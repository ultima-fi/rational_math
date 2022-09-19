# Decimal Lib

## Building and testing

Install the [Aptos CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli) then:

```
aptos move compile --named-addresses Ultima=<address>
aptos move test --named-addresses Ultima=<address>
```

## Features

#### Structs
Decimal struct has a value and a scale. Scale is the exponent of 10.
```
struct Decimal {
    value: u64,
    scale: u8
  }
``` 
#### Utility Functions
```move
public fun from_raw(v: u64, s: u8): Decimal 
```
- Returns a decimal with the given value and scale.
```move
  public fun is_zero(d: &Decimal): bool 
```
```move
  public fun adjust_scale(d: &mut Decimal, new_scale: u8)
```
- Cannot be used to set the scale to 0.

```move
  public fun denominator(d: &Decimal): u64
```
 - Returns 10 ^ scale.

#### Arithmetic
```move
public fun add(d1: Decimal, d2: Decimal): Option<Decimal>
```
  - Adds two decimals of the same scale, returns `none` if overflow occurs.

  ```move
  public fun sub(larger: Decimal, smaller: Decimal): Option<Decimal> 
  ```
  - Subs two decimals of the same scale, returns `none` if underflow


```move
public fun mul(d1: Decimal, d2: Decimal): Option<Decimal> {
```
  - Multiples two decimals of same or different scales, returns `none` if overflow can be detected.
  - Returns none if MAX_u64 is exceeded but can't check if the operations will exceed MAX_U128, care required.
  - Keeps the scale of the decimal with the larger denominator.

```move
public fun div(d1: Decimal, d2: Decimal, round_up: bool): Option<Decimal> 
```
  - Divides two decimals of same or different scales, returns `none` if overflow can be detected.
  - Will error if any of the numerators or denominators are 0.
  - Returns none if MAX_u64 is exceeded but can't check if the operations will exceed MAX_U128, care required.
  - Keeps the scale of the decimal with the larger denominator.


#### Internal Functions

```move
  fun pow(base: u64, exp: u8): u64 
```
- Performs exponentiation for a base and exponent.

```move
fun min_u64(first: u64, second: u64): u64 
```
- Returns the smaller of two u64s.

```move
fun max_u8(first: u8, second: u8): u8 
```
- Returns the larger of two u8s.
