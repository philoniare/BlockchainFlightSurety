var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0x307F4F9c80c07577AdacCe7b5c3C55d466bC9a24",
        "0x11F5b354E4d54e97CEe160CF6CB151A511Bfe8E9",
        "0x2ff17Ae80F844c8f39EbEeCA646EEa3af3bff9f0",
        "0x0A012D9a10d0090d5338CbF12A90a16cBA29ff18",
        "0xc3Ad411E9532133049396A1f7aD99af8e6dec6aC",
        "0x3f26a1a8E2F8b0a4172C398fE2Bb6748eEe8beB4",
        "0x603afF2DE3FEe4ac78e05cB934A33e26edb9839c",
        "0x3f100696029f10F3fDcD1EC4B1CFB31001cAa593",
        "0xE01E24Ee01f1204d981475fF9F0eC9c344FE6B88"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[0];

    let flightSuretyData = await FlightSuretyData.new("United Airlines");
    let flightSuretyApp  = await FlightSuretyApp.new(flightSuretyData.address);

    return {
        owner: owner,
        firstAirline : firstAirline,
        secondAirline: accounts[2],
        thirdAirline : accounts[3],
        fourthAirline: accounts[4],
        fifthAirline : accounts[5],
        sixthAirline : accounts[6],
        policyHolder : accounts[10],
        allAccounts  : accounts,
        flightDepartureTime: 1637885911,
        flight: "BP2021",
        statusCodeUnknown: 0,
        weiMultiple  : (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};