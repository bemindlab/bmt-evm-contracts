// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title LuckyLotDraw
 * @notice This contract is used to create a lottery system
 * @dev This contract is used to create a lottery system
 * @dev A contract for a lottery system
 * @dev default numbers are 0-99 and max numbers per round are 100
 */
contract LuckyLotDraw is AccessControl, ReentrancyGuard {
    using Address for address payable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public ticketPrice;
    address public paymentToken;
    address payable public paymentAddress;

    uint32 public maxNumber = 99;
    uint32 public maxNumbersPerRound = 100;

    struct Round {
        uint256 id;
        mapping(uint256 => address) participants;
        uint32[] numbers;
        bool isClosed;
        uint32 winningNumber;
        bool hasWinner;
    }
    uint256 public currentRoundId;

    struct Entry {
        address participant;
        uint32 number;
    }
    Entry[] public entries;

    // Mapping to store rounds
    mapping(uint256 => Round) public rounds;

    // Mapping to store participant addresses for each round
    mapping(uint256 => address[]) private roundParticipants;

    event NewEntry(uint256 indexed round, address indexed user, uint32 number);

    event RoundClosed(uint256 indexed round, uint32 winningNumber, address winner);

    event RefundIssued(uint256 indexed round, address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only admin can perform this action");
        _;
    }

    modifier roundOpen(uint256 roundId) {
        require(!rounds[roundId].isClosed, "Round is closed");
        _;
    }

    constructor(address _paymentToken, address payable _paymentAddress, uint256 _ticketPrice) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        paymentToken = _paymentToken;
        paymentAddress = _paymentAddress;
        ticketPrice = _ticketPrice;

        currentRoundId = 1;
    }

    // Function to get all numbers from a specific round
    function getRoundNumbers(uint256 roundId) external view returns (uint32[] memory) {
        return rounds[roundId].numbers;
    }

    // Function to get a number by index in a specific round
    function getRoundNumberByIndex(uint256 roundId, uint256 index) external view returns (uint256) {
        return rounds[roundId].numbers[index];
    }

    // Function to get participant by number in a specific round
    function getParticipants(uint256 roundId) external view returns (address[] memory) {
        return roundParticipants[roundId];
    }

    // This function is used to enter the lottery
    function enter(uint32 number) external roundOpen(currentRoundId) nonReentrant {
        require(number <= maxNumber, "Number exceeds max limit");
        require(rounds[currentRoundId].participants[number] == address(0), "Number already taken");

        IERC20(paymentToken).transferFrom(msg.sender, paymentAddress, ticketPrice);

        rounds[currentRoundId].participants[number] = msg.sender;
        rounds[currentRoundId].numbers.push(number);
        roundParticipants[currentRoundId].push(msg.sender);
        entries.push(Entry({participant: msg.sender, number: number}));

        emit NewEntry(currentRoundId, msg.sender, number);

        if (rounds[currentRoundId].numbers.length >= maxNumbersPerRound) {
            closeRound();
        }
    }

    // This function is used to get the number of entries
    function getEntry(uint256 index) public view returns (address participant, uint32 number) {
        require(index < entries.length, "Index out of bounds");
        Entry storage entry = entries[index];
        return (entry.participant, entry.number);
    }

    // This function is used to close the current round
    function closeRound() public onlyAdmin roundOpen(currentRoundId) {
        rounds[currentRoundId].isClosed = true;
    }

    // This function is used to set the winning number
    function setWinningNumber(uint32 winningNumber) external onlyAdmin {
        require(winningNumber <= maxNumber, "Invalid winning number");
        require(rounds[currentRoundId].isClosed, "Round is not closed");

        Round storage round = rounds[currentRoundId];
        round.winningNumber = winningNumber;
        round.hasWinner = round.participants[winningNumber] != address(0);

        address winner = round.participants[winningNumber];
        if (round.hasWinner) {
            uint256 prize = ticketPrice * maxNumbersPerRound;
            IERC20(paymentToken).transferFrom(msg.sender, winner, prize);
        }

        emit RoundClosed(currentRoundId, winningNumber, winner);
        currentRoundId++;
    }

    // This function is used to set the ticket price
    function setTicketPrice(uint256 _ticketPrice) external onlyAdmin {
        ticketPrice = _ticketPrice;
    }

    // This function is used to set the payment token
    function setPaymentToken(address _paymentToken) external onlyAdmin {
        paymentToken = _paymentToken;
    }

    // This function is used to set the payment address
    function setPaymentAddress(address payable _paymentAddress) external onlyAdmin {
        paymentAddress = _paymentAddress;
    }

    // This function is used to set the max number
    function setMaxNumber(uint32 _maxNumber) external onlyAdmin {
        maxNumber = _maxNumber;
    }

    // This function is used to set the max numbers per round
    function setMaxNumbersPerRound(uint8 _maxNumbersPerRound) external onlyAdmin {
        maxNumbersPerRound = _maxNumbersPerRound;
    }

    // This function is used to withdraw the token
    function withdraw(address tokenAddress) external onlyAdmin {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, balance);
    }

    // This function is used to refund all the participants
    function refundAll(uint256 roundId) external onlyAdmin roundOpen(roundId) nonReentrant {
        Round storage round = rounds[roundId];
        for (uint256 i = 0; i < round.numbers.length; i++) {
            address participant = round.participants[round.numbers[i]];
            uint256 refundAmount = ticketPrice;
            IERC20(paymentToken).transferFrom(msg.sender, participant, refundAmount);
            emit RefundIssued(roundId, participant, refundAmount);
        }
        round.isClosed = true;
    }

    // This function is used to update the admin
    function updateAdmin(address newAdmin) external onlyAdmin {
        grantRole(ADMIN_ROLE, newAdmin);
        revokeRole(ADMIN_ROLE, msg.sender);
    }
}
