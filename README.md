# Fault Injection protection

TODO: description

## Build

### Dependencies

* llvm developer package 23.*
* cmake >=3.20
* rust toolchain with LLVM 23.* backend

### llvm plugin

```sh
mkdir build; cd build
cmake ..
cmake --build .
cd -
```

### rust macro

```sh
cd rust_attribute
cargo b
```
