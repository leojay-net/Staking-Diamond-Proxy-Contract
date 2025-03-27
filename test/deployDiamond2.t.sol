// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
import "contracts/facets/StakingFacet.sol";
import "contracts/facets/ERC20Facet.sol";
import "./helpers/DiamondUtils.sol";
import "./mock/MockERC721.sol";
import "./mock/MockERC1155.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";

contract StakingFacetTest is DiamondUtils, IDiamondCut {
    
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    StakingFacet stakingF;
    ERC20Facet stakeTokenF;
    ERC20Facet rewardTokenF;
    MockERC721 mockERC721;
    MockERC1155 mockERC1155;

    
    uint256 constant STAKE_AMOUNT = 100e18;
    uint256 constant INITIAL_BALANCE = 1000e18;
    uint256 constant REWARD_AMOUNT = 1000e18;
    uint256 constant REWARD_DURATION = 7 days;

    
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    function setUp() public {

        
        _deployContracts();
        
        
        _setupDiamond();
        
        
        _mintTokens();

    }

    function _deployContracts() internal {
        stakeTokenF = new ERC20Facet("Stake Token", "STK");
        rewardTokenF = new ERC20Facet("Reward Token", "RWD");

        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();
        
        stakingF = new StakingFacet(address(stakeTokenF), address(rewardTokenF));
    }

    function _setupDiamond() internal {
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = _createFacetCut(address(dLoupe), "DiamondLoupeFacet");
        cut[1] = _createFacetCut(address(ownerF), "OwnershipFacet");
        cut[2] = _createFacetCut(address(stakeTokenF), "ERC20Facet");
        cut[3] = _createFacetCut(address(stakingF), "StakingFacet");

        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
    }

    function _createFacetCut(address facetAddress, string memory facetName) 
        internal 
        returns (FacetCut memory) 
    {
        return FacetCut({
            facetAddress: facetAddress,
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors(facetName)
        });
    }

    function _mintTokens() internal {
        
        stakeTokenF.mint(owner, INITIAL_BALANCE);
        stakeTokenF.mint(user1, INITIAL_BALANCE);
        // rewardTokenF.mint(owner, INITIAL_BALANCE * 10);
        rewardTokenF.mint(user3, REWARD_AMOUNT);

        
        mockERC721.mint(user1, 1);
        mockERC1155.mint(user1, 1, 5, "");
    }

    function testGetterFunctions() public {
        // Setup: Deploy the ERC20Facet contract with known parameters
        ERC20Facet token = new ERC20Facet("TestToken", "TST");

        // Test name() function
        assertEq(token.name(), "TestToken", "Name should match constructor input");

        // Test symbol() function
        assertEq(token.symbol(), "TST", "Symbol should match constructor input");

        // Test decimals() function
        assertEq(token.decimals(), 18, "Decimals should be 18");

        // Test totalSupply() function before minting
        assertEq(token.totalSupply(), 0, "Initial total supply should be 0");

        // Mint some tokens to test balanceOf and totalSupply
        address testAccount = address(0x1);
        uint256 mintAmount = 1000e18;
        vm.prank(address(this));
        token.mint(testAccount, mintAmount);

        // Test balanceOf() function after minting
        assertEq(token.balanceOf(testAccount), mintAmount, "Minted balance should match");

        // Test totalSupply() function after minting
        assertEq(token.totalSupply(), mintAmount, "Total supply should match minted amount");

        // Test allowance() function before approval
        address spender = address(0x2);
        assertEq(token.allowance(testAccount, spender), 0, "Initial allowance should be 0");

        // Approve some tokens and test allowance
        vm.prank(testAccount);
        token.approve(spender, 500e18);
        assertEq(token.allowance(testAccount, spender), 500e18, "Allowance should match approved amount");
}

function testConstructorParameters() public {
    // Test different token names and symbols
    ERC20Facet token1 = new ERC20Facet("CoolToken", "COOL");
    assertEq(token1.name(), "CoolToken", "Name should match constructor input");
    assertEq(token1.symbol(), "COOL", "Symbol should match constructor input");

    ERC20Facet token2 = new ERC20Facet("AnotherToken", "ANY");
    assertEq(token2.name(), "AnotherToken", "Name should match constructor input");
    assertEq(token2.symbol(), "ANY", "Symbol should match constructor input");
    assertEq(token2.decimals(), 18, "decimals should be 18");
}

function testBalanceOfMultipleAccounts() public {
    ERC20Facet token = new ERC20Facet("TestToken", "TST");

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    uint256 user1Amount = 100e18;
    uint256 user2Amount = 250e18;
    uint256 user3Amount = 500e18;

    vm.startPrank(address(this));
    token.mint(user1, user1Amount);
    token.mint(user2, user2Amount);
    token.mint(user3, user3Amount);
    vm.stopPrank();

    assertEq(token.balanceOf(user1), user1Amount, "User1 balance incorrect");
    assertEq(token.balanceOf(user2), user2Amount, "User2 balance incorrect");
    assertEq(token.balanceOf(user3), user3Amount, "User3 balance incorrect");
    assertEq(token.totalSupply(), user1Amount + user2Amount + user3Amount, "Total supply incorrect");
}

function testAllowanceAndApproval() public {
    ERC20Facet token = new ERC20Facet("TestToken", "TST");

    address owner = address(0x1);
    address spender1 = address(0x2);
    address spender2 = address(0x3);

    vm.prank(owner);
    token.approve(spender1, 100e18);
    assertEq(token.allowance(owner, spender1), 100e18, "Allowance for spender1 incorrect");

    vm.prank(owner);
    token.approve(spender2, 200e18);
    assertEq(token.allowance(owner, spender2), 200e18, "Allowance for spender2 incorrect");

    // Verify that approving a different spender doesn't affect previous allowances
    assertEq(token.allowance(owner, spender1), 100e18, "Spender1 allowance should remain unchanged");
}

    
    function testStakeERC20_Success() public {
        vm.startPrank(owner);
        stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
        stakingF.stakeERC20(STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(stakeTokenF.balanceOf(owner), INITIAL_BALANCE - STAKE_AMOUNT, 
            "Token balance incorrect after staking");
        assertEq(stakingF.balanceStaked(owner), STAKE_AMOUNT, 
            "Staked balance incorrect");
        assertEq(stakingF.totalStaked(), STAKE_AMOUNT, 
            "Total staked incorrect");
    }

    function testStakeERC20_Revert_ZeroAmount() public {
        vm.expectRevert(bytes("amount = 0"));
        stakingF.stakeERC20(0);
    }

    function testWithdrawERC20_Success() public {
        
        vm.startPrank(owner);
        stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
        stakingF.stakeERC20(STAKE_AMOUNT);

        
        stakingF.withdrawERC20(STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(stakeTokenF.balanceOf(owner), INITIAL_BALANCE, 
            "Token balance incorrect after withdrawal");
        assertEq(stakingF.balanceStaked(owner), 0, 
            "Staked balance should be zero");
        assertEq(stakingF.totalStaked(), 0, 
            "Total staked should be zero");
    }

    function testWithdrawERC20_Revert_ZeroAmount() public {
        vm.expectRevert(bytes("amount = 0"));
        stakingF.withdrawERC20(0);
    }

    
    function testStakeERC721_Success() public {
        uint256 tokenId = 1;
        
        vm.startPrank(user1);
        mockERC721.approve(address(stakingF), tokenId);
        stakingF.stakeERC721(address(mockERC721), tokenId);
        vm.stopPrank();

        assertEq(stakingF.balanceStaked(user1), 1, 
            "Staked balance should be 1");
        assertEq(stakingF.totalStaked(), 1, 
            "Total staked should be 1");
    }

    function testStakeERC721_Revert_NotOwner() public {
        uint256 tokenId = 1;
        
        vm.expectRevert(bytes("Not token owner"));
        stakingF.stakeERC721(address(mockERC721), tokenId);
    }

    function testWithdrawERC721_Success() public {
        uint256 tokenId = 1;
        
        vm.startPrank(user1);
        mockERC721.approve(address(stakingF), tokenId);
        stakingF.stakeERC721(address(mockERC721), tokenId);
        stakingF.withdrawERC721(address(mockERC721), tokenId);
        vm.stopPrank();

        assertEq(stakingF.balanceStaked(user1), 0, 
            "Staked balance should be 0");
        assertEq(stakingF.totalStaked(), 0, 
            "Total staked should be 0");
    }

    
    function testStakeERC1155_Success() public {
        uint256 tokenId = 1;
        uint256 amount = 5;
        
        vm.startPrank(user1);
        mockERC1155.setApprovalForAll(address(stakingF), true);
        stakingF.stakeERC1155(address(mockERC1155), tokenId, amount);
        vm.stopPrank();

        assertEq(stakingF.balanceStaked(user1), amount, 
            "Staked balance incorrect");
        assertEq(stakingF.totalStaked(), amount, 
            "Total staked incorrect");
    }

    function testStakeERC1155_Revert_ZeroAmount() public {
        uint256 tokenId = 1;
        
        vm.expectRevert(bytes("amount = 0"));
        stakingF.stakeERC1155(address(mockERC1155), tokenId, 0);
    }

    function testStakeERC1155_Revert_InsufficientBalance() public {
        uint256 tokenId = 1;
        
        vm.expectRevert(bytes("Insufficient balance"));
        stakingF.stakeERC1155(address(mockERC1155), tokenId, 10);
    }

    function testWithdrawERC1155_Success() public {
        uint256 tokenId = 1;
        uint256 amount = 5;
        
        vm.startPrank(user1);
        mockERC1155.setApprovalForAll(address(stakingF), true);
        stakingF.stakeERC1155(address(mockERC1155), tokenId, amount);
        stakingF.withdrawERC1155(address(mockERC1155), tokenId, amount);
        vm.stopPrank();

        assertEq(stakingF.balanceStaked(user1), 0, 
            "Staked balance should be 0");
        assertEq(stakingF.totalStaked(), 0, 
            "Total staked should be 0");
    }

    function testWithdrawERC1155_Revert_ZeroAmount() public {
        vm.expectRevert(bytes("amount = 0"));
        stakingF.withdrawERC1155(address(mockERC1155), 1, 0);
    }

    function testWithdrawERC1155_Revert_InsufficientStaked() public {
        vm.startPrank(user1);
        mockERC1155.setApprovalForAll(address(stakingF), true);
        stakingF.stakeERC1155(address(mockERC1155), 1, 3);
        
        vm.expectRevert(bytes("Insufficient staked"));
        stakingF.withdrawERC1155(address(mockERC1155), 1, 4);
        vm.stopPrank();
    }

//  function _prepareRewards(uint256 amount) internal {
//         // Transfer rewards to the staking contract
//         rewardTokenF.transfer(address(stakingF), amount);
        
//         // Set up rewards
//         vm.startPrank(owner);
//         stakingF.setRewardsDuration(REWARD_DURATION);
//         stakingF.notifyRewardAmount(amount);
//         vm.stopPrank();
//     }


function _prepareRewards(uint256 amount) internal {
    // Transfer rewards to the staking contract
    vm.startPrank(user3);
    rewardTokenF.transfer(address(stakingF), amount);
    vm.stopPrank();
    
    // Set up rewards
    vm.startPrank(owner);
    stakingF.setRewardsDuration(REWARD_DURATION);
    stakingF.notifyRewardAmount(amount);
    vm.stopPrank();
}

function testRewardDistribution_SingleUser() public {
    // Stake tokens
    vm.startPrank(owner);
    stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
    stakingF.stakeERC20(STAKE_AMOUNT);
    vm.stopPrank();
    
    // Prepare and distribute rewards
    _prepareRewards(REWARD_AMOUNT);

    // Skip half the duration
    vm.warp(block.timestamp + (REWARD_DURATION / 2));

    // Check earned rewards
    uint256 earned = stakingF.earned(owner);
    
    // Claim rewards
    vm.prank(owner);
    stakingF.getReward();
    
    assertEq(rewardTokenF.balanceOf(owner), earned, 
        "Should receive correct reward amount");
    assertEq(stakingF.earned(owner), 0, 
        "Earned should reset after claim");
}

function testRewardDistribution_MultipleUsers() public {
    // Transfer rewards to the staking contract
    vm.startPrank(user3);
    rewardTokenF.transfer(address(stakingF), REWARD_AMOUNT);
    vm.stopPrank();

    // Set up rewards duration and amount
    vm.startPrank(owner);
    stakingF.setRewardsDuration(REWARD_DURATION);
    stakingF.notifyRewardAmount(REWARD_AMOUNT);
    vm.stopPrank();

    // Stake tokens for user1
    vm.startPrank(user1);
    stakeTokenF.approve(address(stakingF), 100e18);
    stakingF.stakeERC20(100e18);
    vm.stopPrank();

    // Stake tokens for owner
    vm.startPrank(owner);
    stakeTokenF.approve(address(stakingF), 100e18);
    stakingF.stakeERC20(100e18);
    vm.stopPrank();

    // Skip half the duration
    vm.warp(block.timestamp + (REWARD_DURATION / 2));

    // Check and claim rewards for user1
    uint256 user1EarnedBefore = stakingF.earned(user1);
    assertTrue(user1EarnedBefore > 0, "User1 should have earned rewards");
    
    vm.prank(user1);
    stakingF.getReward();
    assertEq(rewardTokenF.balanceOf(user1), user1EarnedBefore, 
        "User1 should receive correct reward amount");

    // Check and claim rewards for owner
    uint256 ownerEarnedBefore = stakingF.earned(owner);
    assertTrue(ownerEarnedBefore > 0, "Owner should have earned rewards");
    
    vm.prank(owner);
    stakingF.getReward();
    assertEq(rewardTokenF.balanceOf(owner), ownerEarnedBefore, 
        "Owner should receive correct reward amount");
}

function testRewardDistribution_NoRewardsWhenNotStaked() public {
    // Transfer rewards to the staking contract
    vm.startPrank(user3);
    rewardTokenF.transfer(address(stakingF), REWARD_AMOUNT);
    vm.stopPrank();

    // Set up rewards duration and amount
    vm.startPrank(owner);
    stakingF.setRewardsDuration(REWARD_DURATION);
    stakingF.notifyRewardAmount(REWARD_AMOUNT);
    vm.stopPrank();

    // Skip half the duration
    vm.warp(block.timestamp + (REWARD_DURATION / 2));

    // Check earned rewards for user without stake
    uint256 user1Earned = stakingF.earned(user1);
    assertEq(user1Earned, 0, "User without stake should have zero rewards");

    // Try to claim rewards
    vm.prank(user1);
    stakingF.getReward(); 

    assertEq(rewardTokenF.balanceOf(user1), 0, 
        "User without stake should not receive rewards");
}
    
    function testSetRewardsDuration_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(bytes("not authorized"));
        stakingF.setRewardsDuration(REWARD_DURATION);
    }

    function testNotifyRewardAmount_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(bytes("not authorized"));
        stakingF.notifyRewardAmount(REWARD_AMOUNT);
    }

    function testStakingFacet_LastTimeRewardApplicable() public {
    // Set up rewards
    vm.startPrank(user3);
    rewardTokenF.transfer(address(stakingF), REWARD_AMOUNT);
    vm.stopPrank();

    vm.startPrank(owner);
    stakingF.setRewardsDuration(REWARD_DURATION);
    stakingF.notifyRewardAmount(REWARD_AMOUNT);
    vm.stopPrank();

    // Initial last time reward applicable should be current timestamp
    uint256 initialLastTime = stakingF.lastTimeRewardApplicable();
    assertEq(initialLastTime, block.timestamp, 
        "Initial last time reward applicable should be current timestamp");

    // Warp to finish time
    vm.warp(block.timestamp + REWARD_DURATION + 1);

    // Last time reward applicable should not exceed finish time
    uint256 finalLastTime = stakingF.lastTimeRewardApplicable();
    assertEq(finalLastTime, stakingF.getFinalAt(), 
        "Last time reward applicable should not exceed finish time");
}

function testStakingFacet_RewardPerToken() public {
    // Stake tokens
    vm.startPrank(owner);
    stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
    stakingF.stakeERC20(STAKE_AMOUNT);
    vm.stopPrank();

    // Set up rewards
    vm.startPrank(user3);
    rewardTokenF.transfer(address(stakingF), REWARD_AMOUNT);
    vm.stopPrank();

    vm.startPrank(owner);
    stakingF.setRewardsDuration(REWARD_DURATION);
    stakingF.notifyRewardAmount(REWARD_AMOUNT);
    vm.stopPrank();

    // Initial reward per token should be 0
    uint256 initialRewardPerToken = stakingF.rewardPerToken();
    assertEq(initialRewardPerToken, 0, 
        "Initial reward per token should be 0");

    // Warp to half duration
    vm.warp(block.timestamp + (REWARD_DURATION / 2));

    // Reward per token should increase
    uint256 midRewardPerToken = stakingF.rewardPerToken();
    assertTrue(midRewardPerToken > 0, 
        "Reward per token should increase over time");
}


function testStakingFacet_Earned_ComplexScenario() public {
    // Stake tokens for multiple users
    vm.startPrank(owner);
    stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
    stakingF.stakeERC20(STAKE_AMOUNT);
    vm.stopPrank();

    vm.startPrank(user1);
    stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
    stakingF.stakeERC20(STAKE_AMOUNT);
    vm.stopPrank();

    // Set up rewards
    vm.startPrank(user3);
    rewardTokenF.transfer(address(stakingF), REWARD_AMOUNT);
    vm.stopPrank();

    vm.startPrank(owner);
    stakingF.setRewardsDuration(REWARD_DURATION);
    stakingF.notifyRewardAmount(REWARD_AMOUNT);
    vm.stopPrank();

    // Warp to half duration
    vm.warp(block.timestamp + (REWARD_DURATION / 2));

    // Check earned for both users
    uint256 ownerEarned = stakingF.earned(owner);
    uint256 user1Earned = stakingF.earned(user1);

    // Earned should be roughly equal as they staked the same amount
    assertApproxEqRel(ownerEarned, user1Earned, 0.01e18, 
        "Earned rewards should be approximately equal for equal stakes");

    // Claim rewards for owner
    vm.prank(owner);
    stakingF.getReward();

    // Earned for owner should reset
    assertEq(stakingF.earned(owner), 0, 
        "Earned should reset after claiming");
}

function testStakingFacet_GetReward_NoRewards() public {
    // Stake some tokens
    vm.startPrank(owner);
    stakeTokenF.approve(address(stakingF), STAKE_AMOUNT);
    stakingF.stakeERC20(STAKE_AMOUNT);
    vm.stopPrank();

    // Get reward without any rewards distributed
    vm.prank(owner);
    stakingF.getReward();

    // Balance should remain unchanged
    assertEq(rewardTokenF.balanceOf(owner), 0, 
        "Should not receive any rewards when no rewards distributed");
}
    
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}

}