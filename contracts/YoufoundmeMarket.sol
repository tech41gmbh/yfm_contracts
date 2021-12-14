//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/token/ERC721/ERC721.sol";

contract YoufoundmeMarket{

    event BalanceWithdrawn (address indexed beneficiary, uint amount);
    event PriceChanged (uint newprice);

    address owner;
    address nftcontract;
    uint offeringNonce;
    uint256 balance;
    uint256 price;

    constructor(){
         owner = payable(msg.sender); /
    }

    function balanceOf() external view returns (uint256) {
        return balance;
    }

    function withdrawBalance(uint256 amount) external owner {
        require(balance >= amount,"You don't have enough balance to withdraw");
        payable(msg.sender).transfer(amount);
        balances -= amount;
        emit BalanceWithdrawn(msg.sender, amount);
    }

    function setPrice(uint256 newprice) {
       price = newprice;
       emit PriceChanged(newprice);
    }

    function getPrice() external view returns (uint256) {
       return price;
    }

    function purchase(address recipient, address contract, uint256 tokenId, string memory tokenURI) external payable {
        equire(msg.value < price, "not enough paid");
        Callee c = Youfoundme(contract);
        c.mint(recipient, tokenId, tokenURI);
        balance += msg.value;
    }
}

contract Youfoundme(){
    function mintNFT(address recipient, uint256 tokenId, string memory tokenURI) public onlyOwner returns (uint256){
       return 0;
    }
}