// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";


struct AppStorageStruct {
    IERC20 erc20Token;
    IERC721 erc721Token;
    IERC1155 erc1155Token;
    

    // Duration of rewards to be paid out (in seconds)
    uint256 duration;
    // Timestamp of when the rewards finish
    uint256 finishAt;
    // Minimum of last updated time and reward finish time
    uint256 updatedAt;
    // Reward to be paid out per second
    uint256 rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) rewards;
    // Total staked
    uint256 totalStaked;
    // User address => staked amount
    mapping(address => uint256) balanceStaked;
    
    IERC20 rewardToken;
    mapping(address => mapping(address => uint256[])) erc721Staked;
    mapping(address => mapping(address => mapping(uint256 => uint256))) erc1155Staked;

    //ERC20 Facet
    mapping(address account => uint256) _balances;
    mapping(address account => mapping(address spender => uint256)) _allowances;
    uint256 _totalSupply;
    string _name;
    string _symbol;



}