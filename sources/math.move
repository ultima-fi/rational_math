module Ultima::UltimaRationalMath {
use Ultima::u256;
  use std::error;
  #[test_only]
  use std::debug;

  const MAX_U128: u128 = 340282366920938463463374607431768211455;

  const ERR_DIV_BY_ZERO: u64 = 0;
  const ERR_OUT_OF_RANGE: u64 = 1;
  const ERR_DIFFERENT_SCALE: u64 = 2;

  struct Decimal has drop, copy, store {
    value: u256::U256,
    scale: u8
  }

  //----------------------------------------------------------
  //                        Scales
  //----------------------------------------------------------
  const UNIFIED_SCALE: u8 = 9;

  //const FOO_SCALE: u8 = 6;
  //Scales can be added as needed for easy conversion

  //----------------------------------------------------------
  //                      Utilities
  //----------------------------------------------------------

  public fun new(v: u256::U256, s: u8): Decimal {
    Decimal {
      value: v,
      scale: s,
    }
  }

  public fun new_from_u64(v: u64, s: u8): Decimal {
    Decimal {
      value: u256::from_u64(v),
      scale: s,
    }
  }

  public fun new_from_u128(v: u128, s: u8): Decimal {
    Decimal {
      value: u256::from_u128(v),
      scale: s,
    }
  }

  public fun val(d: &Decimal): u256::U256 {
    d.value
  }

  public fun val_u64(d: &Decimal): u64 {
      u256::as_u64(d.value)
  }

  public fun val_u128(d: &Decimal): u128 {
      u256::as_u128(d.value)
  }
  
  public fun scale(d: &Decimal): u8 {
    d.scale
  }

  public fun is_zero(d: &Decimal): bool {
    u256::eq(&d.value, &u256::zero())
  }

  public fun adjust_scale(d: &mut Decimal, new_scale: u8) {
    assert!(new_scale > 0, error::invalid_argument(ERR_OUT_OF_RANGE));
    if (d.scale == new_scale) {
     return
    };
    if (d.scale > new_scale) {
    let power = pow(u256::from_u128(10u128), d.scale - new_scale);
      d.value = u256::div(d.value, power);
      d.scale = new_scale;
    }
    else {
    let power = pow(u256::from_u128(10u128), new_scale - d.scale);
      d.value = u256::mul(d.value, power);
      d.scale = new_scale;
    }
  }

  public fun denominator(d: &Decimal): u256::U256 {
    pow(u256::from_u128(10u128), d.scale)
  }

  //----------------------------------------------------------
  //                     Arithmetic
  //----------------------------------------------------------

  //adds two decimals of the same scale, returns none if overflow
  public fun add(d1: Decimal, d2: Decimal): Decimal {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    Decimal {
      value: u256::add(d1.value, d2.value),
      scale: d1.scale,
    }
  }

  //subs two decimals of the same scale, returns none if underflow
  public fun sub(larger: Decimal, smaller: Decimal): Decimal {
    assert!(larger.scale == smaller.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    Decimal {
      value: u256::sub(larger.value, smaller.value),
      scale: larger.scale,
    }
  }

  //multiplies two decimals, can handle different scales, can overflow
  public fun mul(d1: Decimal, d2: Decimal): Decimal {
    let smallerdenom = min_u256(denominator(&d1), denominator(&d2));

    // ((d1.value * d2.value) + (smallerdenom - 1)) / smallerdenom,
    let a = u256::mul(d1.value, d2.value);
    let b = u256::add(a, u256::sub(smallerdenom, u256::from_u128(1u128)));
    let c = u256::div(b, smallerdenom);

    Decimal {
      value: c,
      scale: max_u8(d1.scale, d2.scale),
    }
  }

  //divides two decimals with floor div, can handle different scales
  public fun div_floor(d1: Decimal, d2: Decimal): Decimal {
    assert!(!u256::eq(&d2.value, &u256::zero()), error::invalid_argument(ERR_DIV_BY_ZERO));
    let scale = max_u8(d1.scale, d2.scale);
    
    if (u256::eq(&d1.value, &u256::zero())) {
      return Decimal {
        value: u256::zero(),
        scale
      }
    };

    let smallerdenom = min_u256(denominator(&d1), denominator(&d2));

    Decimal {
      value: u256::div(u256::mul(d1.value, smallerdenom), d2.value),
      scale
    }
  }

  //divides two decimals with ceiling div
  public fun div_ceiling(d1: Decimal, d2: Decimal): Decimal {
    assert!(!u256::eq(&d2.value, &u256::zero()), error::invalid_argument(ERR_DIV_BY_ZERO));
    let scale = max_u8(d1.scale, d2.scale);
    
    if (u256::eq(&d1.value, &u256::zero())) {
      return Decimal {
        value: u256::zero(),
        scale
      }
    };

    let smallerdenom = min_u256(denominator(&d1), denominator(&d2));

    // ((d1.value * smallerdenom) + (d2.value - 1)) / d2.value,
    let a = u256::mul(d1.value, smallerdenom);
    let b = u256::add(a, u256::sub(d2.value, u256::from_u128(1u128)));
    let c = u256::div(b, d2.value);

    Decimal {
      value: c,
      scale
    }
  }

  //----------------------------------------------------------
  //                     Comparisons
  //----------------------------------------------------------
  public fun lt(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return u256::lt(&d1.value, &d2.value)
  }

  public fun gt(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return u256::gt(&d1.value, &d2.value)
  }

  public fun lte(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return u256::lte(&d1.value, &d2.value)
  }

  public fun gte(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return u256::gte(&d1.value, &d2.value)
  }

  public fun eq(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return u256::eq(&d1.value, &d2.value)
  }


  //---------------------------------------------------------- 
  //                       Internal
  //----------------------------------------------------------

  fun pow(base: u256::U256, exp: u8): u256::U256 {
    let count: u8 = 1;
    let val: u256::U256 = base;
    while (count < exp) {
      val = u256::mul(val, base);
      count = count + 1;
    };
    val
  }

  fun min_u256(first: u256::U256, second: u256::U256): u256::U256 {
    if (u256::lt(&first, &second)) {
      return first
    } else {
      return second
    }
  }

  fun max_u8(first: u8, second: u8): u8 {
    if (first > second) {
      return first
    } else {
      return second
    }
  }
  //----------------------------------------------------------
  //                    Sanity Tests
  //----------------------------------------------------------

//   #[test(account = @Ultima)]
//   public entry fun test_new_raw() {
//     let five = new(5, UNIFIED_SCALE);
//     assert!(five.value == 5 && five.scale == UNIFIED_SCALE, 0)
//   }

//   #[test(account = @Ultima)]
//   public entry fun test_denominator() {
//     let dec = Decimal {
//       value: 1800,
//       scale: 6
//     };
//     assert!(denominator(&dec) == 1000000,0)
//   }

  #[test(account = @Ultima)]
  public entry fun test_zero() {
    let zero = new(u256::zero(), UNIFIED_SCALE);
    assert!(is_zero(&zero), 0)
  }

  #[test(account = @Ultima)]
  public entry fun test_pow() {
    let x = pow(u256::from_u128(10u128), 6);
    assert!(u256::as_u64(x) == 1000000, 0);
    let y = pow(u256::from_u128(2u128), 10);
    assert!(u256::as_u64(y) == 1024, 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_scaling() {
    let dec = Decimal {
      value: u256::from_u64(1200),
      scale: 6
    };
    adjust_scale(&mut dec, 7);
    assert!(u256::as_u64(dec.value) == 12000 && dec.scale == 7, 0);
    adjust_scale(&mut dec, 5);
    assert!(u256::as_u64(dec.value) == 120 && dec.scale == 5, 0);
    adjust_scale(&mut dec, 5);
    assert!(u256::as_u64(dec.value) == 120 && dec.scale == 5, 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_add() {
    let dec1 = Decimal {
      value: u256::from_u64(1500),
      scale: 6
    };
    let dec2 = Decimal {
      value: u256::from_u64(1500),
      scale: 6
    };
    let result = add(dec1, dec2);
    assert!(u256::as_u64(result.value) == 3000 && result.scale == 6, 0);
  }

  // #[test(account = @Ultima)]
  // #[expected_failure]
  // public entry fun test_add_aborts_on_overflow() {
  //   let dec3 = Decimal {
  //     value: u256::from_u128(340282366920938463463374607431768211455),
  //     scale: 6
  //   };
  //   let dec4 = Decimal {
  //     value: u256::from_u64(1),
  //     scale: 6
  //   };
  //   add(dec3, dec4);
  // }

  #[test(account = @Ultima)]
  public entry fun test_sub() {
    let dec1 = Decimal {
      value: u256::from_u64(1300),
      scale: 6
    };
    let dec2 = Decimal {
      value: u256::from_u64(300),
      scale: 6
    };
    let result = sub(dec1, dec2);
    assert!(u256::as_u64(result.value) == 1000 && result.scale == 6, 0);
  }

   #[test(account = @Ultima)]
  #[expected_failure]
  public entry fun test_sub_aborts_on_underflow() {
    let dec1 = Decimal {
      value: u256::from_u64(10),
      scale: 6
    };
    let dec2 = Decimal {
      value: u256::from_u64(11),
      scale: 6
    };
    sub(dec1, dec2);
  }

  //Needs more testing
  #[test(account = @Ultima)]
  public entry fun test_mul() {
    let dec1 = Decimal {
      value: u256::from_u64(3000),
      scale: 6
    };
    let dec2 = Decimal {
      value: u256::from_u64(9000),
      scale: 3
    };
    let result = mul(dec1, dec2);
    //debug::print<Decimal>(&result);
    assert!(u256::as_u64(result.value) == 27000 && result.scale == 6, 0);
    let dec3 = Decimal {
      value: u256::from_u64(3000),
      scale: 3
    };
    let dec4 = Decimal {
      value: u256::from_u64(9000),
      scale: 6
    };
    let result2 = mul(dec3, dec4);
    assert!(u256::as_u64(result2.value) == 27000 && result2.scale == 6, 0);
    let dec5 = Decimal {
      value: u256::from_u64(72000000000),
      scale: 8
    };
    let dec6 = Decimal {
      value: u256::from_u64(700000000),
      scale: 8
    };
    let result = mul(dec5, dec6);
    assert!(u256::as_u64(result.value) == 504000000000 && result.scale == 8, 0);
  }

  // //Needs more testing
  // #[test(account = @Ultima)]
  // #[expected_failure]
  // public entry fun test_mul_aborts_on_overflow() {
  //   let dec1 = Decimal {
  //     value: u256::from_u128(3402823669209384634633746074317682114),
  //     scale: 6
  //   };
  //   let dec2 = Decimal {
  //     value: u256::from_u64(200),
  //     scale: 6
  //   };
  //   mul(dec1, dec2);
  // }

  //Needs more testing
  #[test(account = @Ultima)]
  public entry fun test_div_floor() {

    let dec1 = Decimal {
      value: u256::from_u64(5000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u64(5000),
      scale: 3
    };
    let result = div_floor(dec1, dec2);
    //debug::print<Decimal>(&result);
    assert!(u256::as_u64(result.value) == 1000 && result.scale == 3, 0);

    let dec5 = Decimal {
      value: u256::from_u64(3000),
      scale: 6
    };
    let dec6 = Decimal {
      value: u256::from_u64(9000),
      scale: 3
    };
    let result = div_floor(dec5, dec6);
    assert!(u256::as_u64(result.value) == 333 && result.scale == 6, 0);
    
    let dec7 = Decimal {
      value: u256::from_u64(3000),
      scale: 3
    };
    let dec8 = Decimal {
      value: u256::from_u64(9000),
      scale: 6
    };
    let result2 = div_floor(dec7, dec8);
    assert!(u256::as_u64(result2.value) == 333 && result2.scale == 6, 0);
    
    let dec9 = Decimal {
      value: u256::from_u64(720000000000),
      scale: 8
    };
    let dec10 = Decimal {
      value: u256::from_u64(720000000),
      scale: 8
    };
    let result = div_floor(dec9, dec10);
    //debug::print<Decimal>(&result);
    assert!(u256::as_u64(result.value) == 100000000000 && result.scale == 8, 0);
  }
  
  #[test(account = @Ultima)]
  public entry fun test_div_ceiling() {
    let dec1 = Decimal {
      value: u256::from_u64(3000),
      scale: 6
    };
    let dec2 = Decimal {
      value: u256::from_u64(9000),
      scale: 3
    };
    let result = div_ceiling(dec1, dec2);
    assert!(u256::as_u64(result.value) == 334 && result.scale == 6, 0);
    let dec3 = Decimal {
      value: u256::from_u64(3000),
      scale: 3
    };
    let dec4 = Decimal {
      value: u256::from_u64(9000),
      scale: 6
    };
    let result2 = div_ceiling(dec3, dec4);
    assert!(u256::as_u64(result2.value) == 334 && result2.scale == 6, 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_div_ceiling_2() {
    let dec1 = Decimal {
      value: u256::from_u128(340282366920938463463374606),
      scale: 12
    };
    let dec2 = Decimal {
      value: u256::from_u64(1000000000000),
      scale: 12
    };
    let result = div_ceiling(dec1, dec2);
    debug::print(&result);
    // assert!(result.value == 334 && result.scale == 6, 0);
  }

// #[test(account = @Ultima)]
// #[expected_failure]
//   public entry fun test_div_limit() {
//     let dec1 = Decimal {
//       value: u256::from_u128(340282366920938463463374607),
//       scale: 12
//     };
//     let dec2 = Decimal {
//       value: u256::from_u64(1000000000000),
//       scale: 12
//     };
//     let result = div_ceiling(dec1, dec2);
//     debug::print(&result);
//     // assert!(result.value == 334 && result.scale == 6, 0);
//   }

// #[test(account = @Ultima)]
//   public entry fun test_mul_big() {
// let dec1 = Decimal {
//       value: u256::from_u128(18446744073709551 * 1000000000000),
//       scale: 12
//     };
//     let dec2 = Decimal {
//       value: u256::from_u128(18446744073709551 * 1000000000000),
//       scale: 12
//     };
// let result = mul(dec1, dec2);
//     debug::print(&result);
//   }


  #[test(account = @Ultima)]
  public entry fun explicit_sanity_test_for_difference_between_floor_and_ceiling_div() {
    let dec1 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u128(9000),
      scale: 3
    };
    let result = div_floor(dec1, dec2);
    debug::print<Decimal>(&result);
    assert!(u256::as_u64(result.value) == 333 && result.scale == 3, 0);
    let result = div_ceiling(dec1, dec2);
    debug::print<Decimal>(&result);
    assert!(u256::as_u64(result.value) == 334 && result.scale == 3, 0);

    let dec3 = Decimal {
      value: u256::from_u128(720000000000),
      scale: 8
    };
    let dec4 = Decimal {
      value: u256::from_u128(720000000),
      scale: 8
    };
    let result = div_ceiling(dec3, dec4);
    assert!(u256::as_u64(result.value) == 100000000000 && result.scale == 8, 0);
    let result = div_floor(dec3, dec4);
    assert!(u256::as_u64(result.value) == 100000000000 && result.scale == 8, 0);

    let dec5 = Decimal {
      value: u256::from_u128(1000000000),
      scale: 8
    };
    let dec6 = Decimal {
      value: u256::from_u128(100000000),
      scale: 8
    };
    let result = div_ceiling(dec5, dec6);
    assert!(u256::as_u64(result.value) == 1000000000 && result.scale == 8, 0);
    let result = div_floor(dec5, dec6);
    assert!(u256::as_u64(result.value) == 1000000000 && result.scale == 8, 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_lt() {
    let dec1 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec3 = Decimal {
      value: u256::from_u128(4000),
      scale: 3
    };
    assert!(lt(dec2, dec3), 0);
    assert!(!lt(dec1, dec2), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_gt() {
    let dec1 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec3 = Decimal {
      value: u256::from_u128(4000),
      scale: 3
    };
    assert!(gt(dec3, dec2), 0);
    assert!(!gt(dec1, dec2), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_lte() {
    let dec1 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec3 = Decimal {
      value: u256::from_u128(4000),
      scale: 3
    };
    assert!(lte(dec2, dec3), 0);
    assert!(lte(dec2, dec1), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_gte() {
    let dec1 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec3 = Decimal {
      value: u256::from_u128(4000),
      scale: 3
    };
    assert!(gte(dec3, dec2), 0);
    assert!(gte(dec2, dec1), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_eq() {
    let dec1 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec2 = Decimal {
      value: u256::from_u128(3000),
      scale: 3
    };
    let dec3 = Decimal {
      value: u256::from_u128(4000),
      scale: 3
    };
    assert!(!eq(dec3, dec2), 0);
    assert!(eq(dec2, dec1), 0);
  }
}
