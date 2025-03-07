// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Storage.sol";

/**
 * @title BaseNFT Contract
 * @author @lukema95
 * @notice Base contract for FLIPs which implements ERC721, ERC721Enumerable, ERC721Holder, Ownable and Storage
 */
contract BaseNFT is ERC721, ERC721Enumerable, ERC721Holder, Ownable, Storage {
    using Strings for uint256;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialPrice,
        uint256 _maxSupply,
        uint256 _creatorFeePercent
    )
        ERC721(_name, _symbol)
        Ownable(msg.sender)
        Storage(_initialPrice, _maxSupply, _creatorFeePercent)
    {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        _requireOwned(tokenId);
        return bytes(baseURI).length > 0 ? string.concat(baseURI, "/", tokenId.toString(), ".json") : "";
    }

    function contractURI() public view returns (string memory) {
        return bytes(baseURI).length > 0 ? string.concat(baseURI, "/collection.json") : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
}
