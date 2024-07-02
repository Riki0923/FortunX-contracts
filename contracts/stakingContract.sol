// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface FortunxToken {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
  function getFeePercentage() external returns (uint256);
}

contract EnhancedTimeWeightedStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    FortunxToken private _fortunxToken;

    struct Stake {
        uint256 id;
        address user;
        uint256 amount;
    }

    uint256 public rewardTokenAmount;
    uint256 public stakedBalance;
    uint256 public nextId;
    Stake[] public stakes;
    mapping(address => uint256) public userStakedAmount;
    mapping(address => uint256) public userStakeId;
    mapping(address => bool) public hasUserStaked;

    event Staked(address indexed user, uint256 amount, uint256 lastRewardTime);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardAdded(uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(address token, address initialOwner) Ownable(initialOwner) {
        _fortunxToken = FortunxToken(token);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");

        uint256 fee = _fortunxToken.getFeePercentage();
        uint256 excludedAmount = amount * fee / 100; // 1% amount
        uint256 newAmount = amount - excludedAmount; // amount - fee

        if(hasUserStaked[msg.sender] == false){
        stakes.push(Stake({
            id: nextId,
            user: msg.sender,
            amount: newAmount
        }));

        stakedBalance += newAmount;
        userStakedAmount[msg.sender] += newAmount;
        userStakeId[msg.sender] = nextId;
        nextId++;
        } else {
            uint userId = userStakeId[msg.sender];
            stakes[userId].amount += newAmount;
        }

        _fortunxToken.transferFrom(msg.sender, address(this), newAmount); 
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function addDistributeTokenAmount (uint256 amount) public onlyOwner(){
        rewardTokenAmount += amount;
        _fortunxToken.transferFrom(msg.sender, address(this), amount);
    }

    function distributeRewards() public onlyOwner() { // This has to be called via the chainlink Keeper or manually via OnlyOwner

        for(uint i = 0; i < stakes.length; i++){
            if(stakes[i].amount > 0){
                _fortunxToken.transfer(stakes[i].user, rewardTokenAmount * stakes[i].amount / stakedBalance);
            }
        }

        rewardTokenAmount = 0;

        // emit RewardClaimed(msg.sender, reward); => This will require more gas, do we need it?
    }

    function unstake(uint256 amount) external nonReentrant {
        // Write a function which checks how much the user can withhold with the weighted share calculations. 
        uint256 userId = userStakeId[msg.sender]; // This code gives out the user's Id in the Struct

        require(userStakedAmount[msg.sender] > amount, "You have staked less that you want to unstake");
        require(stakes[userId].user == msg.sender, "Stake does not belong to you");

        uint256 fee = _fortunxToken.getFeePercentage();
        uint256 excludedAmount = amount * fee / 100; // 1% amount
        uint256 newAmount = amount - excludedAmount; // amount - fee

        stakedBalance -= amount;
        stakes[userId].amount -= amount;
        userStakedAmount[msg.sender] -= amount;
        _fortunxToken.transfer(msg.sender, newAmount);

        emit Withdrawn(msg.sender, newAmount);
    }


    function adminTransfer(address recipient, uint256 amount) public onlyOwner(){
        _fortunxToken.transfer(recipient, amount); //adminTransfer in case of need
    }

    function getContractBalanceAdmin() public view onlyOwner returns(uint256){ // If admin wants to see the erc20 balance on this contract
        return _fortunxToken.balanceOf(address(this));
    }

    function getAllStakedAmount () public view returns (uint256) {
        return stakedBalance; // returns all staked amount made to the contract
    }

    function getMyStakedAmount (address user) public view returns (uint256){
        return userStakedAmount[user]; // returns a given user's staked amount
    }

    function getRewardTokenAmount() public view returns (uint256){
        return rewardTokenAmount;
    }

    // for test

    function getStakes() public view returns(Stake[] memory){
        return stakes;
    }
}
