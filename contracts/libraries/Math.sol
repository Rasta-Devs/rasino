// SPDX-License-Identifier: MIT
/*
 * Kudi Math Smart Contract Library.  Copyright © 2021 by Nemcrunchers
 * Author: Andrew Schmidt <andrew@nemcrunchers.dev>
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


library RastaMath {
  using SafeMath for uint256;

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (uint256 x) internal pure returns (uint256) {
    uint256 n = 0;

    if (x > 2**255) { x >>= 256; n += 256; }
    if (x >= 2**128) { x >>= 128; n += 128; }
    if (x >= 2**64) { x >>= 64; n += 64; }
    if (x >= 2**32) { x >>= 32; n += 32; }
    if (x >= 2**16) { x >>= 16; n += 16; }
    if (x >= 2**8) { x >>= 8; n += 8; }
    if (x >= 2**4) { x >>= 4; n += 4; }
    if (x >= 2**2) { x >>= 2; n += 2; }
    if (x >= 2**1) { /* x >>= 1; */ n += 1; }

    return n;
  }

}