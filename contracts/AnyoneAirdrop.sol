// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AnyoneAirdrop is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender) ReentrancyGuard() {}

    function airdropERC20(IERC20 token, address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        require(token.allowance(msg.sender, address(this)) >= amounts.length, "Insufficient allowance");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }

    function airdropERC1155(
        IERC1155 token,
        address[] calldata recipients,
        uint256 id,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], id, amounts[i], data);
        }
    }

    function airdropERC721(IERC721 token, address[] calldata recipients, uint256[] calldata tokenIds) external {
        require(recipients.length == tokenIds.length, "Recipients and tokenIds length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}
