// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Test, console2} from "forge-std/Test.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {SuperfluidMulticallForwarder} from "../src/SuperfluidMulticallForwarder.sol";
import {
    BatchOperation,
    IConstantFlowAgreementV1,
    ISuperfluid,
    ISuperfluidToken,
    ISuperToken
} from "superfluid-contracts/interfaces/superfluid/ISuperfluid.sol";

interface ISuperfluidGovernanceBase {
    function enableTrustedForwarder(ISuperfluid host, ISuperToken superToken, address trustedForwarder) external;

    function isTrustedForwarder(ISuperfluid host, ISuperToken superToken, address trustedForwarder)
        external
        view
        returns (bool);
}

interface ICFAv1Forwarder {
    function createFlow(ISuperToken token, address sender, address receiver, int96 flowrate, bytes memory userData)
        external;

    function getFlowrate(ISuperToken token, address sender, address receiver) external view returns (int96 flowrate);
}

/// Fork Test

contract SuperfluidMulticallForwarderTest is Test {
    SuperfluidMulticallForwarder public multicallForwarder;

    address public constant cfaForwarderAddress = 0xcfA132E353cB4E398080B9700609bb008eceB125;
    ISuperToken public constant superToken = ISuperToken(0x19E6F96A887D0a27d60ef63942d7BF707fb1aD08);
    ISuperfluid public constant host = ISuperfluid(0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9);
    IConstantFlowAgreementV1 public constant cfav1 = IConstantFlowAgreementV1(0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8);
    ISuperfluidGovernanceBase public gov;
    address public constant sender = 0xF72c73981550D5120537e8613e3A9BE4B6F5482E;

    function setUp() public {
        multicallForwarder = new SuperfluidMulticallForwarder();
        gov = ISuperfluidGovernanceBase(address(host.getGovernance()));
        vm.startPrank(Ownable(address(gov)).owner());
        gov.enableTrustedForwarder(host, ISuperToken(address(0)), address(multicallForwarder));
        vm.stopPrank();
    }

    function testMulticallForwarderIsTrustedForwarder() public {
        assertEq(gov.isTrustedForwarder(host, ISuperToken(address(0)), address(multicallForwarder)), true);
    }

    function testMulticallCreateFlow() public {
        int96 flowRate = int96(1000);
        
        // craft operation call data for forward batch call
        bytes memory operationCallData =
            abi.encodeCall(cfav1.createFlow, (superToken, address(this), flowRate, new bytes(0)));
        ISuperfluid.Operation[] memory ops = new ISuperfluid.Operation[](1);
        ops[0] = ISuperfluid.Operation(
            BatchOperation.OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT, // type
            address(cfav1), // target
            abi.encode( // data
            operationCallData, new bytes(0))
        );

        // craft forward batch call calldata
        bytes memory fwBatchCallData = abi.encodeCall(host.forwardBatchCall, (ops));
        
        // craft multicall calldata, pack the flow sender here
        bytes memory multicallCallData = abi.encodePacked(fwBatchCallData, sender);
        
        // craft multicall calls array for aggregate function
        SuperfluidMulticallForwarder.Call[] memory calls = new SuperfluidMulticallForwarder.Call[](1);
        calls[0] = SuperfluidMulticallForwarder.Call(address(host), multicallCallData);

        // execute multicall aggregate function
        multicallForwarder.aggregate(calls);

        // check if flow was created
        (, int96 fr, ,) = cfav1.getFlow(superToken, sender, address(this));
        assertEq(fr, flowRate);
    }
}
