module Ultima::UltimaRationalMath {
  use std::error;
  #[test_only]
  use std::debug;

  const MAX_U128: u128 = 340282366920938463463374607431768211455;

  const ERR_DIV_BY_ZERO: u64 = 0;
  const ERR_OUT_OF_RANGE: u64 = 1;
  const ERR_DIFFERENT_SCALE: u64 = 2;

  struct Decimal has drop, copy, store {
    value: u128,
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

  public fun new(v: u128, s: u8): Decimal {
    Decimal {
      value: v,
      scale: s,
    }
  }

  public fun val(d: &Decimal): u128 {
    d.value
  }
  
  public fun scale(d: &Decimal): u8 {
    d.scale
  }

  public fun is_zero(d: &Decimal): bool {
    d.value == 0
  }

  public fun adjust_scale(d: &mut Decimal, new_scale: u8) {
    assert!(new_scale > 0, error::invalid_argument(ERR_OUT_OF_RANGE));
    if (d.scale == new_scale) {
     return
    };
    if (d.scale > new_scale) {
      d.value = d.value / pow(10u128, d.scale - new_scale);
      d.scale = new_scale;
    }
    else {
      d.value = d.value * pow(10u128, new_scale - d.scale);
      d.scale = new_scale;
    }
  }

  public fun denominator(d: &Decimal): u128 {
    pow(10u128, d.scale)
  }

  //----------------------------------------------------------
  //                     Arithmetic
  //----------------------------------------------------------

  //adds two decimals of the same scale, returns none if overflow
  public fun add(d1: Decimal, d2: Decimal): Decimal {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    Decimal {
      value: d1.value + d2.value,
      scale: d1.scale,
    }
  }

