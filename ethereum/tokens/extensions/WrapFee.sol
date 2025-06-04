/**
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract WrapFee is Initializable {
    /// @custom:storage-location erc7201:cashiva.storage.WrapFee
    struct WrapFeeStorage {
        uint256 _feeRate;
        uint256 _minFee;
        uint256 _maxFee;
    }

    event WrapFeeParamsChanged(uint256 feeRate, uint256 minFee, uint256 maxFee);

    error WrapFeeRateInvalid();

    uint256 private constant FEE_PARTS = 1_000_000;

    // solhint-disable-next-line func-name-mixedcase
    function __WrapFee_init() internal onlyInitializing {
        __WrapFee_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __WrapFee_init_unchained() internal onlyInitializing {}

    // keccak256(abi.encode(uint256(keccak256("cashiva.storage.WrapFee")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_LOCATION = 0x5ba8fec81c4568d6510da99701e4a666cb633bcfb82751a5e786b4a56ab6d200;

    function _getWrapFeeStorage() private pure returns (WrapFeeStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := STORAGE_LOCATION
        }
    }

    function wrapFeeParts() public view virtual returns (uint256) {
        return FEE_PARTS;
    }

    function wrapFeeRate() public view returns (uint256) {
        WrapFeeStorage storage $ = _getWrapFeeStorage();
        return $._feeRate;
    }

    function wrapFeeMin() public view virtual returns (uint256) {
        WrapFeeStorage storage $ = _getWrapFeeStorage();
        return $._minFee;
    }

    function wrapFeeMax() public view virtual returns (uint256) {
        WrapFeeStorage storage $ = _getWrapFeeStorage();
        return $._maxFee;
    }

    function _setWrapFeeParams(uint256 feeRate_, uint256 minFee_, uint256 maxFee_) internal virtual {
        if (feeRate_ > FEE_PARTS) {
            revert WrapFeeRateInvalid();
        }
        WrapFeeStorage storage $ = _getWrapFeeStorage();
        $._feeRate = feeRate_;
        $._minFee = minFee_;
        $._maxFee = maxFee_;
        emit WrapFeeParamsChanged($._feeRate, $._minFee, $._maxFee);
    }

    function _calcWrapFee(uint256 amount) internal view returns (uint256) {
        WrapFeeStorage storage $ = _getWrapFeeStorage();
        uint256 rate = $._feeRate;
        if (rate > 0) {
            uint256 fee = (amount * rate) / FEE_PARTS;
            if (fee < $._minFee) {
                fee = $._minFee;
            } else if (fee > $._maxFee) {
                fee = $._maxFee;
            }
            if (fee > amount) {
                fee = amount;
            }
            return fee;
        }
        return 0;
    }
}
