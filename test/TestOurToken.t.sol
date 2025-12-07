// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract TestOurToken is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    address public eve = makeAddr("eve");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        // Give Bob tokens
        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);

        // Give Alice tokens
        vm.prank(msg.sender);
        ourToken.transfer(alice, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransfer() external {
        uint256 amount = 10 ether;

        vm.prank(bob);
        ourToken.transfer(alice, amount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - amount);
        assertEq(ourToken.balanceOf(alice), STARTING_BALANCE + amount);
    }

    function testTransferFailsWithInsufficientBalance() external {
        vm.prank(bob);
        vm.expectRevert(); // OZ ERC20 reverts naturally
        ourToken.transfer(alice, STARTING_BALANCE + 1);
    }

    function testTransferToZeroAddressReverts() external {
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(address(0), 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            ALLOWANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function testApprove() external {
        vm.prank(bob);
        ourToken.approve(alice, 123);

        assertEq(ourToken.allowance(bob, alice), 123);
    }

    function testTransferFromWorks() external {
        uint256 allowanceAmount = 50 ether;
        uint256 transferAmount = 20 ether;

        vm.prank(bob);
        ourToken.approve(alice, allowanceAmount);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), STARTING_BALANCE + transferAmount);
    }

    function testTransferFromReducesAllowance() external {
        vm.prank(bob);
        ourToken.approve(alice, 100);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 40);

        assertEq(ourToken.allowance(bob, alice), 60);
    }

    function testTransferFromFailsWhenAllowanceLow() external {
        vm.prank(bob);
        ourToken.approve(alice, 10);

        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, 11);
    }

    /*//////////////////////////////////////////////////////////////
                        TOTAL SUPPLY / MINT TESTS
    //////////////////////////////////////////////////////////////*/

    function testTotalSupply() external view {
        uint256 deployerBalance = ourToken.balanceOf(msg.sender);
        uint256 expectedTotal = deployerBalance + 2 * STARTING_BALANCE;

        assertEq(ourToken.totalSupply(), expectedTotal);
    }

    function testInitialMintToDeployer() external view {
        assert(ourToken.balanceOf(msg.sender) > 0);
    }

    /*//////////////////////////////////////////////////////////////
                        MISC IMPORTANT TESTS
    //////////////////////////////////////////////////////////////*/

    function testBalanceOfZeroAddressIsZero() external view {
        assertEq(ourToken.balanceOf(address(0)), 0);
    }
}
