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
pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {WrapFee} from "./WrapFee.sol";

abstract contract NativeWrappable is Initializable, ERC20Upgradeable, WrapFee {
    event Wrap(address indexed recipient, uint256 amount);
    event Unwrap(address indexed recipient, uint256 amount);

    error WrapAmountInvalid();

    // solhint-disable-next-line func-name-mixedcase
    function __NativeWrappable_init() internal onlyInitializing {
        __WrapFee_init();
        __NativeWrappable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __NativeWrappable_init_unchained() internal onlyInitializing {}

    function wrap() public payable {
        require(msg.value > 0);
        _wrap(_msgSender(), msg.value);
    }

    function transfer(address to, uint256 value) public override virtual returns (bool) {
        bool res = super.transfer(to, value);
        if (res && to == address(this)) {
            _unwrap(_msgSender(), value);
        }
        return res;
    }

    function withdrawableFee() public view virtual returns (uint) {
        return address(this).balance - totalSupply();
    }

    function _withdrawFee() internal virtual {
        payable(_msgSender()).transfer(withdrawableFee());
    }

    function _wrap(address recipient, uint256 value) internal virtual {
        uint256 fee = _calcWrapFee(value);
        uint256 amount = value - fee;
        emit Wrap(recipient, amount);
        _mint(recipient, amount);
    }

    function _unwrap(address recipient, uint256 value) internal virtual {
        uint256 fee = _calcWrapFee(value);
        uint256 amount = value - fee;
        payable(recipient).transfer(amount);
        emit Unwrap(recipient, value);
        _burn(address(this), value);
    }
}