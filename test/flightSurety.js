var Test = require('../config/testConfig.js');
const web3 = require('web3');

contract('Flight Surety Tests', async (accounts) => {

    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.setAuthorizedCaller(config.flightSuretyApp.address);
    });

    /****************************************************************************************/
    /* Operations and Settings                                                              */
    /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false);
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        await config.flightSuretyData.setOperatingStatus(false);

        let reverted = false;
        try {
            await config.flightSurety.setTestingMode(true);
        }
        catch (e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyData.setOperatingStatus(true);

    });

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        // ARRANGE

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(config.testAddresses[3], { from: config.testAddresses[2] });
        }
        catch (e) {

        }
        let result = await config.flightSuretyData.airlineIsRegistered(config.testAddresses[3]);

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });

    it('(airline) fund the first airline, check the registration status', async () => {


        let beforeFundingIsAirlineFunded = await config.flightSuretyData.airlineIsFunded(config.firstAirline);
        assert.equal(beforeFundingIsAirlineFunded, false, "Airline seems to be funded before calling the fund method.");

        // ARRANGE
        let secondAirline = config.testAddresses[2];
        // ACT
        try {

            await config.flightSuretyApp.fund({
                from: config.firstAirline,
                value: web3.utils.toWei('10', 'ether'),
                gas: 2000000,
                gasPrice: 1
            });

            await config.flightSuretyApp.registerAirline(config.secondAirline,
                "Korean Air",
                {
                    from: config.firstAirline,
                    gas: 2000000,
                    gasPrice: 1
                });

            await config.flightSuretyApp.fund({
                from: config.secondAirline,
                value: web3.utils.toWei('10', 'ether'),
                gas: 2000000,
                gasPrice: 1
            });

        }
        catch (e) {
            console.log(e)
        }
        let airlineExists = await config.flightSuretyData.airlineExists(config.firstAirline);
        let airlineFunded = await config.flightSuretyData.airlineIsFunded(config.firstAirline);
        let airlineIsRegistered = await config.flightSuretyData.airlineIsRegistered(config.firstAirline);

        let secondAirlineExists = await config.flightSuretyData.airlineExists(config.secondAirline);
        let secondAirlineFunded = await config.flightSuretyData.airlineIsFunded(config.secondAirline);

        // ASSERT
        assert.equal(airlineExists, true, "Airline doesn't exist");
        assert.equal(airlineFunded, true, "Funding the airline failed");
        assert.equal(airlineIsRegistered, true, "The airline isn't registered");
        assert.equal(secondAirlineExists, true, "The second airline doesn't exist");
        assert.equal(secondAirlineFunded, true, "Funding the second airline failed");
    });


    it('(airline) if registering airline is funded, the new airline would be registered (number of airlines less than the threshold)', async () => {

        let airlineIsRegistered = await config.flightSuretyData.airlineIsRegistered(config.firstAirline);
        let secondAirlineIsRegistered = await config.flightSuretyData.airlineIsRegistered(config.secondAirline);

        // ASSERT
        assert.equal(airlineIsRegistered, true, "The airline isn't registered");
        assert.equal(secondAirlineIsRegistered, true, "The second airline isn't registered");

    });

    it('(airline) if the fifth airline have not a majority votes it should not be registered (after the threshold of voting reached)', async () => {
        try {


            await config.flightSuretyApp.registerAirline(config.thirdAirline,
                "Turkish Airlines",
                {
                    from: config.firstAirline,
                    gas: 2000000,
                    gasPrice: 1
                });

            await config.flightSuretyApp.registerAirline(config.fourthAirline,
                "Qatar Airways",
                {
                    from: config.firstAirline,
                    gas: 2000000,
                    gasPrice: 1
                });

            // 5th airline registration
            await config.flightSuretyApp.registerAirline(config.fifthAirline,
                "American Airlines",
                {
                    from: config.firstAirline,
                    gas: 2000000,
                    gasPrice: 1
                });
            // voting for airline 5
            await config.flightSuretyApp.vote(config.fifthAirline,
                {
                    from: config.firstAirline,
                    gas: 2000000,
                    gasPrice: 1
                });

            await config.flightSuretyApp.vote(config.fifthAirline,
                {
                    from: config.secondAirline,
                    gas: 2000000,
                    gasPrice: 1
                });
        }
        catch (e) {
            console.log(e)
        }

        let fifthAirlineNumberOfVotes = await config.flightSuretyApp.getNumberOfVotes(config.fifthAirline,
            {
                from: config.secondAirline,
                gas: 2000000,
                gasPrice: 1
            })

        let fifthAirlineNumberOfAirlines = await config.flightSuretyApp.getNumberOfAirlines({
            from: config.secondAirline,
            gas: 2000000,
            gasPrice: 1
        })

        let fifthAirlineIsRegistered = await config.flightSuretyApp.airlineIsRegistered(config.fifthAirline,
            {
                from: config.secondAirline,
                gas: 2000000,
                gasPrice: 1
            });
        assert.equal(fifthAirlineIsRegistered, false, "The Fifth airline doesn't have enough votes yet, it shouldn't be registered");
        assert.equal(fifthAirlineNumberOfVotes, 2, "The fifth airline should have 2 votes");
        assert.equal(fifthAirlineNumberOfAirlines, 4, "There should be 4 airlines");

    });

    it('(airline) if the fifth airline have a majority of votes it should be registered (after the threshold of voting reached)', async () => {
        try {

            // voting for airline 5
            await config.flightSuretyApp.vote(config.fifthAirline,
                {
                    from: config.thirdAirline,
                    gas: 2000000,
                    gasPrice: 1
                });
        }
        catch (e) {
            console.log(e)
        }

        let fifthAirlineNumberOfVotes = await config.flightSuretyApp.getNumberOfVotes(config.fifthAirline,
            {
                from: config.secondAirline,
                gas: 2000000,
                gasPrice: 1
            })

        let fifthAirlineNumberOfAirlines = await config.flightSuretyApp.getNumberOfAirlines({
            from: config.secondAirline,
            gas: 2000000,
            gasPrice: 1
        })

        let fifthAirlineIsRegistered = await config.flightSuretyApp.airlineIsRegistered(config.fifthAirline,
            {
                from: config.secondAirline,
                gas: 2000000,
                gasPrice: 1
            });

        assert.equal(fifthAirlineNumberOfVotes, 3, "The fifth airline should have 3 votes");
        assert.equal(fifthAirlineNumberOfAirlines, 5, "There should be 4 airlines");
        assert.equal(fifthAirlineIsRegistered, true, "The Fifth airline doesn't have enough votes yet, it shouldn't be registered");

    });

    it('(airline) if an airline is not funded, it could not register a new airline', async () => {


        try {
            await config.flightSuretyApp.registerAirline(config.sixthAirline,
                "Philippine Airlines",
                {
                    from: config.fifthAirline,
                    gas: 2000000,
                    gasPrice: 1
                });
        } catch (e) {
            assert.include(e.message, 'Airline is not funded yet')
        }

    });
});