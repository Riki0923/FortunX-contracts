const hre = require("hardhat")
const { ethers } = hre


async function main () {

    const Token = await ethers.getContractFactory("FortunX");
    const token = await Token.attach(process.env.FORTUNX_CONTRACT);
    const StakingContract = await ethers.getContractFactory("EnhancedTimeWeightedStaking")
    const stakingContract = await StakingContract.attach(process.env.STAKING_CONTRACT);
    const humanReadableAmount = "300000000";
    const deployer = await ethers.provider.getSigner();


    
    // Converting 300 million to wei
    const approvedAmount = ethers.parseUnits(humanReadableAmount, 18);
  
    const tx = await token.approve(stakingContract, approvedAmount);
    const receipt = await tx.wait();
  
    if(receipt.status == 1 ){
      console.log("Approved contract: ", stakingContract, "ApprovedAmount: ", approvedAmount, "FNX Token");
     }
      else{
       console.log("Approval failed");
     }

     const tx2 = await token.updateStakingPool(stakingContract);
     const receipt2 = await tx2.wait();

     if(receipt2.status == 1) {
        console.log("New StakingPool added :", stakingContract);
     }
     else {
        console.log("Transaction failed");
     }

     const readableStakingAmount = "100";
     const stakingAmount = await ethers.parseUnits(readableStakingAmount, 18);
     const tx3 = await stakingContract.stake(stakingAmount);
     const receipt3 = await tx3.wait();

     if(receipt3.status == 1){
        console.log("Successfully staked the amount of: ", stakingAmount, "in Ether format: ", stakingAmount / BigInt(10**18));
     }
     else {
        console.log("Staking unsuccessfull");
     }

     const checkAmount = await stakingContract.getMyStakedAmount(deployer);
     console.log("My staked amount is: ", checkAmount, "In Ether format: ", checkAmount / BigInt(10**18))
     const stakedBalance = await stakingContract.getAllStakedAmount();
     console.log("All staked amount is: ", stakedBalance, "In Eth Format: ", stakedBalance / BigInt(10**18))
     const stake = await stakingContract.getStakes();
     console.log("Stakes are: ", stake);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
  });