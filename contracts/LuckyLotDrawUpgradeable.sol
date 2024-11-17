// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract LuckyLotDrawUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using Address for address payable;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public ticketPrice;
    address public paymentToken;
    address payable public paymentAddress;
    uint256 public maxNumber;
    uint8 public maxNumbersPerRound;

    struct Round {
        uint256 id;
        mapping(uint256 => address) participants;
        uint256[] numbers;
        bool isClosed;
        uint256 winningNumber;
        bool hasWinner;
    }

    mapping(uint256 => Round) public rounds;
    uint256 public currentRoundId;

    event NewEntry(uint256 indexed round, address indexed user, uint256 number);
    event RoundClosed(
        uint256 indexed round,
        uint256 winningNumber,
        address winner
    );
    event RefundIssued(
        uint256 indexed round,
        address indexed user,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _paymentToken,
        address payable _paymentAddress,
        uint256 _ticketPrice
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        paymentToken = _paymentToken;
        paymentAddress = _paymentAddress;
        ticketPrice = _ticketPrice;

        maxNumber = 99;
        maxNumbersPerRound = 100;
        currentRoundId = 1;
    }

    // Function to get all numbers from a specific round
    function getRoundNumbers(
        uint256 roundId
    ) external view returns (uint256[] memory) {
        return rounds[roundId].numbers;
    }

    // Function to get a number by index in a specific round
    function getRoundNumberByIndex(
        uint256 roundId,
        uint256 index
    ) external view returns (uint256) {
        return rounds[roundId].numbers[index];
    }

    // Function to get the winning number from a specific round
    function enter(uint256 number) external payable nonReentrant {
        require(number <= maxNumber, "Number exceeds max limit");
        require(
            rounds[currentRoundId].participants[number] == address(0),
            "Number already taken"
        );

        if (paymentToken == address(0)) {
            require(msg.value == ticketPrice, "Incorrect ticket price");
            paymentAddress.sendValue(msg.value);
        } else {
            ERC20Upgradeable(paymentToken).transferFrom(
                msg.sender,
                paymentAddress,
                ticketPrice
            );
        }

        rounds[currentRoundId].participants[number] = msg.sender;
        rounds[currentRoundId].numbers.push(number);

        emit NewEntry(currentRoundId, msg.sender, number);

        if (rounds[currentRoundId].numbers.length >= maxNumbersPerRound) {
            closeRound();
        }
    }

    // Function to close the current round
    function closeRound() public onlyAdmin {
        rounds[currentRoundId].isClosed = true;
    }

    // Function to set the winning number
    function setWinningNumber(uint256 winningNumber) external onlyAdmin {
        require(winningNumber <= maxNumber, "Invalid winning number");
        require(rounds[currentRoundId].isClosed, "Round is not closed");

        Round storage round = rounds[currentRoundId];
        round.winningNumber = winningNumber;
        round.hasWinner = round.participants[winningNumber] != address(0);

        address winner = round.participants[winningNumber];
        if (round.hasWinner) {
            uint256 prize = ticketPrice * maxNumbersPerRound;
            if (paymentToken == address(0)) {
                payable(winner).sendValue(prize);
            } else {
                ERC20Upgradeable(paymentToken).transfer(winner, prize);
            }
        }

        emit RoundClosed(currentRoundId, winningNumber, winner);

        currentRoundId++;
    }

    // Function to set the ticket price
    function setTicketPrice(uint256 _ticketPrice) external onlyAdmin {
        ticketPrice = _ticketPrice;
    }

    // Function to set the payment token
    function setPaymentToken(address _paymentToken) external onlyAdmin {
        paymentToken = _paymentToken;
    }

    // Function to set the payment address
    function setPaymentAddress(
        address payable _paymentAddress
    ) external onlyAdmin {
        paymentAddress = _paymentAddress;
    }

    // Function to set the max number
    function setMaxNumber(uint256 _maxNumber) external onlyAdmin {
        maxNumber = _maxNumber;
    }

    // Function to set the max numbers per round
    function setMaxNumbersPerRound(
        uint8 _maxNumbersPerRound
    ) external onlyAdmin {
        maxNumbersPerRound = _maxNumbersPerRound;
    }

    /// @dev Authorization function for UUPS upgrades
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}
}
