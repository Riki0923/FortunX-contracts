const hre = require("hardhat")
const { ethers } = hre

async function main() {

    const Token = await ethers.getContractFactory("FortunX");
    const token = await Token.attach(process.env.FORTUNX_CONTRACT);
    const StakingContract = await ethers.getContractFactory("EnhancedTimeWeightedStaking")
    const stakingContract = await StakingContract.attach(process.env.STAKING_CONTRACT);
    const deployer = await ethers.provider.getSigner(0);

    // First get the accounts I am going to call the the Claim functions

    const account1 = await ethers.provider.getSigner(1);
    console.log("account1: ", account1)
    const account2 = await ethers.provider.getSigner(2);
    console.log("account2: ", account2);
    const accounts = [account1.address, account2.address];
    console.log("accounts are ", accounts);

    const stakesBefore = await stakingContract.getStakes();
    console.log("Stakes are before claims: ", stakesBefore);

    await stakingContract.claimReward();
    await stakingContract.connect(account1).claimReward();
    await stakingContract.connect(account2).claimReward();

    console.log("Successfully staked claimed the tokens for all users")
   const stakesAfter = await stakingContract.getStakes();
   console.log("Stakes are after claims: ", stakesAfter);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });