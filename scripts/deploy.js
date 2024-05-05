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

  // const MyToken = await ethers.deployContract("MyToken", ["0x49cB5Fa951AD2ABbC4d14239BfE215754c7Df030"]);
  // const myToken = await MyToken.waitForDeployment();

  // IERC20 compatible ERC20 contract address is: 0xE586385922CfA1f0538a659C6fE4838a31769152 

  const StakingContract = await ethers.deployContract("EnhancedTimeWeightedStaking", ["0xE586385922CfA1f0538a659C6fE4838a31769152", deployer]);
  const stakingContract = await StakingContract.waitForDeployment();

  const FortunX = await ethers.deployContract("FortunX", [stakingContract])
  const fortunX = await FortunX.waitForDeployment();

  console.log("stakingContract deployed at: ", stakingContract)
  console.log("FortunX contract deployed at: ", fortunX)
  // console.log("MyToken deployed at: ", myToken);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


//stakingcontract: 0xed79B7C2efc27f1733E626D1821c02F419d8E104  (argumentek: 0xE586385922CfA1f0538a659C6fE4838a31769152 0x49cB5Fa951AD2ABbC4d14239BfE215754c7Df030 )

//FortunX contract: 0x5BC92750884189EA85d0c3A397D84D95Fa1b5830 (argumentek: 0xed79B7C2efc27f1733E626D1821c02F419d8E104  )