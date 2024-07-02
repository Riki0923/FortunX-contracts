const hre = require("hardhat")
const { ethers } = hre

async function main() {

    const Token = await ethers.getContractFactory("FortunX");
    const token = await Token.attach(process.env.FORTUNX_CONTRACT);
    const StakingContract = await ethers.getContractFactory("EnhancedTimeWeightedStaking")
    const stakingContract = await StakingContract.attach(process.env.STAKING_CONTRACT);
    const deployer = await ethers.provider.getSigner(0);

    // First execute the adminTransfer for the tokens

    const tokenAmount = 100;
    const addTokens = await stakingContract.addDistributeTokenAmount(ethers.parseUnits(tokenAmount.toString(), 18));
    const receipt = await addTokens.wait();

    if(receipt.status == 1){
        console.log("Successfully sent ", tokenAmount, "FNX token to the contract via adminTransfer")
    }
    else {
        console.log("Send failed");
    }

    const checkDistributeRewardAmount = await stakingContract.getRewardTokenAmount();
    console.log("RewardAmount is: ", checkDistributeRewardAmount, "in ETH ", checkDistributeRewardAmount / BigInt(10*18));

    const account1 = await ethers.provider.getSigner(1);
    console.log("account1: ", account1)
    const account2 = await ethers.provider.getSigner(2);
    console.log("account2: ", account2);
    const accounts = [account1.address, account2.address];
    console.log("accounts are ", accounts)

    const transferAmounts = [100, 200]; // Amounts to transfer to account1, account2, account3, account4
    const transferAmountUnits = transferAmounts.map(amount => ethers.parseUnits(amount.toString(), 18));


        // Transfer tokens to other accounts
        await token.transfer(account1, transferAmountUnits[0]);
        await token.transfer(account2, transferAmountUnits[1]);
    
        console.log("Tokens transferred to accounts.");

        // Stake with the other accounts
        const stakingAmount = [100, 200];
        const stakingAmountUnits = stakingAmount.map(amount => ethers.parseUnits(amount.toString(), 18));

        await token.connect(account1).approve(stakingContract,stakingAmountUnits[0]);
        await token.connect(account2).approve(stakingContract, stakingAmountUnits[1]);
        await stakingContract.connect(account1).stake(stakingAmountUnits[0]);
        await stakingContract.connect(account2).stake(stakingAmountUnits[1]);

        console.log("Successfully staked the amounts with the other users");


    try {
        const distributeRewards = await stakingContract.distributeRewards();
        const receipt1 = await distributeRewards.wait()
        // Print the result
        
        console.log("Successfully distributed", distributeRewards);
    } catch (error) {
        console.error("Error:", error);
    }

   const rewardTokenAmount = await stakingContract.rewardTokenAmount();
   console.log("Reward token Amount remained: ", rewardTokenAmount);
   const stakes = await stakingContract.getStakes();
   console.log("Stakes are: ", stakes);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });