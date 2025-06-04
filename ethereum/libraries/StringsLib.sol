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

import "@openzeppelin/contracts/utils/Strings.sol";

library StringsLib {
    using Strings for uint256;

    function toDecimalString(uint256 value, uint8 decimals) internal pure returns (string memory) {
        string memory integerPart = (value / 10 ** decimals).toString();
        string memory decimalPart = (value % 10 ** decimals).toString();

        // Remove trailing zeros from the decimal part
        uint256 trailingZeros;
        for (uint256 i = bytes(decimalPart).length; i > 0; i--) {
            if (bytes(decimalPart)[i - 1] != "0") {
                break;
            }
            trailingZeros++;
        }

        // If all decimal digits are zeros, return only the integer part
        if (trailingZeros == bytes(decimalPart).length) {
            return integerPart;
        }

        // Trim the trailing zeros
        bytes memory trimmedDecimalPart = new bytes(bytes(decimalPart).length - trailingZeros);
        for (uint256 i = 0; i < trimmedDecimalPart.length; i++) {
            trimmedDecimalPart[i] = bytes(decimalPart)[i];
        }

        // Combine the integer and decimal parts with a dot
        return string(abi.encodePacked(integerPart, ".", trimmedDecimalPart));
    }
}
