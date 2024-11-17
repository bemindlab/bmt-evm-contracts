// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract AnyoneAirdropUpgradeable is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event ERC20Airdropped(address indexed token, address indexed from, address indexed to, uint256 amount);
    event ERC721Airdropped(address indexed token, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Airdropped(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 amount
    );

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function airdropERC20(ERC20Upgradeable token, address[] calldata recipients, uint256 amount) external nonReentrant {
        uint256 totalAmount = amount * recipients.length;
        require(token.allowance(msg.sender, address(this)) >= totalAmount, "Insufficient allowance");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amount);
            emit ERC20Airdropped(address(token), msg.sender, recipients[i], amount);
        }
    }

    function airdropERC721(
        ERC721Upgradeable token,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        require(recipients.length == tokenIds.length, "Recipients and tokenIds length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
            emit ERC721Airdropped(address(token), msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function airdropERC1155(
        ERC1155Upgradeable token,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external nonReentrant {
        require(recipients.length == tokenIds.length && tokenIds.length == amounts.length, "Array length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], amounts[i], data);
            emit ERC1155Airdropped(address(token), msg.sender, recipients[i], tokenIds[i], amounts[i]);
        }
    }
}
