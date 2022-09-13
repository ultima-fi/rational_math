module Ultima::UltimaRationalMath {
  use std::error;
  use std::option::{Option, some, none};
  #[test_only]
  use std::option::destroy_some;
//  #[test_only]
//  use std::debug;

  const MAX_U64: u128 = 18446744073709551615;

  const ERR_DIV_BY_ZERO: u64 = 0;
  const ERR_OUT_OF_RANGE: u64 = 1;
  const ERR_DIFFERENT_SCALE: u64 = 2;

  struct Decimal has drop, copy, store {
    value: u64,
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

  public fun new(v: u64, s: u8): Decimal {
    Decimal {
      value: v,
      scale: s,
    }
  }

  public fun val(d: &Decimal): u64 {
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
      d.value = d.value / pow(10u64, d.scale - new_scale);
      d.scale = new_scale;
    }
    else {
      d.value = d.value * pow(10u64, new_scale - d.scale);
      d.scale = new_scale;
    }
  }

  public fun denominator(d: &Decimal): u64 {
    pow(10u64, d.scale)
  }

  //----------------------------------------------------------
  //                     Arithmetic
  //----------------------------------------------------------

  //adds two decimals of the same scale, returns none if overflow
  public fun add(d1: Decimal, d2: Decimal): Option<Decimal> {
    assert!(d1.scale == d2.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    if ((d1.value as u128) + (d2.value as u128) > MAX_U64) {
      return none<Decimal>()
    };
    some<Decimal>(Decimal {
      value: d1.value + d2.value,
      scale: d1.scale,
    })
  }

  //subs two decimals of the same scale, returns none if underflow
  public fun sub(larger: Decimal, smaller: Decimal): Option<Decimal> {
    assert!(larger.scale == smaller.scale, error::invalid_argument(ERR_DIFFERENT_SCALE));
    if (larger.value < smaller.value) {
      return none<Decimal>()
    };
    some<Decimal>(Decimal {
      value: larger.value - smaller.value,
      scale: larger.scale,
    })
  }



  //Returns none if MAX_u64 is exceeded but can't check if
  //the operations will exceed MAX_U128, care required.

  //Don't trust either of the folling functions yet, they very likely need refinement
  public fun mul(d1: Decimal, d2: Decimal): Option<Decimal> {
    let smallerdenom = min_u64(denominator(&d1), denominator(&d2));
    if (smallerdenom < 2 || (((d1.value as u128) * (d2.value as u128)) + ((smallerdenom - 1) as u128)) / (smallerdenom as u128) > MAX_U64) {
      return none<Decimal>()
    };
    let val = (((d1.value as u128) * (d2.value as u128)) + ((smallerdenom - 1) as u128)) / (smallerdenom as u128);
    some<Decimal>(Decimal {
      value: (val as u64),
      scale: max_u8(d1.scale, d2.scale),
    })
  }

  public fun div(d1: Decimal, d2: Decimal, round_up: bool): Option<Decimal> {
    let round = 0;
    if (!round_up) {
      round = 1;
    };
    assert!(d1.value != 0 && d2.value != 0 && d1.scale != 0 && d2.scale != 0, error::invalid_argument(ERR_DIV_BY_ZERO));
    let smallerdenom = min_u64(denominator(&d1), denominator(&d2));
    if (d2.value < 2 || (((d1.value as u128) * (smallerdenom as u128)) + ((d2.value - 1) as u128)) / (d2.value as u128) - (round as u128) > MAX_U64) {
      return none<Decimal>()
    };
    let val = (((d1.value as u128) * (smallerdenom as u128)) + ((d2.value - 1) as u128)) / (d2.value as u128) - (round as u128);
    some<Decimal>(Decimal {
      value: (val as u64),
      scale: max_u8(d1.scale, d2.scale),
    })

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

  fun pow(base: u64, exp: u8): u64 {
    let count: u8 = 1;
    let val: u64 = base;
    while (count < exp) {
      val = val * base;
      count = count + 1;
    };
    val
  }

  fun min_u64(first: u64, second: u64): u64 {
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
    let maybe = add(dec1, dec2);
    let result = destroy_some(maybe);
    assert!(result.value == 3000 && result.scale == 6, 0);
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
    let maybe = sub(dec1, dec2);
    let result = destroy_some(maybe);
    assert!(result.value == 1000 && result.scale == 6, 0);
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
    let maybe = mul(dec1, dec2);
    let result = destroy_some(maybe);
    assert!(result.value == 27000 && result.scale == 6, 0);
    let dec3 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec4 = Decimal {
      value: 9000,
      scale: 6
    };
    let maybe2 = mul(dec3, dec4);
    let result2 = destroy_some(maybe2);
    assert!(result2.value == 27000 && result2.scale == 6, 0);
    let dec5 = Decimal {
      value: 72000000000,
      scale: 8
    };
    let dec6 = Decimal {
      value: 700000000,
      scale: 8
    };
    let maybe = mul(dec5, dec6);
    let result = destroy_some(maybe);
    assert!(result.value == 504000000000 && result.scale == 8, 0);
  }

  //Needs more testing
  #[test(account = @Ultima)]
  public entry fun test_div() {
    let dec1 = Decimal {
      value: 3000,
      scale: 6
    };
    let dec2 = Decimal {
      value: 9000,
      scale: 3
    };
    let maybe = div(dec1, dec2, true);
    let result = destroy_some(maybe);
    assert!(result.value == 334 && result.scale == 6, 0);
    let dec3 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec4 = Decimal {
      value: 9000,
      scale: 6
    };
    let maybe2 = div(dec3, dec4, true);
    let result2 = destroy_some(maybe2);
    assert!(result2.value == 334 && result2.scale == 6, 0);
    let dec5 = Decimal {
      value: 3000,
      scale: 6
    };
    let dec6 = Decimal {
      value: 9000,
      scale: 3
    };
    let maybe = div(dec5, dec6, false);
    let result = destroy_some(maybe);
    assert!(result.value == 333 && result.scale == 6, 0);
    let dec7 = Decimal {
      value: 3000,
      scale: 3
    };
    let dec8 = Decimal {
      value: 9000,
      scale: 6
    };
    let maybe2 = div(dec7, dec8, false);
    let result2 = destroy_some(maybe2);
    assert!(result2.value == 333 && result2.scale == 6, 0);
    let dec9 = Decimal {
      value: 720000000000,
      scale: 8
    };
    let dec10 = Decimal {
      value: 720000000,
      scale: 8
    };
    let maybe = div(dec9, dec10, true);
    let result = destroy_some(maybe);
    assert!(result.value == 100000000000 && result.scale == 8, 0);
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
