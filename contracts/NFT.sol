// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Axe is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string internal _baseTokenURI;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    // Mint game item
    function mintItem(address player) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        return newItemId;
    }

    // Burn game item
    function burnItem(uint256 itemId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), itemId),
            "Caller is not owner nor approved"
        );
        _burn(itemId);
    }

    // Set base URI
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    // Get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
