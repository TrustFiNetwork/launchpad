// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import 'hardhat/console.sol';

contract PoolInstance {
    using SafeMath for uint256;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;


    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    address public immutable FACTORY;

    bool public isInitialized;

    uint256 public accTokenPerShare;

    uint256 public totalStake;

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public lastRewardBlock;

    uint256 public rewardPerBlock;

    uint256 public PRECISION_FACTOR;

    ERC20 public rewardToken;

    ERC20 public stakedToken;

    uint256 public projectId;

    uint256[] public launchpads;

    mapping(address => UserInfo) public userInfo;

    mapping(address => uint256) public userVoted;
    mapping(uint256 => uint256) public launchpadVoted;
    uint256 public totalVoted;
    mapping(address => bool) public userFavorite;
    uint256 public totalFavorite;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Vote(address indexed user, address pool, uint source, uint num);
    event Favorite(address indexed user);

    constructor() {
        _status = _NOT_ENTERED;
        FACTORY = msg.sender;
    }

    function initialize(
        ERC20 _stakedToken,
        ERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _projectId,
        uint256[] calldata _launchpads
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == FACTORY, "Only factory can do this");

        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        projectId = _projectId;

        launchpads = _launchpads;

        lastRewardBlock = startBlock;
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        SafeERC20.safeTransferFrom(rewardToken, FACTORY, address(this), reward);

        if (totalStake == 0) {
            lastRewardBlock = block.number;
            return;
        }

        accTokenPerShare = accTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(totalStake));

        lastRewardBlock = block.number;
    }

    function deposit(uint256 launchpad, uint256 _amount) external nonReentrant {
        console.log("block.number:", block.number);
        require(block.number <= endBlock, "not the right time");
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                SafeERC20.safeTransfer(rewardToken, address(msg.sender), pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            SafeERC20.safeTransferFrom(stakedToken, address(msg.sender), address(this), _amount);
            totalStake = totalStake.add(_amount);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
        doVote(launchpad, _amount);
    }

    function withdraw() external nonReentrant {
        console.log("block.number: ", block.number);
        require(block.number > endBlock, "not the right time");
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        uint _amount = user.amount;
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            SafeERC20.safeTransfer(stakedToken, address(msg.sender), _amount);
        }

        if (pending > 0) {
            SafeERC20.safeTransfer(rewardToken, address(msg.sender), pending);
            emit Claim(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Withdraw(msg.sender, _amount);
    }

    function emergencyWithdraw() external nonReentrant {
        require(block.number > endBlock, "not the right time");
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            SafeERC20.safeTransfer(stakedToken, address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = totalStake;
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
                accTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    function claim(address _user) external {
        UserInfo storage user = userInfo[_user];

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (pending > 0) {
            SafeERC20.safeTransfer(rewardToken, _user, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Claim(_user, pending);
    }

    function totalVoteNum(address _user) external view returns (uint256) {
        if (block.number < startBlock || block.number > endBlock) {
            return 0;
        }
        UserInfo storage user = userInfo[_user];
        return user.amount.sub(userVoted[_user]);
    }

    function doVote(uint256 launchpad, uint256 num) internal {
        require(launchpad < launchpads.length, "illegal source");
        launchpadVoted[launchpad] = launchpadVoted[launchpad].add(num);
        userVoted[msg.sender] = userVoted[msg.sender].add(num);
        totalVoted = totalVoted.add(num);
        require(userVoted[msg.sender] <= userInfo[msg.sender].amount, "illegal num");
        emit Vote(msg.sender, address(this), launchpad, num);
    }

    function doFavorite() external {
        require(userFavorite[msg.sender] == false, "already favorite");
        require(block.number <= endBlock, "already finish");
        userFavorite[msg.sender] = true;
        totalFavorite = totalFavorite.add(1);
        emit Favorite(msg.sender);
    }
}
