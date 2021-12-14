// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Youfoundme.sol";

contract YoufoundmeMarket{
    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: You are not the owner.");
        _;
    }

    event BalanceWithdrawn (address indexed beneficiary, uint amount);
    event PriceChanged (uint newprice);

    address owner;
    uint offeringNonce;
    uint256 balance;
    uint256 price;

    constructor(){
         owner = payable(msg.sender); 
    }

    function balanceOf() external view returns (uint256) {
        return balance;
    }

    function withdrawBalance(uint256 amount) external onlyOwner {
        require(balance >= amount,"You don't have enough balance to withdraw");
        payable(msg.sender).transfer(amount);
        balance -= amount;
        emit BalanceWithdrawn(msg.sender, amount);
    }

    function setPrice(uint256 newprice) external onlyOwner {
       price = newprice;
       emit PriceChanged(newprice);
    }

    function getPrice() external view returns (uint256) {
       return price;
    }

    function purchasenft(address nftcontract, address recipient,  uint256 tokenId, string memory tokenURI) public payable {
        require(msg.value < price, "not enough paid");
        bool success = Youfoundme(nftcontract).mintNFT(recipient, tokenId, tokenURI);
        require(success, "Failed to create NFT");
        balance += msg.value;
    }
}