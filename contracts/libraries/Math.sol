// SPDX-License-Identifier: MIT
/*
 * Rasta Math Smart Contract Library.  Copyright © 2021 by RastaFinance
 */
pragma solidity ^0.6.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";


library RastaMath {
  using SafeMath for uint256;
  using Math for uint;

  /**
   * Calculate exponential of base 10
   *
   * @param x unsigned 256 bit integer
   * @param decimals unsigned 256 bit integer as logarithmic power
   * @return unsigned 256 bit integer
   */
  function exp10 (uint256 x, uint8 decimals) internal pure returns (uint256) {
      return x.mul(uint256(10) ** uint256(decimals)); // 10**255 is the max value... this should be less than max value for uint256
  }
  /**
   * Calculate the Average while rounding up
   *
   * @param x unsigned integer
   * @param y unsigned integer
   * @return unsigned integer
   */
  function averageUp (uint x, uint y ) internal pure returns (uint){

    uint256 average = x.average(y);
    if(average.mul(2) != x.add(y)){ // average rounded down to zero so round up
      return average.add(1);
    }
    return average;
  }
}