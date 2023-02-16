// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TrueXOR.sol";
import "../src/TrueXORExploit.sol";

contract TrueXORTest is Test {
    TrueXOR trueXor;
    TrueXORExploit exploit;

    function setUp() external {
        trueXor = new TrueXOR();
        exploit = new TrueXORExploit();
    }

    function testExploit() external {
        vm.prank(msg.sender);
        bool success = trueXor.callMe{gas: 10000}(address(exploit));
        assertTrue(success);
    }
}
