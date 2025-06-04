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

library DateTimeLib {
    using Strings for uint256;

    // Constants for time units
    uint256 private constant SECONDS_PER_MINUTE = 60;
    uint256 private constant SECONDS_PER_HOUR = 3600;
    uint256 private constant SECONDS_PER_DAY = 86400;
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    uint256 private constant SECONDS_PER_LEAP_YEAR = 31622400;
    uint256 private constant SECONDS_PER_4_YEARS = 126230400;

    // Struct to hold date and time components
    struct DateTime {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
    }

    /**
     * @dev Converts a Unix timestamp to a DateTimeStruct.
     * @param timestamp The Unix timestamp to convert.
     * @return A DateTime containing the date and time components.
     */
    function toDateTime(uint256 timestamp) internal pure returns (DateTime memory) {
        // Epoch is 1970-01-01 00:00:00
        uint256 _seconds = timestamp;
        uint256 _minutes = _seconds / SECONDS_PER_MINUTE;
        uint256 _hours = _minutes / 60;
        uint256 _days = _hours / 24;

        // Calculate seconds, minutes, and hours
        uint256 second = _seconds % SECONDS_PER_MINUTE;
        uint256 minute = (_minutes % 60);
        uint256 hour = _hours % 24;

        // Calculate the year
        uint256 year = 1970;
        uint256 daysRemaining = _days;

        while (true) {
            uint256 daysInYear = isLeapYear(year) ? 366 : 365;
            if (daysRemaining >= daysInYear) {
                year += 1;
                daysRemaining -= daysInYear;
            } else {
                break;
            }
        }

        // Calculate the month
        uint256 month = 1;
        uint256 monthDays;
        while (true) {
            monthDays = daysInMonth(year, month);
            if (daysRemaining >= monthDays) {
                month += 1;
                daysRemaining -= monthDays;
            } else {
                break;
            }
        }

        // The remaining days are the day of the month
        uint256 day = daysRemaining + 1;

        return DateTime(year, month, day, hour, minute, second);
    }

    /**
     * @dev Formats a timestamp into a string with format yyyy-mm-dd hh:mm:ss.
     * @param timestamp The Unix timestamp to convert.
     * @return A string representing the formatted date and time.
     */
    function toDateTimeString(uint256 timestamp) internal pure returns (string memory) {
        DateTime memory dateTime = toDateTime(timestamp);

        return string(
            abi.encodePacked(
                dateTime.year.toString(), "-",
                padZero(dateTime.month.toString(), 2), "-",
                padZero(dateTime.day.toString(), 2), " ",
                padZero(dateTime.hour.toString(), 2), ":",
                padZero(dateTime.minute.toString(), 2), ":",
                padZero(dateTime.second.toString(), 2)
            )
        );
    }

    /**
     * @dev Determines if a given year is a leap year.
     * @param year The year to check.
     * @return True if the year is a leap year, false otherwise.
     */
    function isLeapYear(uint256 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        } else if (year % 100 != 0) {
            return true;
        } else if (year % 400 != 0) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of days in a specific month and year.
     * @param year The year.
     * @param month The month (1 = January, ..., 12 = December).
     * @return The number of days in the month.
     */
    function daysInMonth(uint256 year, uint256 month) internal pure returns (uint256) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        } else {
            // Invalid month
            return 0;
        }
    }

    /**
     * @dev Pads a string with leading zeros to a specified length.
     * @param value The string to pad.
     * @param length The desired length of the string.
     * @return The padded string.
     */
    function padZero(string memory value, uint256 length) internal pure returns (string memory) {
        if (bytes(value).length >= length) {
            return value;
        }
        bytes memory buffer = new bytes(length);
        uint256 start = length - bytes(value).length;
        for (uint256 i = 0; i < start; i++) {
            buffer[i] = "0";
        }
        for (uint256 i = start; i < length; i++) {
            buffer[i] = bytes(value)[i - start];
        }
        return string(buffer);
    }
}
