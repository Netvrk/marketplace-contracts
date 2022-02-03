// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract NRGToken is ERC20, Pausable {
    constructor() ERC20("ENERGY", "NRGY") {
        _mint(msg.sender, 1000000 * 1000000000000000000);
    }
}
