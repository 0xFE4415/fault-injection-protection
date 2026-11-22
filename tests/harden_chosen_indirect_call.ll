; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: clang %t.ll -o %t.out
; RUN: %t.out
; RUN: cat %t.ll | FileCheck %s

target triple = "x86_64-redhat-linux-gnu"

declare dso_local i32 @cfip_harden_var_(i32 noundef) local_unnamed_addr

@function_pointer = global ptr @store_value

define void @store_value(ptr %destination, i32 %value) {
  store i32 %value, ptr %destination
  ret void
}

; CHECK-LABEL: main
; CHECK-NOT: cfip_harden_var_
define dso_local i32 @main() local_unnamed_addr {
  %val = call i32 @cfip_harden_var_(i32 noundef 42)
  %buffer = alloca i32
  %callee = load ptr, ptr @function_pointer

  ; the indirect call is left unchanged
  ; CHECK: call void %callee(ptr %buffer, i32 42)
  call void %callee(ptr %buffer, i32 %val)

  ; the pointer passed to an unknown callee is tainted, so its users are hardened
  %stored = load i32, ptr %buffer
  ; CHECK: sub i32 %stored, 42
  ; CHECK: sub i32 %{{[^ ,]*barrier[^ ,]*}}, 42
  %difference = sub i32 %stored, 42
  ret i32 %difference
}
