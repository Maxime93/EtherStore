// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract EtherStoreVulnerable {
    uint256 withdrawlLimit = 1 ether;
    mapping (address => uint256) withdrawlTime;
    mapping (address => uint256) balances;

    function depositFunds() public payable {
        console.log("%s is depositing: %d.", msg.sender, msg.value);
        balances[msg.sender] += msg.value;
        console.log("-------------------");
    }

    function withdrawFunds(uint256 amount) external {
        console.log("%s is withdrawing: %d.", msg.sender, amount);
        require(amount <= withdrawlLimit, "Limit is 1 ether per withdrawl.");
        require(balances[msg.sender] >= amount, "Not enough balance.");
        require(block.timestamp >= withdrawlTime[msg.sender] + 7 days, "Withdrawl time is too close.");

        console.log("Requirements passed, ethers being sent.");
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success == true);
        console.log("Sent.");

        console.log("Updating state variable balances: %d - %d", balances[msg.sender], amount);
        console.log("Updating state variable withdrawlTime: %d -> %d", withdrawlTime[msg.sender], block.timestamp);
        balances[msg.sender] -= amount;
        withdrawlTime[msg.sender] = block.timestamp;
        console.log("State variables updated.");
        console.log("Current EtherStoreVulnerable balance: %d", address(this).balance);
        console.log("-------------------");
    }

    function getBalance() public view returns(uint256) {
        return balances[msg.sender];
    }

    function getwithdrawlTime() public view returns(uint256) {
        return withdrawlTime[msg.sender] + 1 weeks;
    }
}