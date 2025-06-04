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

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {CashivaStandardToken} from "./CashivaStandardToken.sol";
import {NativeWrappable} from "../extensions/NativeWrappable.sol";
import {IPyth} from "../../oracles/pyth/IPyth.sol";


abstract contract CashivaNativeWrappedToken is CashivaStandardToken, NativeWrappable {
    function __CashivaNativeWrappedToken_init(
        string memory name_,
        string memory symbol_,
        IPyth oracle_,
        bytes32 priceFeedId_,
        string memory currencySymbol_,
        uint256 validTimePeriod_
    ) internal onlyInitializing {
        __CashivaStandardToken_init(
            name_,
            symbol_,
            oracle_,
            priceFeedId_,
            currencySymbol_,
            validTimePeriod_
        );
        __NativeWrappable_init();
        __CashivaNativeWrappedToken_init_unchained();
    }

    function __CashivaNativeWrappedToken_init_unchained() internal onlyInitializing {}

    receive() external payable  {
        wrap();
    }

    function transfer(
        address to,
        uint256 value
    ) public override(ERC20Upgradeable, NativeWrappable) returns (bool) {
        return super.transfer(to, value);
    }

    function setWrapFeeParams(uint256 feeRate_, uint256 minFee_, uint256 maxFee_) public onlyOwner {
        _setWrapFeeParams(feeRate_, minFee_, maxFee_);
    }

    function withdrawFee() public onlyOwner {
        _withdrawFee();
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20Upgradeable, CashivaStandardToken) {
        super._update(from, to, value);
    }
}
