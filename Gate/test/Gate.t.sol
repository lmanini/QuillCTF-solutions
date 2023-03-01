// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Gate.sol";

contract GateTest is Test {
    Gate gate;
    address gateExploit;

    function setUp() external {
        gate = new Gate();
    }

    function testExploit() external {
        vm.chainId(1); // needed for the exploit to work! otherwise in foundry chain id is 31337
        
        gateExploit = deployExploit();
        gate.open(gateExploit);
        assertTrue(gate.opened());
    }

    function deployExploit() internal returns (address pointer) {
        bytes memory code = abi.encodePacked(
            hex"63",
            uint32(0x20),
            hex"80_60_0E_60_00_39_60_00_F3",
            hex"3634601c37345180600f57336019565b461460175758fd5b325b3452602034f3"
        );
        assembly {
            pointer := create(0, add(code, 0x20), mload(code))
        }
    }

}