  //subs two decimals of the same scale, returns none if underflow
  public fun sub(larger: Decimal, smaller: Decimal): Decimal {
    assert!(larger.scale == smaller.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    Decimal {
      value: larger.value - smaller.value,
      scale: larger.scale,
    }
  }

  //multiplies two decimals, can handle different scales, can overflow
  public fun mul(d1: Decimal, d2: Decimal): Decimal {
    let smallerdenom = min_u128(denominator(&d1), denominator(&d2));
    Decimal {
      value: ((d1.value * d2.value) + (smallerdenom - 1)) / smallerdenom,
      scale: max_u8(d1.scale, d2.scale),
    }
  }

  //divides two decimals with floor div, can handle different scales
  public fun div_floor(d1: Decimal, d2: Decimal): Decimal {
    assert!(d2.value != 0, error::invalid_argument(ERR_DIV_BY_ZERO));
    let scale = max_u8(d1.scale, d2.scale);
    
    if (d1.value == 0) {
      return Decimal {
        value: 0,
        scale
      }
    };

    let smallerdenom = min_u128(denominator(&d1), denominator(&d2));

    Decimal {
      value: (d1.value * smallerdenom) / d2.value,
      scale
    }
  }

  //divides two decimals with ceiling div
  public fun div_ceiling(d1: Decimal, d2: Decimal): Decimal {
    assert!(d2.value != 0, error::invalid_argument(ERR_DIV_BY_ZERO));
    let scale = max_u8(d1.scale, d2.scale);
    
    if (d1.value == 0) {
      return Decimal {
        value: 0,
        scale
      }
    };

    let smallerdenom = min_u128(denominator(&d1), denominator(&d2));

    Decimal {
      value: ((d1.value * smallerdenom) + (d2.value - 1)) / d2.value,
      scale
    }
  }

  //----------------------------------------------------------
  //                     Comparisons
  //----------------------------------------------------------
  public fun lt(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return d1.value < d2.value
  }

  public fun gt(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return d1.value > d2.value
  }

  public fun lte(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return d1.value <= d2.value
  }

  public fun gte(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return d1.value >= d2.value
  }

  public fun eq(d1: Decimal, d2: Decimal): bool {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    return d1.value == d2.value
  }


  //---------------------------------------------------------- 
  //                       Internal
  //----------------------------------------------------------

  fun pow(base: u128, exp: u8): u128 {
    let count: u8 = 1;
    let val: u128 = base;
    while (count < exp) {
      val = val * base;
      count = count + 1;
    };
    val
  }

  fun min_u128(first: u128, second: u128): u128 {
    if (first < second) {
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

  #[test(account = @Ultima)]
  public entry fun test_new_raw() {
    let five = new(5, UNIFIED_SCALE);
    assert!(five.value == 5 && five.scale == UNIFIED_SCALE, 0)
  }

  #[test(account = @Ultima)]
  public entry fun test_denominator() {
    let dec = Decimal {
      value: 1800,
      scale: 6
    };
    assert!(denominator(&dec) == 1000000,0)
  }

  #[test(account = @Ultima)]
  public entry fun test_zero() {
    let zero = new(0, UNIFIED_SCALE);
    assert!(is_zero(&zero), 0)
  }

  #[test(account = @Ultima)]
  public entry fun test_pow() {
    assert!(pow(10, 6) == 1000000, 0);
    assert!(pow(2, 10) == 1024, 0)
  }

  #[test(account = @Ultima)]
  public entry fun test_scaling() {
    let dec = Decimal {
      value: 1200,
      scale: 6
    };
    adjust_scale(&mut dec, 7);
    assert!(dec.value == 12000 && dec.scale == 7, 0);
    adjust_scale(&mut dec, 5);
    assert!(dec.value == 120 && dec.scale == 5, 0);
    adjust_scale(&mut dec, 5);
    assert!(dec.value == 120 && dec.scale == 5, 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_add() {
    let dec1 = Decimal {
      value: 1500,
      scale: 6
    };
    let dec2 = Decimal {
      value: 1500,
      scale: 6
    };
    let result = add(dec1, dec2);
    assert!(result.value == 3000 && result.scale == 6, 0);
  }

  #[test(account = @Ultima)]
  #[expected_failure]
  public entry fun test_add_aborts_on_overflow() {
    let dec3 = Decimal {
      value: 340282366920938463463374607431768211455,
      scale: 6
    };
    let dec4 = Decimal {
      value: 1,
      scale: 6
    };
    add(dec3, dec4);
  }

  #[test(account = @Ultima)]
  public entry fun test_sub() {
    let dec1 = Decimal {
      value: 1300,
      scale: 6
    };
    let dec2 = Decimal {
      value: 300,
      scale: 6
    };
    let result = sub(dec1, dec2);
    assert!(result.value == 1000 && result.scale == 6, 0);
  }

   #[test(account = @Ultima)]
  #[expected_failure]
  public entry fun test_sub_aborts_on_underflow() {
    let dec1 = Decimal {
      value: 10,
      scale: 6
    };
    let dec2 = Decimal {
      value: 11,
      scale: 6
    };
    sub(dec1, dec2);
  }

  //Needs more testing
  #[test(account = @Ultima)]
  public entry fun test_mul() {
    let dec1 = Decimal {
      value: 3000,
      scale: 6
    };
    let dec2 = Decimal {
      value: 9000,
      scale: 3
    };
    let result = mul(dec1, dec2);
    //debug::print<Decimal>(&result);
    assert!(result.value == 27000 && result.scale == 6, 0);
    let dec3 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec4 = Decimal {
      value: 9000,
      scale: 6
    };
    let result2 = mul(dec3, dec4);
    assert!(result2.value == 27000 && result2.scale == 6, 0);
    let dec5 = Decimal {
      value: 72000000000,
      scale: 8
    };
    let dec6 = Decimal {
      value: 700000000,
      scale: 8
    };
    let result = mul(dec5, dec6);
    assert!(result.value == 504000000000 && result.scale == 8, 0);
  }

  //Needs more testing
  #[test(account = @Ultima)]
  #[expected_failure]
  public entry fun test_mul_aborts_on_overflow() {
    let dec1 = Decimal {
      value: 3402823669209384634633746074317682114,
      scale: 6
    };
    let dec2 = Decimal {
      value: 200,
      scale: 6
    };
    mul(dec1, dec2);
  }

  //Needs more testing
  #[test(account = @Ultima)]
  public entry fun test_div_floor() {

    let dec1 = Decimal {
      value: 5000,
      scale: 3
    };
    let dec2 = Decimal {
      value: 5000,
      scale: 3
    };
    let result = div_floor(dec1, dec2);
    //debug::print<Decimal>(&result);
    assert!(result.value == 1000 && result.scale == 3, 0);

    let dec5 = Decimal {
      value: 3000,
      scale: 6
    };
    let dec6 = Decimal {
      value: 9000,
      scale: 3
    };
    let result = div_floor(dec5, dec6);
    assert!(result.value == 333 && result.scale == 6, 0);
    
    let dec7 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec8 = Decimal {
      value: 9000,
      scale: 6
    };
    let result2 = div_floor(dec7, dec8);
    assert!(result2.value == 333 && result2.scale == 6, 0);
    
    let dec9 = Decimal {
      value: 720000000000,
      scale: 8
    };
    let dec10 = Decimal {
      value: 720000000,
      scale: 8
    };
    let result = div_floor(dec9, dec10);
    //debug::print<Decimal>(&result);
    assert!(result.value == 100000000000 && result.scale == 8, 0);
  }
  
  #[test(account = @Ultima)]
  public entry fun test_div_ceiling() {
    let dec1 = Decimal {
      value: 3000,
      scale: 6
    };
    let dec2 = Decimal {
      value: 9000,
      scale: 3
    };
    let result = div_ceiling(dec1, dec2);
    assert!(result.value == 334 && result.scale == 6, 0);
    let dec3 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec4 = Decimal {
      value: 9000,
      scale: 6
    };
    let result2 = div_ceiling(dec3, dec4);
    assert!(result2.value == 334 && result2.scale == 6, 0);
  }

  #[test(account = @Ultima)]
  public entry fun explicit_sanity_test_for_difference_between_floor_and_ceiling_div() {
    let dec5 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec6 = Decimal {
      value: 9000,
      scale: 3
    };
    let result = div_floor(dec5, dec6);
    debug::print<Decimal>(&result);
    assert!(result.value == 333 && result.scale == 3, 0);

    let dec5 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec6 = Decimal {
      value: 9000,
      scale: 3
    };
    let result = div_ceiling(dec5, dec6);
    debug::print<Decimal>(&result);
    assert!(result.value == 334 && result.scale == 3, 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_lt() {
    let dec1 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec2 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec3 = Decimal {
      value: 4000,
      scale: 3
    };
    assert!(lt(dec2, dec3), 0);
    assert!(!lt(dec1, dec2), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_gt() {
    let dec1 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec2 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec3 = Decimal {
      value: 4000,
      scale: 3
    };
    assert!(gt(dec3, dec2), 0);
    assert!(!gt(dec1, dec2), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_lte() {
    let dec1 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec2 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec3 = Decimal {
      value: 4000,
      scale: 3
    };
    assert!(lte(dec2, dec3), 0);
    assert!(lte(dec2, dec1), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_gte() {
    let dec1 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec2 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec3 = Decimal {
      value: 4000,
      scale: 3
    };
    assert!(gte(dec3, dec2), 0);
    assert!(gte(dec2, dec1), 0);
  }

  #[test(account = @Ultima)]
  public entry fun test_eq() {
    let dec1 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec2 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec3 = Decimal {
      value: 4000,
      scale: 3
    };
    assert!(!eq(dec3, dec2), 0);
    assert!(eq(dec2, dec1), 0);
  }
}
