const { ethers } = require("hardhat");

async function main() {
  // This was just for test 
  // Connect to the provider using the configured network
  const account1 = await ethers.provider.getSigner(0);
  console.log("account1: ", account1)
  const account2 = await ethers.provider.getSigner(1);
  console.log("account2: ", account2);
  const accounts = [account1.address, account2.address];
  console.log("accounts are: ", accounts);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
