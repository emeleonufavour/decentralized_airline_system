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

    struct Seat {
        bytes32 uuid;
        address owner;
        address passenger;
        uint price;
    }
    Seat[] public _seats;

    mapping(address => uint[]) public _ownerSeats;
    mapping(bytes32 => uint) public _sentIndexFromuuid;
    mapping(address => uint) public _passengerSeat;
    mapping(address => bool) public _admin;

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
        _admin[msg.sender] = true;
    }

    // setter functions

    ///@dev this function is used to set an address as a regulator
    ///@param regulator the address to be assigned as a regulator
    function changeRegulator(
        address regulator
    ) public onlyOwner onlyAdmin(msg.sender) {
        _regulator = regulator;
    }

    ///@dev this function checks if an account is the regulator
    ///@param regulator the address to check if it is a regulator
    function isRegulator(address regulator) public view returns (bool) {
        assert(regulator == _regulator);
        return true;
    }

    ///@dev this function is used to add an address as an admin to the contract
    ///@param addressToAdd the address to add as an admin
    function addAdmin(address addressToAdd) public onlyOwner {
        _admin[addressToAdd] = true;
    }

    ///@dev this function is used to remove an address as an admin to the contract
    ///@param addressToRemove the address to remove as an admin
    function removeAdmin(address addressToRemove) public onlyOwner {
        _admin[addressToRemove] = false;
    }

    ///@dev this function is used to check if an address is an admin
    function isAdmin(address addr) public view returns (bool) {
        return _admin[addr];
    }

    ///@dev this function is to set the price of a seat
    ///@param seatPrice the price of the seat
    function setSeatPrice(
        uint seatPrice
    ) public onlyOwner onlyAdmin(msg.sender) returns (uint) {
        _seatPrice = seatPrice;
        return seatPrice;
    }

    // function setFlightId(bytes32 flightId) public onlyOwner {
    //     _flightId = flightId;
    // }

    ///@dev this function sets the amount of seat left in the airline
    function setVacantSeats(
        uint seatsRemaining
    ) public onlyAdmin(msg.sender) onlyOwner {
        _seatsRemaining = seatsRemaining;
    }

    ///@dev this functions sets the total amount of seats
    function setSeatCount(
        uint seatCount
    ) public onlyOwner onlyAdmin(msg.sender) {
        _seatCount = seatCount;
    }

    // term-settlement functions

    function approveFlight() public {
        require(msg.sender == _owner, "Only the owner ");
        require(_seatCount > 0, "The seat count must be greater than zero");

        _status = FlightStatus.Sale;
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

    //consumer actions
    function bookOneSeat() public {
        _ownerSeats[msg.sender].push(_seatPurchaseIndex);
        _passengerSeat[msg.sender] = _seatPurchaseIndex;
        unchecked {
            _seatPurchaseIndex++;
            _seatsRemaining--;
        }
    }

    function book(uint numberOfSeats) public payable onlySale {
        require(msg.value > 0, "Price must be greater than zero");
        require(numberOfSeats > 0, "Number of seats cannot be zero");
        require(
            msg.value == _seatPrice * numberOfSeats,
            "Value must be the number of seats multiplied by the current price"
        );
        require(
            numberOfSeats <= _seatsRemaining,
            "There are not enough seats to make this booking"
        );

        if (numberOfSeats == 1 && _skippedSeats == 0) {
            bookOneSeat();
        } else if (numberOfSeats > 1) {
            //bookMultipleSeats(numberOfSeats);
            bookOneSeat();
        } else if (numberOfSeats == 1 && _skippedSeats > 0) {
            bookSkippedSeat();
        }
    }

    function bookSkippedSeat() private {
        uint skippedSeatIndex = _skippedSeats - 1;
        // delete _skippedSeats[_skippedSeats.length - 1];
        _skippedSeats--;

        _seatsRemaining--;

        _ownerSeats[msg.sender].push(skippedSeatIndex);
        _passengerSeat[msg.sender] = skippedSeatIndex;

        _seats[skippedSeatIndex].owner = msg.sender;
        _seats[skippedSeatIndex].passenger = msg.sender;
        _seats[skippedSeatIndex].price = _seatPrice;

        // emit SeatBooked(
        //     _flightId,
        //     _seats[skippedSeatIndex].owner,
        //     _seats[skippedSeatIndex].uuid
        // );
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

    // modifiers
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

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only owner is allowed to call this function"
        );
        _;
    }

    modifier onlyAdmin(address adminAddress) {
        require(
            _admin[adminAddress] == true,
            "Only admins can perform this function"
        );
        _;
    }
}
