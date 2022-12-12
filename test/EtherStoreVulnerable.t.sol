// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/EtherStoreVulnerable.sol";
import "../src/Attacker.sol";


// THIS TEST ONLY WORKS ON FORKED CHAINS
// Test with anvil `anvil --fork-url "https://mainnet.infura.io/v3/<api>"
// Run test `forge test -vvvv --fork-url "https://mainnet.infura.io/v3/<api>"
contract EtherStoreVulnerableTest is Test {
    EtherStoreVulnerable public ethStore;
    Attacker public attacker;
    address testerContractAddress = address(this);
    address bob = address(0x1);
    address mary = address(0x2);

    function setUp() public {
        ethStore = new EtherStoreVulnerable();
        attacker = new Attacker(address(ethStore));
        (bool success,) = payable(address(attacker)).call{value: 2 ether}("");
        require(success);
    }

    function testDeposit() public {
        ethStore.depositFunds{value: 1 ether}();
        uint256 balance = ethStore.getBalance();
        assertEq(balance, 1 ether);
    }

    function testSendEthToBob() public {
        (bool success,) = bob.call{value: 3}("");
        require(success == true);
    }

    function testWithdrawl() public {
        uint256 bobInitialBalance = bob.balance;

        (bool success,) = bob.call{value: 13 ether}("");
        require(success == true);

        vm.startPrank(bob);
        ethStore.depositFunds{value: 5 ether}();
        assertEq(address(ethStore).balance, 5 ether);
        ethStore.withdrawFunds(1 ether);
        assertEq(address(ethStore).balance, 4 ether);
        assertEq(bob.balance, bobInitialBalance + 13 ether - 5 ether + 1 ether);

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + 8 days);

        ethStore.withdrawFunds(1 ether);
        assertEq(address(ethStore).balance, 3 ether);
        assertEq(bob.balance, bobInitialBalance + 13 ether - 5 ether + 2 ether);
        assertEq(ethStore.getBalance(), 3 ether);

        vm.stopPrank();
    }

    function testWithdrawlLimit() public {
        (bool success,) = bob.call{value: 13 ether}("");
        require(success == true);

        vm.startPrank(bob);
        ethStore.depositFunds{value: 5 ether}();
        vm.expectRevert();
        ethStore.withdrawFunds(3 ether);
        vm.stopPrank();
    }

    function testWithdrawlTime() public {
        (bool success,) = bob.call{value: 13 ether}("");
        require(success == true);

        vm.startPrank(bob);
        ethStore.depositFunds{value: 5 ether}();
        ethStore.withdrawFunds(1);

        // Wait less than a week
        vm.roll(block.number + 10);
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert();
        ethStore.withdrawFunds(1);
        vm.stopPrank();
    }

    function testAttack() public {
        // Bob and Mary are using the EtherStore
        // They do not know it is vulnerable
        (bool success,) = bob.call{value: 15 ether}("");
        require(success == true);
        (success,) = mary.call{value: 15 ether}("");
        require(success == true);

        uint256 totalDeposit = 20 ether;
        uint256 singleDeposit = totalDeposit / 2;

        vm.startPrank(bob);
        ethStore.depositFunds{value: singleDeposit}();
        vm.stopPrank();
        vm.startPrank(mary);
        ethStore.depositFunds{value: singleDeposit}();
        vm.stopPrank();

        // Wait a lil bit
        vm.roll(block.number + 10);
        vm.warp(block.timestamp + 2 days);

        uint256 initialAttackerBalance = address(attacker).balance;
        console.log("Attacker initial ether: %d", initialAttackerBalance);

        vm.expectRevert();
        attacker.AttackEtherStore();
        console.log("Attacker new ether: %d", address(attacker).balance);

        // this attack does not work. balances[msg.sender] -= amount;
        // in EtherStoreVulnerable reverts Arithmetic over/underflow
        // When all the calls from the fallback function finally get
        // executed. This might have worked in a previous solidity version.

        // However we are still able to re-enter the contract here.
    }
}
