
const { getHasher, OutputType, HashType } = require('bigint-hash');


// DID is lowercase !

var did = "did:yfm:eip-155:43113:0x58d22f24cd7fda155f9f7eefe9b32add46388ab9";

var decimal = "" + getHasher(HashType.SHA3_224).update(Buffer.from(did.toLowerCase())).digest(OutputType.BigInt);

console.log(decimal)


