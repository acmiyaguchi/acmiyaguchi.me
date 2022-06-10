---
layout: post
title: Enabling some wasm-bindgen tests in ring
date: 2021-01-25T16:44:00-08:00
category: Engineering
tags:
  - rust
  - wasm
---

I was recently digging into compiling a rust crate that relies on
[ring](https://github.com/briansmith/ring) into wasm. It is a small cryptography
library with over [7 million](https://crates.io/crates/ring) downloads to date.
While I could compile the code successfully, I ran into some errors that I
reproduced [in this PR](https://github.com/briansmith/ring/pull/1176). First I
added a few wasm-bindgen tests by adding the appropriate feature flags. Then I
ran the tests to get the same errors I was seeing in my own rollup project.

```bash
% wasm-pack test --firefox --headless --  --test ed25519_tests
[INFO]: 🎯  Checking for the Wasm target...
   Compiling ring v0.16.19 (/Users/amiyaguchi/Work/ring)
    Finished dev [unoptimized + debuginfo] target(s) in 1.86s
[INFO]: ⬇️  Installing wasm-bindgen...
    Finished test [unoptimized + debuginfo] target(s) in 0.05s
     Running target/wasm32-unknown-unknown/debug/deps/ed25519_tests-af557e71142febbd.wasm
Set timeout to 20 seconds...
Running headless tests in Firefox on `http://127.0.0.1:62602/`
Try find `webdriver.json` for configure browser's capabilities:
Not found
Failed to detect test as having been run. It might have timed out.
output div contained:
    Loading scripts...

driver status: signal: 9
driver stdout:
    1611356824151       geckodriver     INFO    Listening on 127.0.0.1:62602
    1611356824255       mozrunner::runner       INFO    Running command: "/Applications/Firefox.app/Contents/MacOS/firefox-bin" "--marionette" "-headless" "-foreground" "-no-remote" "-profile" "/var/folders/q6/m7bqqf2n05l5dvng72_xvvlw0000gn/T/rust_mozprofileZY7YL3"
    console.warn: SearchSettings: "get: No settings file exists, new profile?" (new Error("", "(unknown module)"))
    1611356825619       Marionette      INFO    Listening on port 62606
    1611356845909       Marionette      INFO    Stopped listening on port 62606

driver stderr:
    *** You are running in headless mode.
    JavaScript error: http://127.0.0.1:62601/wasm-bindgen-test, line 1: TypeError: Error resolving module specifier “env”. Relative module specifiers must start with “./”, “../” or “/”.

Error: some tests failed
error: test failed, to rerun pass '--test ed25519_tests'
Error: Running Wasm tests with wasm-bindgen-test failed
Caused by: failed to execute `cargo test`: exited with exit code: 1
  full command: "cargo" "test" "--target" "wasm32-unknown-unknown" "--test" "ed25519_tests"
```

To get a better understanding of what the missing imports are, we can take a
look at the the textual representation of the generated wasm bytcode (better
known as wat). Here we use the [wasm2wat](https://github.com/WebAssembly/wabt)
utility provided by wabt.

```bash
% wasm2wat target/wasm32-unknown-unknown/debug/deps/ed25519_tests-af557e71142febbd.wasm | grep '(import "env"'
  (import "env" "GFp_x25519_ge_scalarmult_base" (func $GFp_x25519_ge_scalarmult_base (type 5)))
  (import "env" "GFp_x25519_sc_muladd" (func $GFp_x25519_sc_muladd (type 4)))
  (import "env" "GFp_x25519_sc_reduce" (func $GFp_x25519_sc_reduce (type 3)))
  (import "env" "GFp_x25519_sc_mask" (func $GFp_x25519_sc_mask (type 3)))
  (import "env" "GFp_x25519_fe_neg" (func $GFp_x25519_fe_neg (type 3)))
  (import "env" "GFp_x25519_ge_frombytes_vartime" (func $GFp_x25519_ge_frombytes_vartime (type 11)))
  (import "env" "GFp_x25519_fe_invert" (func $GFp_x25519_fe_invert (type 5)))
  (import "env" "GFp_x25519_fe_mul_ttt" (func $GFp_x25519_fe_mul_ttt (type 6)))
  (import "env" "GFp_x25519_fe_tobytes" (func $GFp_x25519_fe_tobytes (type 5)))
  (import "env" "GFp_x25519_fe_isnegative" (func $GFp_x25519_fe_isnegative (type 18)))
  (import "env" "GFp_x25519_ge_double_scalarmult_vartime" (func $GFp_x25519_ge_double_scalarmult_vartime (type 4)))
  (import "env" "LIMBS_less_than" (func $LIMBS_less_than (type 12)))
  (import "env" "LIMBS_are_zero" (func $LIMBS_are_zero (type 11)))
```

These look like they're missing because the relevant C code is not being built.
I changed a line in the build file and added a flag that enables the wasm32
target.

```bash
 % wasm-pack test --firefox --headless --  --features wasm32_c --test ed25519_tests
[INFO]: 🎯  Checking for the Wasm target...
   Compiling ring v0.16.19 (/Users/amiyaguchi/Work/ring)
    Finished dev [unoptimized + debuginfo] target(s) in 2.06s
[INFO]: ⬇️  Installing wasm-bindgen...
   Compiling ring v0.16.19 (/Users/amiyaguchi/Work/ring)
    Finished test [unoptimized + debuginfo] target(s) in 1.17s
     Running target/wasm32-unknown-unknown/debug/deps/ed25519_tests-8b475dcb9ffa54de.wasm
Set timeout to 20 seconds...
Running headless tests in Firefox on `http://127.0.0.1:63084/`
Try find `webdriver.json` for configure browser's capabilities:
Not found
running 6 tests

test ed25519_tests::ed25519_test_public_key_coverage ... ok
test ed25519_tests::test_ed25519_from_pkcs8 ... ok
test ed25519_tests::test_ed25519_from_pkcs8_unchecked ... ok
test ed25519_tests::test_ed25519_from_seed_and_public_key_misuse ... ok
test ed25519_tests::test_signature_ed25519_verify ... ok
test ed25519_tests::test_signature_ed25519 ... ok

test result: ok. 6 passed; 0 failed; 0 ignored
```

With this, the tests pass for this particular modules. Unfortunately, this
doesn't work for other failing tests in the repository because they rely on
generated assembly code instead of C. I hear there are side-channel concerns of
using cryptography compiled to wasm too, but I'm not too familiar with the
details. Regardless, it's promising to see the progress of wasm as a target for
compiled languages like rust.
