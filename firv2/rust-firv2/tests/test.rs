pub fn foo(x: &i32, y: &i32) -> bool {
    x == y
}

#[rust_firv2::harden_fn(foo)]
pub fn test1() -> i32 {
    1
}

#[rust_firv2::harden_fn(i32::eq)]
pub fn test2(x: &i32) -> &i32 {
    x
}
