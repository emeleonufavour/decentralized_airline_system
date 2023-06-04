// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Airline {
    address public _regulator;
    address public _owner;

    uint public _seatCount;
    uint public _seatPrice;
    uint public _seatsRemaining;
    uint public _seatPurchaseIndex = 0;

    bytes32 public flightId;

    // create a struct for the details of the seat
    struct Seat {
        bytes32 uuid;
        address owner;
        address passenger;
        uint price;
    }
    Seat[] public _seats;

    // make up mappings to tracking things

    mapping(address => uint[]) public _ownerSeats;
    mapping(bytes32 => uint) public _sentIndexFromuuid;
    mapping(address => uint) public _passengerSeat;

    uint private _skippedSeats;

    enum FlightStatus {
        Presale,
        Sale,
        Closed,
        Landed,
        Finalized,
        Cancelled
    }

    FlightStatus public _status;

    bytes32 public _flightId;

    constructor() {
        _owner = msg.sender;
        _flightId = "JQ570";
        _status = FlightStatus.Presale;
    }

    // modifiers declaration for security considerations
    modifier hasTicket() {
        require(
            _ownerSeats[msg.sender].length > 0,
            "Must have a ticket in the first place"
        );
        _;
    }

    modifier onlyRegulator() {
        require(msg.sender == _regulator, "Must be a regulator");
        _;
    }

    modifier onlyPresale() {
        require(
            _status == FlightStatus.Presale,
            "The status of the flight must be at the presale"
        );
        _;
    }

    modifier onlySale() {
        require(
            _status == FlightStatus.Sale,
            "The status of the flight must be at the sale"
        );
        _;
    }

    modifier onlyClosed() {
        require(
            _status == FlightStatus.Closed,
            "The status of the flight must be at the closed"
        );
        _;
    }

    modifier onlyLanded() {
        require(
            _status == FlightStatus.Landed,
            "The status of the flight must be at the landed"
        );
        _;
    }

    // first declare admin functions

    // setter functions

    function addRegulators(address regulator) public {
        require(msg.sender == _owner, "Only the owner ");
        // so you can pass addresses
        _regulator = regulator;
    }

    function setSeatPrice(uint seatPrice) public {
        require(msg.sender == _owner, "Only the owner ");
        _seatPrice = seatPrice;
    }

    function setFlightId(bytes32 flightId) public {
        require(msg.sender == _owner, "Only the owner ");
        _flightId = flightId;
    }

    function setVacantSeats(uint seatsRemaining) public {
        _seatsRemaining = seatsRemaining;
    }

    function setSeatCount(uint seatCount) public {
        _seatCount = seatCount;
    }

    // term-settlement functions

    function approveFlight() public {
        require(msg.sender == _owner, "Only the owner ");
        require(_seatCount > 0, "The seat count must be greater than zero");

        _status = FlightStatus.Sale;
    }

    function transferSeat(
        uint _seatIndex,
        address _transferTo
    ) public hasTicket {
        require(
            _seats[_seatIndex].owner == msg.sender,
            "Someone else owns this seat"
        );

        _seats[_seatIndex].passenger = _transferTo;
        _passengerSeat[_transferTo] = _seatIndex;
    }

    function closeFlight() public onlySale {
        require(msg.sender == _owner, "Only the owner ");
        _status = FlightStatus.Closed;
    }

    function landFlight() public onlySale {
        require(msg.sender == _owner, "Only the owner ");
        _status = FlightStatus.Landed;
    }

    function finalizeFlight() public onlySale {
        require(msg.sender == _owner, "Only the owner ");
        _status = FlightStatus.Finalized;
    }

    function cancelFlight() public onlySale {
        require(msg.sender == _owner, "Only the owner ");
        _status = FlightStatus.Cancelled;
    }

    // the following functions are the ones the passenger can call, do you get?

    function bookOneSeat() private {
        _ownerSeats[msg.sender].push(_seatPurchaseIndex);
        _passengerSeat[msg.sender] = _seatPurchaseIndex;

        _seatPurchaseIndex++;
        _seatsRemaining--;
    }
}
