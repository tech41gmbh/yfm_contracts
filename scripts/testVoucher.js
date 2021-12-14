const { expect } = require("chai");
const hardhat = require("hardhat");
const { ethers } = hardhat;
const { LazyMinter } = require('../lib')

async function deploy() {
  const [minter, redeemer, _] = await ethers.getSigners()
  let factory = await ethers.getContractFactory("YoufoundmeNft", minter)
  const contract = await factory.deploy(minter.address)

  // the redeemerContract is an instance of the contract that's wired up to the redeemer's signing key
  const redeemerFactory = factory.connect(redeemer)
  const redeemerContract = redeemerFactory.attach(contract.address)

  return {
    minter,
    redeemer,
    contract,
    redeemerContract,
  }
}

async function sayHello() {

	const minPrice = 500;
	const tokenId = "16463810416611142016106935538063421765033088066682018782392386069911";

    const { contract, redeemerContract, redeemer, minter } = await deploy();
	const lazyMinter = new LazyMinter({ contract, signer: minter });

    const voucher = await lazyMinter.createVoucher(tokenId, "https://gateway.pinata.cloud/ipfs/QmUGZTtojfX9EWuoLQ82Hf1DBpeVRrCuiLQru1cYVdH1ec", minPrice)
    return voucher;

}

sayHello().then((value) => console.log(value) );
