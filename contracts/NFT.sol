// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Axe is ERC721URIStorage {
    constructor() ERC721("Axe", "AXE") {}

    // Mint game item
    function mintItem(
        address player,
        uint256 newItemId,
        string memory tokenURI
    ) public returns (uint256) {
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    // Burn game item
    function burnItem(uint256 itemId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), itemId),
            "ERC721: caller is not owner nor approved"
        );
        _burn(itemId);
    }
}
