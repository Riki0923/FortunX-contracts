const hre = require("hardhat")
const { ethers } = hre

async function main() {

    const Token = await ethers.getContractFactory("FortunX");
    const token = await Token.attach(process.env.FORTUNX_CONTRACT);
    const StakingContract = await ethers.getContractFactory("EnhancedTimeWeightedStaking")
    const stakingContract = await StakingContract.attach(process.env.STAKING_CONTRACT);
    const deployer = await ethers.provider.getSigner(0);
    
    try {
        const unstakeedAmountReadable = '98';
        const unstakedAmount = await ethers.parseUnits(unstakeedAmountReadable, 18);
        const finalAmount = unstakedAmount - (unstakedAmount / BigInt(100));
        const tx = await stakingContract.unstake(unstakedAmount);
        
        // Print the result
        console.log("Successfully unstaked", finalAmount);
    } catch (error) {
        console.error("Error:", error);
    }

    const checkRemainingAmount = await stakingContract.getMyStakedAmount(deployer)
    console.log("My Remaining staked amount is: ", checkRemainingAmount, "In Ether format: ", checkRemainingAmount / BigInt(10**18))
    const stakedBalance = await stakingContract.getAllStakedAmount();
    console.log("All staked amount is: ", stakedBalance, "In Eth Format: ", stakedBalance / BigInt(10**18))
    const stakes = await stakingContract.getStakes();
    console.log("Stakes are: ", stakes);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });