// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnhancedTimeWeightedStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;

    struct Stake {
        address user;
        uint256 amount;
        uint256 lastRewardTime;
        uint256 endTime;
    }

    uint256 private totalWeightedShares;
    uint256 public stakedBalance;
    Stake[] public stakes;
    mapping(address => uint256[]) public userStakeIndexes;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount, uint256 lastRewardTime, uint256 indexed stakeIndex);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardAdded(uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(IERC20 _stakingToken, address initialOwner) Ownable(initialOwner) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount); // ide lehet hogy csak sima transfer kéne, 

        stakes.push(Stake({
            user: msg.sender,
            amount: amount,
            lastRewardTime: block.timestamp,
            endTime: 0
        }));
        stakedBalance += amount;

        uint256 index = stakes.length - 1;
        userStakeIndexes[msg.sender].push(index);

        emit Staked(msg.sender, amount, block.timestamp, index);
    }

    function distributeRewards() public nonReentrant {
        uint256 contractBalance = stakingToken.balanceOf(address(this)) - stakedBalance;
        require(contractBalance > 0, "No rewards to distribute");

        totalWeightedShares = calculateTotalWeightedShares();

        for (uint i = 0; i < stakes.length; i++) {
            if (stakes[i].endTime == 0) {
                uint256 stakeDuration = block.timestamp - stakes[i].lastRewardTime;
                uint256 weightedShare = stakes[i].amount * stakeDuration;
                uint256 reward = (contractBalance * weightedShare) / totalWeightedShares;
                stakes[i].lastRewardTime = block.timestamp;

                rewards[stakes[i].user] += reward;
            }
        }

        emit RewardAdded(contractBalance);
    }

    function calculateTotalWeightedShares() private view returns (uint256) {
        uint256 _totalWeightedShares = 0;
        for (uint i = 0; i < stakes.length; i++) {
            if (stakes[i].endTime == 0) {
                uint256 stakeDuration = block.timestamp - stakes[i].lastRewardTime;
                _totalWeightedShares += stakes[i].amount * stakeDuration;
            }
        }
        return _totalWeightedShares;
    }

    function claimRewards() external nonReentrant {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        stakingToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function unstake(uint256 stakeIndex) external nonReentrant {
        require(stakeIndex < userStakeIndexes[msg.sender].length, "Invalid stake index");

        uint256 stakeId = userStakeIndexes[msg.sender][stakeIndex];
        require(stakeId < stakes.length, "Invalid stake ID");
        Stake storage userStake = stakes[stakeId];

        require(userStake.user == msg.sender, "Stake does not belong to you");
        require(userStake.endTime == 0, "Stake already unstaked");

        userStake.endTime = block.timestamp;

        uint256 stakeDuration = userStake.endTime - userStake.lastRewardTime;
        uint256 weightedShare = userStake.amount * stakeDuration;

        uint256 contractBalance = stakingToken.balanceOf(address(this)) - stakedBalance;
        stakingToken.safeTransfer(msg.sender, rewards[msg.sender] + userStake.amount + (contractBalance * weightedShare) / totalWeightedShares);
        stakedBalance -= userStake.amount;
        rewards[msg.sender] = 0;

        emit Withdrawn(msg.sender, userStake.amount);
    }


}
