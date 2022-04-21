// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NRGY is ERC20 {
    constructor() ERC20("ENERGY", "NRGY") {
        _mint(msg.sender, 10000000 * 1000000000000000000);
    }
}
