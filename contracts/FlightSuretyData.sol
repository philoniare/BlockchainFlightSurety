pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        string name;
        address wallet;
        bool isFunded;
        bool isRegistered;
        uint256 airlineStackedEth;
        uint256 numberOfVotes;
        bool exists;
    }

    struct Flight {
        string name;
        address airline;
        bool isRegistered;
        uint8 statusCode;
        uint256 timestamp;
    }

    mapping(address => Airline) public airlines; // airlines
    mapping(bytes32 => Flight) public flights; // flights

    mapping(address => mapping(bytes32 => uint256)) private premiums; // premiums
    mapping(bytes32 => address[]) private policyHolders; // find all addresses for a specific flight
    mapping(address => uint256) private payouts; // payouts
    mapping(address => mapping(address => bool))
        private addressAlreadyVotedForAirline; // votesByAirline

    uint256 public MIN_AIRLINE_FUNDS = 10 ether;
    uint256 public MAX_INSURANCE_PREMIUM_VALUE = 1 ether;
    uint256 public AIRLINE_THRESHOLD_FOR_VOTING = 4;
    mapping(address => uint256) public votesByAddress;
    uint256 public airlinesNumber = 0;
    uint256 public REIMBURSE_RATE = 150;
    address public authorizedCaller;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event PolicyHolderPayoutReceived(address policyHolder, uint256 amount);

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(string newAirlineName) public {
        contractOwner = msg.sender;

        // first airfline registered on the creation of the contract

        airlines[contractOwner] = Airline({
            name: newAirlineName,
            wallet: contractOwner,
            isFunded: false,
            isRegistered: true,
            airlineStackedEth: 0,
            exists: true,
            numberOfVotes: 1
        });

        incrementAirlineNumber();
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
     * @dev Modifier that requires the "airline" to be already registered
     */
    modifier requireRegisteredAirline(address airlineAddress) {
        require(
            airlineIsRegistered(airlineAddress),
            "Airline is not registered yet"
        );
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "airline" to be already funded
     */
    modifier requireIsAirlineFunded(address airlineAddress) {
        require(airlines[airlineAddress].isFunded, "Airline is not funded yet");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "airline" doesn't exist
     */
    modifier requireAirlineDoesntExist(address airlineAddress) {
        require(
            false == airlineExists(airlineAddress),
            "Airline already exists"
        );
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "airline" exist
     */
    modifier requireAirlineExist(address airlineAddress) {
        require(true == airlineExists(airlineAddress), "Airline doesn't exist");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Is it an existing airline
     *
     * @return A bool that represents if the airline exists
     */
    function airlineExists(address newAirlineAddress)
        public
        view
        returns (bool)
    {
        return airlines[newAirlineAddress].exists;
    }

    /**
     * @dev Is it a registered airline
     *
     * @return A bool that represents if the airline is registered
     */
    function airlineIsRegistered(address newAirlineAddress)
        public
        view
        returns (bool)
    {
        return airlines[newAirlineAddress].isRegistered;
    }

    /**
     * @dev Is it a funded airline
     *
     * @return A bool that represents if the airline is funded
     */
    function airlineIsFunded(address newAirlineAddress)
        public
        view
        returns (bool)
    {
        return airlines[newAirlineAddress].isFunded;
    }

    /**
     * @dev Number of votes for an airline
     *
     * @return An int that represents if the airline exists
     */
    function getNumberOfVotes(address newAirlineAddress)
        public
        view
        returns (uint256)
    {
        return airlines[newAirlineAddress].numberOfVotes;
    }

    /**
     * @dev Get max insurance premium value
     *
     * @return max insurance premium value
     */
    function getMaxInsurancePremiumValue() public view returns (uint256) {
        return MAX_INSURANCE_PREMIUM_VALUE;
    }

    /**
     * @dev Get min fund
     *
     * @return
     */
    function getMinFund() public view returns (uint256) {
        return MIN_AIRLINE_FUNDS;
    }

    /**
     * @dev Number of airlines
     *
     * @return uint256
     */
    function getNumberOfAirlines() public view returns (uint256) {
        return airlinesNumber;
    }

    /**
     * @dev Voting Threshold
     *
     * @return uint256
     */
    function getVotingThreshold() public view returns (uint256) {
        return AIRLINE_THRESHOLD_FOR_VOTING;
    }

    /**
     * @dev set registered field of an airline
     *
     * @return A bool that represents if the airline is registered
     */
    function setRegistrationStatus(
        address newAirlineAddress,
        bool registrationStatus
    ) public requireIsOperational {
        airlines[newAirlineAddress].isRegistered = registrationStatus;
    }

    function setAuthorizedCaller(address _authorizedCaller)
        public
        requireIsOperational
        requireContractOwner
    {
        authorizedCaller = _authorizedCaller;
    }

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev increment the number of airlines
     *
     * @return
     */
    function incrementAirlineNumber() public requireIsOperational {
        airlinesNumber++;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /**
     * @dev Vote for airline
     *
     *
     */
    function vote(address newAirlineAddress, address electorAirlineAddress)
        external
        returns (uint256)
    {
        bool alreadyVoted = addressAlreadyVotedForAirline[
            electorAirlineAddress
        ][newAirlineAddress];

        if (alreadyVoted != true) {
            airlines[newAirlineAddress].numberOfVotes =
                1 +
                airlines[newAirlineAddress].numberOfVotes;
        }

        addressAlreadyVotedForAirline[electorAirlineAddress][
            newAirlineAddress
        ] = true;

        return airlines[newAirlineAddress].numberOfVotes;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(
        address newAirlineAddress,
        string newAirlineName,
        address registeringAirlineAddress
    )
        external
        requireIsOperational
        requireIsAirlineFunded(registeringAirlineAddress)
        requireAirlineDoesntExist(newAirlineAddress)
        returns (bool)
    {
        airlines[newAirlineAddress] = Airline({
            name: newAirlineName,
            wallet: newAirlineAddress,
            isFunded: false,
            isRegistered: false,
            airlineStackedEth: 0,
            numberOfVotes: 0,
            exists: true
        });

        return true;
    }

    /**
     * @dev Add a flight to the flights map
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerFlight(
        string flight,
        uint256 departureTimestamp,
        uint8 statusCode,
        address airlineAddress
    ) external requireIsOperational returns (bool) {
        bytes32 key = getFlightKey(msg.sender, flight, departureTimestamp);

        flights[key] = Flight({
            name: flight,
            airline: airlineAddress,
            isRegistered: true,
            statusCode: statusCode,
            timestamp: departureTimestamp
        });
        return flights[key].isRegistered;
    }

    function getFlight(string _flight, uint256 _departureTimestamp)
        external
        view
        requireIsOperational
        returns (uint8 statusCode)
    {
        bytes32 key = getFlightKey(msg.sender, _flight, _departureTimestamp);
        statusCode = flights[key].statusCode;
        return statusCode;
    }

    /**
     * @dev Update flight info
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function updateFlightStatusCode(bytes32 flightKey, uint8 statusCode)
        external
        requireIsOperational
    {
        flights[flightKey].statusCode = statusCode;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy(
        address airlineAddress,
        uint256 timestamp,
        string flight,
        address passengerAddress,
        uint256 amount
    ) external payable requireIsOperational {
        require(
            amount > 0,
            "Flight insurance is not free, premium payment needed (Data contract)"
        );
        require(
            amount <= MAX_INSURANCE_PREMIUM_VALUE,
            "Flight premium amount can't exceed 1ETH (Data contract)"
        );

        bytes32 flightKey = getFlightKey(airlineAddress, flight, timestamp);
        premiums[passengerAddress][flightKey] = premiums[passengerAddress][
            flightKey
        ].add(amount);
        policyHolders[flightKey].push(passengerAddress);
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(bytes32 flightKey) external requireIsOperational {
        for (uint256 i = 0; i < policyHolders[flightKey].length; i++) {
            address passengerAddress = policyHolders[flightKey][i];
            uint256 reimburseAmount = premiums[passengerAddress][flightKey]
                .mul(REIMBURSE_RATE)
                .div(100);

            // delete insurance info
            delete policyHolders[flightKey][i];
            delete premiums[passengerAddress][flightKey];

            // credit the policyHolder a payout
            payouts[passengerAddress] = reimburseAmount;

            emit PolicyHolderPayoutReceived(passengerAddress, reimburseAmount);
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(address policyHolderAddress) external requireIsOperational {
        require(payouts[policyHolderAddress] > 0, "No payouts available");
        require(
            policyHolderAddress == tx.origin,
            "Payouts to contracts forbidden"
        );

        uint256 reimburseAmount = payouts[policyHolderAddress];
        payouts[policyHolderAddress] = 0;

        policyHolderAddress.transfer(reimburseAmount);
    }

    function getPayoutAmount(address policyHolderAddress)
        external
        view
        requireIsOperational
        returns (uint256)
    {
        return payouts[policyHolderAddress];
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund(address airlineAddress, uint256 amount)
        external
        payable
        requireIsOperational
        requireAirlineExist(airlineAddress)
    {
        uint256 alreadyFundedAmount = airlines[airlineAddress]
            .airlineStackedEth;
        airlines[airlineAddress].airlineStackedEth = alreadyFundedAmount.add(
            amount
        );

        if (airlines[airlineAddress].airlineStackedEth >= MIN_AIRLINE_FUNDS) {
            airlines[airlineAddress].isFunded = true;
        }
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }
}
