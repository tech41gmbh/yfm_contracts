/**
* @type import('hardhat/config').HardhatUserConfig
*/
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const { API_URL, PRIVATE_KEY } = process.env;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
   solidity: "0.8.0",
   defaultNetwork: "fuji",
   networks: {
      hardhat: {},
      ganache: {
         url: "http://127.0.0.1:7545",
         accounts: {
           mnemonic: "symptom bean awful husband dice accident crush tank sun notice club creek",
         },
      // chainId: 1234,
      },
      fuji: {
         url: API_URL,
         accounts: [`0x${PRIVATE_KEY}`]
      }
   },
}
