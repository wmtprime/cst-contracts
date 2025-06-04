/*
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
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {DateTimeLib} from "../../libraries/DateTimeLib.sol";
import {StringsLib} from "../../libraries/StringsLib.sol";
import {IPyth} from "../../oracles/pyth/IPyth.sol";
import {PythStructs} from "../../oracles/pyth/PythStructs.sol";

abstract contract TransferPriceEmitter is Initializable, ERC20Upgradeable {
    using DateTimeLib for uint256;
    using StringsLib for uint256;

    event TransferPrice(bytes32 indexed id, uint64 publishTime, int64 rate, int32 expo, string price);

    /// @custom:storage-location erc7201:cashiva.storage.TransferPriceEmitter
    struct EmitterStorage {
        IPyth _oracle;
        bytes32 _priceFeedId;
        string _currencySymbol;
        uint256 _validTimePeriod; // in seconds
    }

    // solhint-disable-next-line func-name-mixedcase
    function __TransferPriceEmitter_init(
        IPyth oracle_,
        bytes32 priceFeedId_,
        string memory currencySymbol_,
        uint256 validTimePeriod_
    ) internal onlyInitializing {
        __TransferPriceEmitter_init_unchained(
            oracle_,
            priceFeedId_,
            currencySymbol_,
            validTimePeriod_
        );
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __TransferPriceEmitter_init_unchained(
        IPyth oracle_,
        bytes32 priceFeedId_,
        string memory currencySymbol_,
        uint256 validTimePeriod_
    ) internal onlyInitializing {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        $._oracle = oracle_;
        $._priceFeedId = priceFeedId_;
        $._currencySymbol = currencySymbol_;
        $._validTimePeriod = validTimePeriod_;
    }

    // keccak256(abi.encode(uint256(keccak256("cashiva.storage.TransferPriceEmitter")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_LOCATION = 0xf116ee31fa11d5f3e9f2ed675718b59844fe1729415bbc6ccfe55c1ab01e2c00;

    function _getEmitterStorageStorage() private pure returns (EmitterStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := STORAGE_LOCATION
        }
    }

    function oracle() public view returns (IPyth) {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        return $._oracle;
    }

    function priceFeedId() public view returns(bytes32) {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        return $._priceFeedId;
    }

    function validTimePeriod() public view returns(uint256) {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        return $._validTimePeriod;
    }

    function _setOracle(IPyth oracle_) internal {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        $._oracle = oracle_;
    }

    function _setValidTimePeriod(uint256 newValidTimePeriod) internal {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        $._validTimePeriod = newValidTimePeriod;
    }

    function _transferWithUpdatePrice(address to, uint256 value, bytes[] calldata updateData, uint256 updateFee) internal returns (bool) {
        oracle().updatePriceFeeds{ value: updateFee }( updateData);
        return super.transfer(to, value);
    }

    function _transferFromWithUpdatePrice(address from, address to, uint256 value, bytes[] calldata updateData, uint256 updateFee) internal returns (bool) {
        oracle().updatePriceFeeds{ value: updateFee }(updateData);
        return super.transferFrom(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        if (to != address(0)) {
            EmitterStorage storage $ = _getEmitterStorageStorage();
            if ($._validTimePeriod > 0) {
                _emitNoLongerThan(value, $._validTimePeriod);
            } else {
                _emitUnsafe(value);
            }
        }
    }

    function _emitUnsafe(uint256 value) internal virtual {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        PythStructs.Price memory priceData = $._oracle.getPriceUnsafe($._priceFeedId);
        _emitTransferPrice(value, priceData);
    }

    function _emitNoLongerThan(uint256 value, uint256 age) internal virtual {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        PythStructs.Price memory priceData = $._oracle.getPriceNoOlderThan($._priceFeedId, age);
        _emitTransferPrice(value, priceData);
    }

    function _emitTransferPrice(uint256 value, PythStructs.Price memory data) internal virtual {
        EmitterStorage storage $ = _getEmitterStorageStorage();
        uint8 priceDecimals = decimals() + uint8(uint32(-1 * data.expo));
        uint price = uint256(uint64(data.price)) * value;

        emit TransferPrice(
            $._priceFeedId,
            uint64(data.publishTime),
            data.price,
            data.expo,
            string(abi.encodePacked(
                price.toDecimalString(priceDecimals),
                " ",
                $._currencySymbol,
                " at ",
                data.publishTime.toDateTimeString(),
                " UTC"
            ))
        );
    }
}
