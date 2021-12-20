const { expect } = require("chai");
const hardhat = require("hardhat");
const { ethers } = hardhat;
const { LazyMinter } = require('../lib')


// https://faucets.chain.link/fuji


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


describe("YoufoundmeNft", function() {

  /*
  it("Should deploy", async function() {
    const signers = await ethers.getSigners();
    const minter = signers[0].address;

    console.log(minter);

    const LazyNFT = await ethers.getContractFactory("YoufoundmeNft");
    const lazynft = await LazyNFT.deploy(minter.address);
    await lazynft.deployed();
  })
  */


  it("Should redeem an NFT from a signed voucher", async function() {


    const { contract, redeemerContract, redeemer, minter } = await deploy();
    const lazyMinter = new LazyMinter({ contract, signer: minter });
    const minPrice = 50000;
    const tokenId = "16463810416611142016106935538063421765033088066682018782392386069911";
    const voucher = await lazyMinter.createVoucher(tokenId, "https://gateway.pinata.cloud/ipfs/QmUGZTtojfX9EWuoLQ82Hf1DBpeVRrCuiLQru1cYVdH1ec", minPrice);
    console.log(voucher);



    await expect(redeemerContract.redeem("0x345879B60BF5ccDDd06BC91E49A6eBc4e93CfDAa", voucher))
        .to.emit(contract, 'Transfer')  // transfer from null address to minter
        .withArgs('0x0000000000000000000000000000000000000000', minter.address, voucher.tokenId)
        .and.to.emit(contract, 'Transfer') // transfer from minter to redeemer
        .withArgs(minter.address, "0x345879B60BF5ccDDd06BC91E49A6eBc4e93CfDAa", voucher.tokenId);
    
    /*
    await expect(redeemerContract.redeem(redeemer.address, voucher)).to.be.revertedWith('ERC721: token already minted')
   
    */
   });
});

/* main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
    */
