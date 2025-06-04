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

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {TransferPriceEmitter} from "../extensions/TransferPriceEmitter.sol";
import {IPyth} from "../../oracles/pyth/IPyth.sol";

abstract contract CashivaStandardToken is ERC20Upgradeable, TransferPriceEmitter, OwnableUpgradeable, ERC20PermitUpgradeable {
    // solhint-disable-next-line func-name-mixedcase
    function __CashivaStandardToken_init(
        string memory name_,
        string memory symbol_,
        IPyth oracle_,
        bytes32 priceFeedId_,
        string memory currencySymbol_,
        uint256 validTimePeriod_
    ) internal onlyInitializing {
        __ERC20_init(name_, symbol_);
        __TransferPriceEmitter_init(
            oracle_,
            priceFeedId_,
            currencySymbol_,
            validTimePeriod_
        );
        __Ownable_init(_msgSender());
        __ERC20Permit_init(name());

        __CashivaStandardToken_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __CashivaStandardToken_init_unchained() internal onlyInitializing {}

    function transferWithUpdatePrice(address to, uint256 value, bytes[] calldata updateData) public payable returns (bool) {
        return _transferWithUpdatePrice(to, value, updateData, msg.value);
    }

    function transferFromWithUpdatePrice(address from, address to, uint256 value, bytes[] calldata updateData) public payable returns (bool) {
        return _transferFromWithUpdatePrice(from, to, value, updateData, msg.value);
    }

    function setOracle(IPyth newOracle) public onlyOwner {
        _setOracle(newOracle);
    }

    function setValidTimePeriod(uint256 newValidTimePeriod) public onlyOwner {
        _setValidTimePeriod(newValidTimePeriod);
    }

    function _update(
        address from,
        address to,
        uint256 value) internal virtual override(ERC20Upgradeable, TransferPriceEmitter) {
        super._update(from, to, value);
    }
}
