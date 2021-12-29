
const { getHasher, OutputType, HashType } = require('bigint-hash');
const Web3 = require('web3');

// DID is lowercase !


function TokenIdFromDid(did) {

  const web3 = new Web3("ws://localhost:8545");
  return web3.utils.hexToNumberString(Web3.utils.soliditySha3(did));
}

var did = "did:yfm:0x345879B60BF5ccDDd06BC91E49A6eBc4e93CfDAa";

var decimal = TokenIdFromDid(did);

console.log(decimal)


