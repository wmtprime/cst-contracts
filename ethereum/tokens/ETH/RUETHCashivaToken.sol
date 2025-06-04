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

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {CashivaNativeWrappedToken} from "../cashiva/CashivaNativeWrappedToken.sol";
import {IPyth} from "../../oracles/pyth/IPyth.sol";

contract RUETHCashivaToken is CashivaNativeWrappedToken, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IPyth oracle_,
        bytes32 priceFeedId_,
        uint256 validTimePeriod_
    ) public initializer {
        __CashivaNativeWrappedToken_init(
            "Russian Ruble Wrapped Ethereum",
            "RUETH",
            oracle_,
            priceFeedId_,
            "RUB",
            validTimePeriod_
        );
        __UUPSUpgradeable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}
