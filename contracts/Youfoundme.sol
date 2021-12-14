// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Youfoundme is ERC721URIStorage, Ownable {

    constructor() ERC721("Youfoundme", "YFM") {}

    function mintNFT(address recipient, uint256 tokenId, string memory tokenURI) public onlyOwner returns (bool){
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }

    function setTokenUri(uint256 tokenId, string memory tokenURI) public onlyOwner{
        _setTokenURI(tokenId, tokenURI);
    }

    function decimals() public pure returns (uint8){
        return 0;
    }
}
