; LTO merges same-named marker declarations from different crates, so a call's type can differ from its declaration.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll

declare i32 @cfip_harden_var_0(i32)
declare i32 @cfip_harden_var_1(i32)

; CHECK-LABEL: define i64 @main()
; CHECK-NOT: cfip_harden_var_0(
; CHECK: add i64 42, 1
; CHECK: add i64 %{{[^ ,]*barrier[^ ,]*}}, 1
define i64 @main() {
  %val = call i64 @cfip_harden_var_0(i64 42)
  %r = add i64 %val, 1
  ret i64 %r
}

; The call has sret and the declaration does not, so the call site decides.
; CHECK-LABEL: define i32 @sret_call()
; CHECK-NOT: cfip_harden_var_1(
; CHECK: add i32 7, 1
; CHECK: add i32 %{{[^ ,]*barrier[^ ,]*}}, 1
define i32 @sret_call() {
  %input = alloca [1 x i32]
  %result = alloca [1 x i32]
  store [1 x i32] [i32 7], ptr %input
  call void @cfip_harden_var_1(ptr sret([1 x i32]) %result, ptr byval([1 x i32]) %input)
  %v = load i32, ptr %result
  %r = add i32 %v, 1
  ret i32 %r
}
