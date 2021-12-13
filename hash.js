
const { getHasher, OutputType, HashType } = require('bigint-hash');



var did = "did:yfm:eip-155:43113:345879B60BF5ccDDd06BC91E49A6eBc4e93CfDAa";

var decimal = getHasher(HashType.SHA3_224).update(Buffer.from(did)).digest(OutputType.BigInt);

console.log(decimal)


