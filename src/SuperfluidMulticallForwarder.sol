// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Multicall3} from "multicall/Multicall3.sol";

contract SuperfluidMulticallForwarder {
    address public constant MULTICALL_3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    error DELEGATE_CALL_FAILED();

    /// @notice Backwards-compatible call aggregation with Multicall
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return returnData An array of bytes containing the responses
    function aggregate(Call[] calldata calls) public payable returns (uint256 blockNumber, bytes[] memory returnData) {
        (bool success, bytes memory data) =
            MULTICALL_3_ADDRESS.delegatecall(abi.encodeWithSelector(Multicall3.aggregate.selector, calls));
        if (!success) revert DELEGATE_CALL_FAILED();

        (blockNumber, returnData) = abi.decode(data, (uint256, bytes[]));
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls without requiring success
    /// @param requireSuccess If true, require all calls to succeed
    /// @param calls An array of Call structs
    /// @return returnData An array of Result structs
    function tryAggregate(bool requireSuccess, Call[] calldata calls)
        public
        payable
        returns (Result[] memory returnData)
    {
        (bool success, bytes memory data) = MULTICALL_3_ADDRESS.delegatecall(
            abi.encodeWithSelector(Multicall3.tryAggregate.selector, requireSuccess, calls)
        );
        if (!success) revert DELEGATE_CALL_FAILED();

        (returnData) = abi.decode(data, (Result[]));
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls and allow failures using tryAggregate
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls)
        public
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData)
    {
        (bool success, bytes memory data) = MULTICALL_3_ADDRESS.delegatecall(
            abi.encodeWithSelector(Multicall3.tryBlockAndAggregate.selector, requireSuccess, calls)
        );
        if (!success) revert DELEGATE_CALL_FAILED();

        (blockNumber, blockHash, returnData) = abi.decode(data, (uint256, bytes32, Result[]));
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls and allow failures using tryAggregate
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function blockAndAggregate(Call[] calldata calls)
        public
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData)
    {
        (bool success, bytes memory data) = MULTICALL_3_ADDRESS.delegatecall(
            abi.encodeWithSelector(Multicall3.blockAndAggregate.selector, calls)
        );
        if (!success) revert DELEGATE_CALL_FAILED();

        (blockNumber, blockHash, returnData) = abi.decode(data, (uint256, bytes32, Result[]));
    }

    /// @notice Aggregate calls, ensuring each returns success if required
    /// @param calls An array of Call3 structs
    /// @return returnData An array of Result structs
    function aggregate3(Call3[] calldata calls) public payable returns (Result[] memory returnData) {
        (bool success, bytes memory data) = MULTICALL_3_ADDRESS.delegatecall(
            abi.encodeWithSelector(Multicall3.aggregate3.selector, calls)
        );
        if (!success) revert DELEGATE_CALL_FAILED();

        (returnData) = abi.decode(data, (Result[]));
    }

    /// @notice Aggregate calls with a msg value
    /// @notice Reverts if msg.value is less than the sum of the call values
    /// @param calls An array of Call3Value structs
    /// @return returnData An array of Result structs
    function aggregate3Value(Call3Value[] calldata calls) public payable returns (Result[] memory returnData) {
        (bool success, bytes memory data) = MULTICALL_3_ADDRESS.delegatecall(
            abi.encodeWithSelector(Multicall3.aggregate3Value.selector, calls)
        );
        if (!success) revert DELEGATE_CALL_FAILED();

        (returnData) = abi.decode(data, (Result[]));
    }

    /// @notice Returns the block hash for the given block number
    /// @param blockNumber The block number
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @notice Returns the block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @notice Returns the block coinbase
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @notice Returns the block difficulty
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    /// @notice Returns the block gas limit
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /// @notice Returns the block timestamp
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /// @notice Returns the (ETH) balance of a given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Returns the block hash of the last block
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }

    /// @notice Gets the base fee of the given block
    /// @notice Can revert if the BASEFEE opcode is not implemented by the given chain
    function getBasefee() public view returns (uint256 basefee) {
        basefee = block.basefee;
    }

    /// @notice Returns the chain id
    function getChainId() public view returns (uint256 chainid) {
        chainid = block.chainid;
    }
}
