
const { getHasher, OutputType, HashType } = require('bigint-hash');


// DID is lowercase !

var did = "did:yfm:eip-155:43113:0x8db97c7cece249c2b98bdc0226cc4c2a57bf52fc";

var decimal = "" + getHasher(HashType.SHA3_224).update(Buffer.from(did.toLowerCase())).digest(OutputType.BigInt);

console.log(decimal)


