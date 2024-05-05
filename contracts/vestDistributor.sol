// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TokenVesting is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 internal constant ONE_MONTH_IN_SECONDS = 2592000;

    IERC20 public token;
    bytes32 public merkleRoot; // to be calculated and set here

    uint256 public deployedAt;

    mapping(address => uint256) public totalVestedAmount;
    mapping(address => uint256) public claimedAmount;

    mapping(address => uint256) public walletSchedule;
    mapping(address => uint256) private lastClaimedAt;

    event Claimed(address indexed account, uint256 amount);
    event Started(address indexed account, uint256 amount);

    constructor(IERC20 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
        deployedAt = block.timestamp;
    }

    function lastClaimDate(address _wallet) public view returns(uint256){
        if(lastClaimedAt[_wallet] == 0){
            return deployedAt;
        }else{
            return lastClaimedAt[_wallet];
        }
    }

    function start(uint256 amount, bytes32[] calldata merkleProof, uint256 vestingSchedule) external nonReentrant {
        require(vestingSchedule <= 8 && vestingSchedule >= 1, "Invalid vesting schedule");
        require(!isClaimed(msg.sender), "Tokens already claimed");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, vestingSchedule));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");

        walletSchedule[msg.sender] = vestingSchedule;
        totalVestedAmount[msg.sender] = amount;

        emit Started(msg.sender, amount);
    }

    function claim() external nonReentrant {
        uint256 amount = claimableAmount(msg.sender);
        claimedAmount[msg.sender] += amount;
        token.transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function isClaimed(address account) public view returns (bool) {
        return totalVestedAmount[account] > 0;
    }

    function claimableAmount(address _wallet) public view returns (uint256 _claimableAmount) {
        uint256 schedule = walletSchedule[_wallet];
        uint256 totalVest = totalVestedAmount[_wallet];
        uint256 _claimedAmount = claimedAmount[_wallet];
        if(schedule == 2){
            uint256 monthlyRelease = totalVest/36;
            _claimableAmount += monthlyRelease;
            if((block.timestamp - deployedAt) <= ONE_MONTH_IN_SECONDS){
                return _claimableAmount - _claimedAmount;
            }else if((block.timestamp - deployedAt) >= ONE_MONTH_IN_SECONDS * 36) {
                return totalVest - _claimedAmount;
            }else {
                return monthlyRelease * ((block.timestamp - deployedAt) / ONE_MONTH_IN_SECONDS) - _claimedAmount;
            }
        }else if(schedule == 3 || schedule == 4){
            uint256 initiallyAvailable = (totalVest * 25) / 100;
            totalVest -= initiallyAvailable;
            uint256 monthlyRelease = totalVest/12;
            _claimableAmount += initiallyAvailable;
            if((block.timestamp - deployedAt) <= ONE_MONTH_IN_SECONDS){
                return _claimableAmount - _claimedAmount;
            }else if((block.timestamp - deployedAt) >= ONE_MONTH_IN_SECONDS * 12) {
                return totalVest + initiallyAvailable - _claimedAmount;
            }else {
                return initiallyAvailable + monthlyRelease * ((block.timestamp - deployedAt) / ONE_MONTH_IN_SECONDS) - _claimedAmount;
            }
        }else if(schedule == 5 || schedule == 6){
            uint256 monthlyRelease = totalVest/36;
            if((block.timestamp - deployedAt) >= ONE_MONTH_IN_SECONDS * 12) {
                return totalVest - _claimedAmount;
            }else {
                return monthlyRelease * 6 * ((block.timestamp - deployedAt) / (6 * ONE_MONTH_IN_SECONDS)) - _claimedAmount;
            }
        }else if(schedule == 7){
            uint256 monthlyRelease = totalVest/18;
            if((block.timestamp - deployedAt) >= ONE_MONTH_IN_SECONDS * 12) {
                return totalVest - _claimedAmount;
            }else {
                return monthlyRelease * 6 * ((block.timestamp - deployedAt) / (6 * ONE_MONTH_IN_SECONDS)) - _claimedAmount;
            }
        }else{
            return totalVest - _claimedAmount;
        }
    }
}