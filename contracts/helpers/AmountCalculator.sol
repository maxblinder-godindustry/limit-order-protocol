// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
pragma abicoder v1;

import "@openzeppelin/contracts/utils/Address.sol";
import "../libraries/Callib.sol";

/// @title A helper contract for calculations related to order amounts
contract AmountCalculator {
    using Address for address;

    /// @notice Calculates maker amount
    /// @return Result Floored maker amount
    function getMakingAmount(uint256 orderMakerAmount, uint256 orderTakerAmount, uint256 swapTakerAmount) public pure returns(uint256) {
        return swapTakerAmount * orderMakerAmount / orderTakerAmount;
    }

    /// @notice Calculates taker amount
    /// @return Result Ceiled taker amount
    function getTakingAmount(uint256 orderMakerAmount, uint256 orderTakerAmount, uint256 swapMakerAmount) public pure returns(uint256) {
        return (swapMakerAmount * orderTakerAmount + orderMakerAmount - 1) / orderMakerAmount;
    }

    /// @notice Performs an arbitrary call to target with data
    /// @return Result Bytes transmuted to uint256
    function arbitraryStaticCall(address target, bytes calldata data) external view returns(uint256) {
        (bool success, uint256 res) = Callib.callReturningUint(target, data);
        require(success, "AC: arbitraryStaticCall");
        return res;
    }
}
