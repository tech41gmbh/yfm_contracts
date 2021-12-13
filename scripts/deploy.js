async function main() {
  const Youfoundme = await ethers.getContractFactory("Youfoundme")

  // Start deployment, returning a promise that resolves to a contract object
  const youfoundme = await Youfoundme.deploy()
  console.log("Contract deployed to address:", youfoundme.address)
}

main()