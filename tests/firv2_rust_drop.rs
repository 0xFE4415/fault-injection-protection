// REQUIRES: rustup
// The second result is only used for the comparison, so it must be dropped afterwards.
// RUN: %build_firv2_macro
// RUN: %rustc_firv2 %s -o %t.out
// RUN: %t.out | FileCheck %s
// CHECK: leaked 0

use std::sync::atomic::{AtomicUsize, Ordering};

static CREATED: AtomicUsize = AtomicUsize::new(0);
static DROPPED: AtomicUsize = AtomicUsize::new(0);

#[derive(PartialEq)]
pub struct Tracked(Vec<u8>);

impl Drop for Tracked {
    fn drop(&mut self) {
        DROPPED.fetch_add(1, Ordering::SeqCst);
    }
}

#[rust_firv2::harden_fn(Tracked::eq)]
fn make() -> Tracked {
    CREATED.fetch_add(1, Ordering::SeqCst);
    Tracked(vec![1; 64])
}

fn main() {
    drop(make());
    let leaked = CREATED.load(Ordering::SeqCst) - DROPPED.load(Ordering::SeqCst);
    println!("leaked {leaked}");
}
