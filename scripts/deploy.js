// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const deployer = await ethers.provider.getSigner(0);

  console.log("Deploying contracts with the account:", await deployer.getAddress());

  const FortunX = await ethers.deployContract("FortunX")
  const fortunX = await FortunX.waitForDeployment();

  const StakingContract = await ethers.deployContract("EnhancedTimeWeightedStaking", [fortunX, deployer]);
  const stakingContract = await StakingContract.waitForDeployment();

  console.log("FortunX contract deployed at: ", fortunX.target)
  console.log("stakingContract deployed at: ", stakingContract.target)

}

// arbitrum sepolia fortunx contract: 0x6cf2cd877020aA4c228843Db3dF26E4F3EE510e5
// arbitrum sepolia staking contract: 0x3C28f0D582E3f49D9994fB3FABC1413D7704946c

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
