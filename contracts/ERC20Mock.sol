// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("MOCK Token", "MOCK") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function faucet() public {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
