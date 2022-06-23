// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../libraries/Callib.sol";
import "../libraries/ArgumentsDecoder.sol";
import "./NonceManager.sol";

/// @title A helper contract for executing boolean functions on arbitrary target call results
contract PredicateHelper is NonceManager {
    using Callib for address;
    using ArgumentsDecoder for bytes;

    error ArbitraryStaticCallFailed();

    /// @notice Calls every target with corresponding data
    /// @return Result True if call to any target returned True. Otherwise, false
    function or(uint256 offsets, bytes calldata data) public view returns(bool) {
        uint256 current;
        uint256 previous;
        for (uint256 i = 0; (current = uint32(offsets >> (i << 5))) != 0; i++) {
            (bool success, uint256 res) = _selfStaticCall(data[previous:current]);
            if (success && res == 1) {
                return true;
            }
            previous = current;
        }
        return false;
    }

    /// @notice Calls every target with corresponding data
    /// @return Result True if calls to all targets returned True. Otherwise, false
    function and(uint256 offsets, bytes calldata data) public view returns(bool) {
        uint256 current;
        uint256 previous;
        for (uint256 i = 0; (current = uint32(offsets >> (i << 5))) != 0; i++) {
            (bool success, uint256 res) = _selfStaticCall(data[previous:current]);
            if (!success || res != 1) {
                return false;
            }
            previous = current;
        }
        return true;
    }

    /// @notice Calls target with specified data and tests if it's equal to the value
    /// @param value Value to test
    /// @return Result True if call to target returns the same value as `value`. Otherwise, false
    function eq(uint256 value, bytes calldata data) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(data);
        return success && res == value;
    }

    /// @notice Calls target with specified data and tests if it's lower than value
    /// @param value Value to test
    /// @return Result True if call to target returns value which is lower than `value`. Otherwise, false
    function lt(uint256 value, bytes calldata data) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(data);
        return success && res < value;
    }

    /// @notice Calls target with specified data and tests if it's bigger than value
    /// @param value Value to test
    /// @return Result True if call to target returns value which is bigger than `value`. Otherwise, false
    function gt(uint256 value, bytes calldata data) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(data);
        return success && res > value;
    }

    /// @notice Checks passed time against block timestamp
    /// @return Result True if current block timestamp is lower than `time`. Otherwise, false
    function timestampBelow(uint256 time) public view returns(bool) {
        return block.timestamp < time;  // solhint-disable-line not-rely-on-time
    }

    /// @notice Performs an arbitrary call to target with data
    /// @return Result Bytes transmuted to uint256
    function arbitraryStaticCall(address target, bytes calldata data) public view returns(uint256) {
        (bool success, uint256 res) = target.staticcallForUint(data);
        if (!success) revert ArbitraryStaticCallFailed();
        return res;
    }

    function _selfStaticCall(bytes calldata data) internal view returns(bool, uint256) {
        bytes4 selector = data.decodeSelector();
        uint256 arg = data.decodeUint256(4);
        bytes calldata param;
        uint256 index;
        assembly {  // solhint-disable-line no-inline-assembly
            param.offset := add(data.offset, 100)
            param.length := sub(data.length, 100)
            index := mod(mod(xor(shr(224, selector), 117243), 1337), 5)
        }

        if (selector == [this.or, this.and, this.eq, this.lt, this.gt][index].selector) {
            return (true, [or, and, eq, lt, gt][index](arg, param) ? 1 : 0);
        }
        // if (selector == this.or.selector) {
        //     return (true, or(arg, param) ? 1 : 0);
        // }
        // if (selector == this.and.selector) {
        //     return (true, and(arg, param) ? 1 : 0);
        // }
        // if (selector == this.eq.selector) {
        //     return (true, eq(arg, param) ? 1 : 0);
        // }
        // if (selector == this.lt.selector) {
        //     return (true, lt(arg, param) ? 1 : 0);
        // }
        // if (selector == this.gt.selector) {
        //     return (true, gt(arg, param) ? 1 : 0);
        // }

        // Other functions
        if (selector == this.timestampBelow.selector) {
            return (true, timestampBelow(arg) ? 1 : 0);
        }
        if (selector == this.nonceEquals.selector) {
            uint256 arg2 = data.decodeUint256(0x24);
            return (true, nonceEquals(address(uint160(arg)), arg2) ? 1 : 0);
        }
        if (selector == this.arbitraryStaticCall.selector) {
            return (true, arbitraryStaticCall(address(uint160(arg)), param));
        }

        return address(this).staticcallForUint(data);
    }
}
