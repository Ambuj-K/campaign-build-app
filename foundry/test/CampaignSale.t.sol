// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/CampaignSale.sol";
import "../src/PlatformToken.sol";

interface CheatCodes {
    function startPrank(address) external;
    function stopPrank() external;
    function expectEmit(bool, bool, bool, bool) external;
    function warp(uint256) external;
    function roll(uint256) external;
}

contract CampaignSaleTest is DSTest {
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    CampaignSale public CampaignSaleObj;
    PlatformToken public token;

    function setUp() public {
        token =new PlatformToken();
        CampaignSaleObj = new CampaignSale(address(token));
    }

    function testCreateContributeWithdrawClaim() public {
        // create campaign via addr
        address addr = 0x1234567890123456789012345678901234567890;
        token.transfer(address(addr), 1000 ether);
        emit log_uint(token.balanceOf(address(addr)));
        cheats.startPrank(address(addr));
        CampaignSaleObj.launchCampaign(30 ether, uint32(block.timestamp + 1 days), uint32(block.timestamp + 91 days));
        cheats.stopPrank();
        // use 2nd address to contribute
        address addr1 = 0x1234567890123456789012345678901234567892;
        token.transfer(address(addr1), 1000 ether);
        emit log_uint(token.balanceOf(address(addr1)));
        cheats.startPrank(address(addr1));
        // approval from 2nd acc for contract transfer
        token.approve(address(CampaignSaleObj), 20 ether);
        // addr 1 contribute to campaign
        CampaignSaleObj.contribute(0, 20 ether);
        cheats.stopPrank();
        emit log_uint(token.balanceOf(address(addr1)));
        assertEq(token.balanceOf(address(addr1)), 980 ether);
        // use 3rd address to contribute
        address addr2 = 0x1234567890123456789012345678901234567893;
        token.transfer(address(addr2), 1000 ether);
        emit log_uint(token.balanceOf(address(addr2)));
        cheats.startPrank(address(addr2));
        // approval from 3rd acc for contract transfer
        token.approve(address(CampaignSaleObj), 20 ether);
        // addr 2 contribute to campaign 20
        CampaignSaleObj.contribute(0, 20 ether);
        cheats.stopPrank();
        assertEq(token.balanceOf(address(addr2)), 980 ether);
        cheats.startPrank(address(addr1));
        // withdraw 10 ether from campaign via addr1
        CampaignSaleObj.withdraw(0, 10 ether);
        cheats.stopPrank();
        assertEq(token.balanceOf(address(addr1)), 990 ether);
        assertEq(CampaignSaleObj.getCampaign(0).creator,addr);
        // check campaign balance to 30
        assertEq(CampaignSaleObj.getCampaign(0).pledged,30 ether);
        cheats.warp(92 days);
        cheats.startPrank(address(addr));
        CampaignSaleObj.claimCampaign(0);
        cheats.stopPrank();
        // check balance of user addr, creator of campaign
        assertEq(token.balanceOf(address(addr)), 1030 ether);
    }

    // create campaign
    // function testLaunchCampaign() public {
    //     address addr = 0x1234567890123456789012345678901234567890;
    //     token.transfer(address(addr), 1000 ether);
    //     emit log_uint(token.balanceOf(address(addr)));
    //     cheats.startPrank(address(addr));
    //     CampaignSaleObj.launchCampaign(100 ether, uint32(block.timestamp + 1 days), uint32(block.timestamp + 91 days));
    //     cheats.stopPrank();
    //     emit log_address(CampaignSaleObj.getCampaign(0).creator);
    //     assertEq(CampaignSaleObj.getCampaign(0).creator,addr);
    // }

}
