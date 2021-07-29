// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import 'hardhat/console.sol';
import './PoolInstance.sol';
import './Collector.sol';

contract Factory is Ownable {
    using SafeMath  for uint;

    address public vault;
    Collector public collector;

    event VaultChanged(address oldVault, address newVault);
    event CollectorChanged(Collector oldCollector, Collector newCollector);
    event NewPool(address pool, ERC20 stakedToken, ERC20 rewardToken, uint256 stakedPrice, uint256 rewardPrice);
    event PoolReward(address pool, uint256 rewardPerBlock, uint256 startBlock, uint256 endBlock);
    event PoolProject(address pool, uint256 projectId);
    event PoolLaunchpads(address pool, uint256[] launchpads);

    constructor(address _vault, Collector _collector) {
        vault = _vault;
        emit VaultChanged(address(0), _vault);
        collector = _collector;
        emit CollectorChanged(Collector(address(0)), _collector);
    }

    function setVault(address _vault) external onlyOwner {
        address oldVault = vault;
        vault = _vault;
        emit VaultChanged(oldVault, _vault);
    }

    function setCollector(Collector _collector) external onlyOwner {
        Collector oldCollector = collector;
        collector = _collector;
        emit CollectorChanged(oldCollector, _collector);
    }

    function deployPool(
        ERC20 _stakedToken,
        ERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _projectId,
        uint256[] memory _launchpads,
        uint256 _stakedPrice,
        uint256 _rewardPrice
    ) external onlyOwner {
        require(_endBlock > _startBlock, "endBlock must bigger than startBlock");
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        uint rewardAmount = _endBlock.sub(_startBlock).mul(_rewardPerBlock);
        SafeERC20.safeTransferFrom(_rewardToken, vault, address(this), rewardAmount);

        bytes memory bytecode = type(PoolInstance).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));
        address poolAddress;

        assembly {
            poolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        for (uint i = 0; i < _launchpads.length; i ++) {
            require(collector.launchpadAvaliable(_launchpads[i]) == true, "illegal launchpad");
        }

        require(collector.projectAvaliable(_projectId) == true, "illegal projectId");

        PoolInstance(poolAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerBlock,
            _startBlock,
            _endBlock,
            _projectId,
            _launchpads
        );
        _rewardToken.approve(poolAddress, rewardAmount);

        emit NewPool(poolAddress, _stakedToken, _rewardToken, _stakedPrice, _rewardPrice);
        emit PoolReward(poolAddress, _rewardPerBlock, _startBlock, _endBlock);
        emit PoolProject(poolAddress, _projectId);
        emit PoolLaunchpads(poolAddress, _launchpads);
    }
}
