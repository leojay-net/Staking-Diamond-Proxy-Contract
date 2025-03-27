
pragma solidity ^0.8.0;

import "../libraries/AppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
// import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract StakingFacet  {
    AppStorageStruct internal _storage;

    address _owner;

    constructor(address _erc20Token, address _rewardToken) {
        _storage.erc20Token = IERC20(_erc20Token);
        _storage.rewardToken = IERC20(_rewardToken);
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        // LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == _owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        _storage.rewardPerTokenStored = rewardPerToken();
        _storage.updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            _storage.rewards[_account] = earned(_account);
            _storage.userRewardPerTokenPaid[_account] = _storage.rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(_storage.finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_storage.totalStaked == 0) {
            return _storage.rewardPerTokenStored;
        }

        return _storage.rewardPerTokenStored
            + (_storage.rewardRate * (lastTimeRewardApplicable() - _storage.updatedAt) * 1e18)
                / _storage.totalStaked;
    }

    
    function stakeERC20(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        _storage.erc20Token.transferFrom(msg.sender, address(this), _amount);
        _storage.balanceStaked[msg.sender] += _amount;
        _storage.totalStaked += _amount;
    }

    
    function stakeERC721(address _nftContract, uint256 _tokenId) external updateReward(msg.sender) {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not token owner");
        
        nft.transferFrom(msg.sender, address(this), _tokenId);
        _storage.erc721Staked[msg.sender][_nftContract].push(_tokenId);
        _storage.balanceStaked[msg.sender] += 1; 
        _storage.totalStaked += 1;
    }

    
    function stakeERC1155(address _nftContract, uint256 _tokenId, uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        IERC1155 nft = IERC1155(_nftContract);
        require(nft.balanceOf(msg.sender, _tokenId) >= _amount, "Insufficient balance");
        
        nft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        _storage.erc1155Staked[msg.sender][_nftContract][_tokenId] += _amount;
        _storage.balanceStaked[msg.sender] += _amount;
        _storage.totalStaked += _amount;
    }

    
    function withdrawERC20(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        _storage.balanceStaked[msg.sender] -= _amount;
        _storage.totalStaked -= _amount;
        _storage.erc20Token.transfer(msg.sender, _amount);
    }

    function withdrawERC721(address _nftContract, uint256 _tokenId) external updateReward(msg.sender) {
        
        
        _storage.balanceStaked[msg.sender] -= 1;
        _storage.totalStaked -= 1;
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
    }

    function withdrawERC1155(address _nftContract, uint256 _tokenId, uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        require(_storage.erc1155Staked[msg.sender][_nftContract][_tokenId] >= _amount, "Insufficient staked");
        
        _storage.erc1155Staked[msg.sender][_nftContract][_tokenId] -= _amount;
        _storage.balanceStaked[msg.sender] -= _amount;
        _storage.totalStaked -= _amount;
        IERC1155(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
    }

    
    function earned(address _account) public view returns (uint256) {
        return (
            (
                _storage.balanceStaked[_account]
                    * (rewardPerToken() - _storage.userRewardPerTokenPaid[_account])
            ) / 1e18
        ) + _storage.rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = _storage.rewards[msg.sender];
        if (reward > 0) {
            _storage.rewards[msg.sender] = 0;
            _storage.rewardToken.transfer(msg.sender, reward);
        }
    }

    function balanceStaked(address account) external view returns(uint256) {
        return _storage.balanceStaked[account];
    }

    function totalStaked() external view returns(uint256) {
        return _storage.totalStaked;
    }

    function getFinalAt() external view returns(uint256) {
        return _storage.finishAt;
    }

    
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(_storage.finishAt < block.timestamp, "reward duration not finished");
        _storage.duration = _duration;
    }

    function notifyRewardAmount(uint256 _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= _storage.finishAt) {
            _storage.rewardRate = _amount / _storage.duration;
        } else {
            uint256 remainingRewards = (_storage.finishAt - block.timestamp) * _storage.rewardRate;
            _storage.rewardRate = (_amount + remainingRewards) / _storage.duration;
        }

        require(_storage.rewardRate > 0, "reward rate = 0");
        require(
            _storage.rewardRate * _storage.duration <= _storage.rewardToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        _storage.finishAt = block.timestamp + _storage.duration;
        _storage.updatedAt = block.timestamp;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}