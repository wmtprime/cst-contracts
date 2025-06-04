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
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {WrapFee} from "./WrapFee.sol";

abstract contract Mintable is Initializable, AccessControlUpgradeable, ERC20Upgradeable, WrapFee {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER');

    event DepositCreated(
        address indexed account,
        uint256 depositId,
        string txId,
        string recipient,
        uint256 amount,
        uint256 fee
    );

    event WithdrawalRequestCreated(
        address indexed account,
        uint256 withdrawalId,
        string recipient,
        uint256 amount,
        uint256 fee
    );

    event WithdrawalCancelled(address indexed account, uint256 withdrawalId, string recipient, uint256 amount);
    event WithdrawalCompleted(address indexed account, string txId, string recipient, uint256 amount, uint256 fee);
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    error DepositAlreadySettled();
    error WithdrawalRequestInWrongState();

    enum DepositStatus {
        Unknown,
        Settled
    }

    enum WithdrawRequestStatus {
        Unknown,
        Pending,
        Cancelled,
        Completed
    }

    struct Deposit {
        DepositStatus status;
        string txId;
        string recipient;
        uint256 amount;
        uint256 fee;
    }

    struct WithdrawRequest {
        WithdrawRequestStatus status;
        address account;
        string recipient;
        uint256 amount;
    }

    struct MintableStorage {
        mapping (uint256 => Deposit) _deposits;
        mapping (uint256 => WithdrawRequest) _withdrawRequests;
        uint256 _requestId;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Mintable_init() internal onlyInitializing {
        __AccessControl_init();
        __WrapFee_init();
        __Mintable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __Mintable_init_unchained() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
    }

    // keccak256(abi.encode(uint256(keccak256("cashiva.storage.Mintable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_LOCATION = 0xddb9e61613b3299de1a8214e91c696a267968494eb8f384023aadbd92496b700;

    function _getMintableStorage() private pure returns (MintableStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := STORAGE_LOCATION
        }
    }

    function deposit(
        address account,
        uint256 depositId,
        uint256 amount,
        string memory txId,
        string memory recipient
    ) public virtual onlyRole(MINTER_ROLE) {
        MintableStorage storage $ = _getMintableStorage();
        Deposit storage d = $._deposits[depositId];
        if (d.status == DepositStatus.Settled) {
            revert DepositAlreadySettled();
        }
        uint256 fee = _calcWrapFee(amount);
        uint256 value = amount - fee;

        d.status = DepositStatus.Settled;
        d.txId = txId;
        d.recipient = recipient;
        d.amount = amount;
        d.fee = fee;

        _mint(account, value);
        emit DepositCreated(account, depositId, txId, recipient, amount, fee);
        emit Mint(account, value);
    }

    function getDeposit(uint256 depositId) public view returns (Deposit memory) {
        MintableStorage storage $ = _getMintableStorage();
        return $._deposits[depositId];
    }

    function requestWithdrawal(
        string memory recipient,
        uint256 amount
    ) public virtual returns (WithdrawRequest memory) {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");

        MintableStorage storage $ = _getMintableStorage();
        $._withdrawRequests[$._requestId].status = WithdrawRequestStatus.Pending;
        $._withdrawRequests[$._requestId].account = _msgSender();
        $._withdrawRequests[$._requestId].recipient = recipient;
        $._withdrawRequests[$._requestId].amount = amount;

        _transfer(_msgSender(), address(this), amount);

        uint256 fee = _calcWrapFee(amount);
        emit WithdrawalRequestCreated(
            _msgSender(),
            $._requestId,
            recipient,
            amount,
            fee
        );
        return $._withdrawRequests[$._requestId++];
    }

    function getWithdrawal(uint256 withdrawalId) public view returns (WithdrawRequest memory) {
        MintableStorage storage $ = _getMintableStorage();
        return $._withdrawRequests[withdrawalId];
    }

    function cancelWithdrawal(uint256 withdrawalId) public virtual onlyRole(BURNER_ROLE) {
        MintableStorage storage $ = _getMintableStorage();
        if ($._withdrawRequests[withdrawalId].status != WithdrawRequestStatus.Pending) {
            revert WithdrawalRequestInWrongState();
        }
        _transfer(
            address(this),
            $._withdrawRequests[withdrawalId].account,
            $._withdrawRequests[withdrawalId].amount
        );

        $._withdrawRequests[withdrawalId].status = WithdrawRequestStatus.Cancelled;
        emit WithdrawalCancelled(
            $._withdrawRequests[withdrawalId].account,
            withdrawalId,
            $._withdrawRequests[withdrawalId].recipient,
            $._withdrawRequests[withdrawalId].amount
        );
    }

    function completeWithdrawal(uint256 withdrawalId, string memory txId) public virtual onlyRole(BURNER_ROLE) {
        MintableStorage storage $ = _getMintableStorage();
        if ($._withdrawRequests[withdrawalId].status != WithdrawRequestStatus.Pending) {
            revert WithdrawalRequestInWrongState();
        }
        uint256 fee = _calcWrapFee($._withdrawRequests[withdrawalId].amount);
        $._withdrawRequests[withdrawalId].status = WithdrawRequestStatus.Completed;
        _burn(address(this), $._withdrawRequests[withdrawalId].amount);
        emit WithdrawalCompleted(
            $._withdrawRequests[withdrawalId].account,
            txId,
            $._withdrawRequests[withdrawalId].recipient,
            $._withdrawRequests[withdrawalId].amount,
            fee
        );
        emit Burn(address(this), $._withdrawRequests[withdrawalId].amount);
    }
}
