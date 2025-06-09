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
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {CashivaStandardToken} from "./CashivaStandardToken.sol";
import {TransferPriceEmitter} from "../extensions/TransferPriceEmitter.sol";
import {Mintable} from "../extensions/Mintable.sol";
import {Freezable} from "../extensions/Freezable.sol";
import {IPyth} from "../../oracles/pyth/IPyth.sol";

abstract contract CashivaMintableToken is
    CashivaStandardToken,
    Mintable,
    PausableUpgradeable,
    Freezable
{
    struct CashivaMintableTokenStorage {
        uint8 _decimals;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __CashivaMintableToken_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
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
        __Mintable_init();
        __Pausable_init();
        __Freezable_init();
        __CashivaMintableToken_init_unchained(decimals_);
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __CashivaMintableToken_init_unchained(
        uint8 decimals_
    ) internal onlyInitializing {
        CashivaMintableTokenStorage storage $ = _getCashivaMintableTokenStorage();
        $._decimals = decimals_;
    }

    // keccak256(abi.encode(uint256(keccak256("cashiva.storage.CashivaMintableToken")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CASHIVA_MINTABLE_TOKEN_STORAGE_LOCATION = 0x9b9e7ab05886f036ccbbe5f70f770ff36db154b0409040f4610d6927942ad500;

    function _getCashivaMintableTokenStorage() private pure returns (CashivaMintableTokenStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := CASHIVA_MINTABLE_TOKEN_STORAGE_LOCATION
        }
    }

    function decimals() public view virtual override returns (uint8) {
        CashivaMintableTokenStorage storage $ = _getCashivaMintableTokenStorage();
        return $._decimals;
    }

    function transfer(
        address to,
        uint256 value
    ) public override notFrozen(_msgSender()) notFrozen(to) returns (bool) {
        return super.transfer(to, value);
    }

    function approve(
        address spender,
        uint256 value
    ) public override notFrozen(_msgSender()) whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override notFrozen(_msgSender()) notFrozen(from) notFrozen(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function setWrapFeeParams(uint256 feeRate_, uint256 minFee_, uint256 maxFee_) public onlyOwner {
        _setWrapFeeParams(feeRate_, minFee_, maxFee_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function freeze(address account) external onlyOwner {
        _freeze(account);
    }

    function unfreeze(address account) external onlyOwner {
        _unfreeze(account);
    }

    function burnFrozenFunds(address account) external onlyOwner onlyFrozen(account) {
        uint256 balance = balanceOf(account);
        _burn(account, balance);
        emit FrozenFundsBurned(account, balance);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20Upgradeable, CashivaStandardToken) whenNotPaused {
        super._update(from, to, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual override notFrozen(owner) notFrozen(spender) whenNotPaused {
        super._approve(owner, spender, value, emitEvent);
    }
}
