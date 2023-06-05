// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Flight {
    event TicketPurchased(address indexed purchaser);
    event FlightEnabled(bytes32 indexed flightId);
    event FlightLanded(bytes32 indexed flightId);
    event FlightCancelled(bytes32 indexed flightId);
    event SeatBooked(
        bytes32 indexed flightId,
        address indexed owner,
        bytes32 uuid
    );
    event SeatCancelled(bytes32 indexed flightId, bytes32 uuid);
    event SeatTransferred(
        bytes32 indexed flightId,
        address indexed owner,
        bytes32 uuid
    );
    event RefundSent(
        bytes32 indexed flightId,
        address indexed owner,
        uint amount
    );
    event FlightConcluded(
        bytes32 indexed flightId,
        address indexed owner,
        uint amount
    );

    address public _regulator;
    address public _owner;

    uint public _seatCount;
    uint public _seatsRemaining;
    uint public _seatPurchaseIndex = 0;
    uint public _seatPrice;

    bytes32 public _flightId;

    struct Seat {
        bytes32 uuid;
        address owner;
        address passenger;
        uint price;
    }

    mapping(address => uint[]) public _ownerSeats;
    mapping(bytes32 => uint) public _seatIndexFromUuid;
    mapping(address => uint) public _passengerSeat;

    Seat[] public _seats;

    uint[] private _skippedSeats;

    enum FlightStatus {
        Presale,
        Sale,
        Closed,
        Landed,
        Finalised,
        Cancelled
    }
    FlightStatus public _status;

    constructor(bytes32 flightId) public {
        _status = FlightStatus.Presale;
        _flightId = flightId;
        _owner = msg.sender;
    }

    function addRegulator(address regulator) public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _regulator = regulator;
    }

    function setSeatPrice(uint seatPrice) public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _seatPrice = seatPrice;
    }

    function enableFlight() public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        require(_seatCount > 0, "Flight must have seats");
        //require(_regulator != 0, "Flight must have a regulator");
        // require(_flightId != "", "Flight must have an ID");
        _status = FlightStatus.Sale;
        //emit FlightEnabled(_flightId);
    }

    // function getOwnerSeats() public view hasTicket returns(uint[]) {
    //     return _ownerSeats[msg.sender];

    // }

    // function getOwnerSeats() public view returns (
    //     bytes32[] uuid,
    //     address[] owner,
    //     address[] passenger,
    //     uint256[] price
    // ) {
    //     uuid = new bytes32[](_ownerSeats[msg.sender].length);
    //     owner = new address[](_ownerSeats[msg.sender].length);
    //     passenger = new address[](_ownerSeats[msg.sender].length);
    //     price = new uint256[](_ownerSeats[msg.sender].length);

    //     for(uint256 i = 0; i < _ownerSeats[msg.sender].length; i++) {
    //         Seat memory currentSeat = _seats[_ownerSeats[msg.sender][i]];
    //         uuid[i] = currentSeat.uuid;
    //         owner[i] = currentSeat.owner;
    //         passenger[i] = currentSeat.passenger;
    //         price[i] = currentSeat.price;
    //     }
    // }

    function transferSeat(
        uint _seatIndex,
        address _transferTo
    ) public hasTicket {
        require(
            _seats[_seatIndex].owner == msg.sender,
            "You are not the owner of this seat"
        );
        _seats[_seatIndex].passenger = _transferTo;
        _passengerSeat[_transferTo] = _seatIndex;

        emit SeatTransferred(_flightId, msg.sender, _seats[_seatIndex].uuid);
    }

    function closeFlight() public onlySale {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _status = FlightStatus.Closed;
    }

    function landFlight() public onlyClosed {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _status = FlightStatus.Landed;
        emit FlightLanded(_flightId);
    }

    function finaliseFlight() public onlyLanded {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _status = FlightStatus.Finalised;
    }

    function cancelFlight() public onlyFinalised {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _status = FlightStatus.Cancelled;
    }

    function setFlightId(bytes32 flightId) public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _flightId = flightId;
    }

    function setSeatCount(uint seatCount) public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _seatCount = seatCount;
    }

    function setRemainingSeats(uint seatsRemaining) public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        _seatsRemaining = seatsRemaining;
    }

    /**
     * Passenger Actions
     */

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

        if (numberOfSeats == 1 && _skippedSeats.length == 0) {
            bookOneSeat();
        } else if (numberOfSeats > 1) {
            //bookMultipleSeats(numberOfSeats);
            bookOneSeat();
        } else if (numberOfSeats == 1 && _skippedSeats.length > 0) {
            bookSkippedSeat();
        }
    }

    function bookGarbage() public view returns (bytes32) {
        //_seats[1].owner = 0x7f90656Cde73A907f66cbfE44cBB88B57B00cE23;
        return _seats[3].uuid;
    }

    function loadSeat(bytes32 uuid) public returns (uint) {
        _seats.push(Seat(uuid, address(0), address(0), 0));
        _seatIndexFromUuid[uuid] = _seats.length - 1;
        return _seats.length - 1;
    }

    function getSeatByIndex(
        uint index
    ) public view returns (uint, bytes32, address, address, uint) {
        Seat storage searchSeat = _seats[index];
        return (
            index,
            searchSeat.uuid,
            searchSeat.owner,
            searchSeat.passenger,
            searchSeat.price
        );
    }

    function getSeatByUuid(
        bytes32 uuid
    ) public view returns (uint, bytes32, address, address, uint) {
        Seat storage searchSeat = _seats[_seatIndexFromUuid[uuid]];
        return (
            _seatIndexFromUuid[uuid],
            uuid,
            searchSeat.owner,
            searchSeat.passenger,
            searchSeat.price
        );
    }

    function getPassengerSeat()
        public
        view
        returns (uint, bytes32, address, address, uint)
    {
        Seat storage searchSeat = _seats[_passengerSeat[msg.sender]];
        return (
            _passengerSeat[msg.sender],
            searchSeat.uuid,
            searchSeat.owner,
            searchSeat.passenger,
            searchSeat.price
        );
    }

    function bookOneSeat() private {
        _ownerSeats[msg.sender].push(_seatPurchaseIndex); // 20,000
        _passengerSeat[msg.sender] = _seatPurchaseIndex; // 20,000

        // _seats[_seatPurchaseIndex].owner = msg.sender;    // 20,000
        // _seats[_seatPurchaseIndex].passenger = msg.sender;// 20,000
        // _seats[_seatPurchaseIndex].price = _seatPrice;    // 20,000

        emit SeatBooked(
            _flightId,
            _seats[_seatPurchaseIndex].owner,
            _seats[_seatPurchaseIndex].uuid
        );

        _seatPurchaseIndex++; // 3 + 20,000
        _seatsRemaining--; // 3 + 20,000
        // gas limit = 3000000
    }

    function bookSkippedSeat() private {
        uint skippedSeatIndex = _skippedSeats[_skippedSeats.length - 1];
        delete _skippedSeats[_skippedSeats.length - 1];
        //_skippedSeats.length--;

        _seatsRemaining--;

        _ownerSeats[msg.sender].push(skippedSeatIndex);
        _passengerSeat[msg.sender] = skippedSeatIndex;

        _seats[skippedSeatIndex].owner = msg.sender;
        _seats[skippedSeatIndex].passenger = msg.sender;
        _seats[skippedSeatIndex].price = _seatPrice;

        emit SeatBooked(
            _flightId,
            _seats[skippedSeatIndex].owner,
            _seats[skippedSeatIndex].uuid
        );
    }

    function cancelSeat(uint seatIndex) public {
        require(
            _seats[seatIndex].owner == msg.sender,
            "This seat does not belong to this user"
        );

        if (_seats[seatIndex].passenger == msg.sender) {
            delete _passengerSeat[msg.sender];
        }

        for (uint i = 0; i < _ownerSeats[msg.sender].length - 1; i++) {
            if (seatIndex == _ownerSeats[msg.sender][i]) {
                delete _ownerSeats[msg.sender][i];
                _ownerSeats[msg.sender][i] = _ownerSeats[msg.sender][
                    _ownerSeats[msg.sender].length - 1
                ];
            }
        }

        // _ownerSeats[msg.sender].length--;
        _skippedSeats.push(seatIndex);

        // msg.sender.transfer(_seats[seatIndex].price);

        _seats[seatIndex].owner = address(0);
        _seats[seatIndex].passenger = address(0);
        _seats[seatIndex].price = 0;

        _seatsRemaining++;

        emit SeatCancelled(_flightId, _seats[seatIndex].uuid);
    }

    function bookMultipleSeats(uint numberOfSeats) private {
        for (uint i; i < numberOfSeats; i++) {
            bookOneSeat();
        }
    }

    function getSkippedSeatCount() public view returns (uint) {
        return _skippedSeats.length;
    }

    function requestRefund() public hasTicket onlyCancelled {
        uint totalRefund = 0;
        for (uint i; i < _ownerSeats[msg.sender].length; i++) {
            totalRefund += _ownerSeats[msg.sender][i];
            delete _ownerSeats[msg.sender][i];
        }
        //_ownerSeats[msg.sender].length = 0;

        emit RefundSent(_flightId, msg.sender, totalRefund);
        //msg.sender.transfer(totalRefund);
    }

    function concludeFlight() public {
        require(msg.sender == _owner, "Only the owner may perform this action");
        emit FlightConcluded(_flightId, _owner, address(this).balance);
        //selfdestruct(_owner);
    }

    /**
     * Modifiers
     */

    modifier onlyRegulator() {
        require(msg.sender == _regulator, "Sender must be a regulator");
        _;
    }

    modifier onlyPresale() {
        require(
            _status == FlightStatus.Presale,
            "Flight must be in Presale status"
        );
        _;
    }

    modifier onlySale() {
        require(_status == FlightStatus.Sale, "Flight must be in Sale status");
        _;
    }

    modifier onlyClosed() {
        require(
            _status == FlightStatus.Closed,
            "Flight must be in Closed status"
        );
        _;
    }

    modifier onlyLanded() {
        require(
            _status == FlightStatus.Landed,
            "Flight must be in Landed status"
        );
        _;
    }

    modifier onlyFinalised() {
        require(
            _status == FlightStatus.Finalised,
            "Flight must be in Finalised status"
        );
        _;
    }

    modifier onlyCancelled() {
        require(
            _status == FlightStatus.Cancelled,
            "Flight must be in Cancelled status"
        );
        _;
    }

    modifier hasTicket() {
        require(
            _ownerSeats[msg.sender].length > 0,
            "Sender must have seats on this flight"
        );
        _;
    }
}
