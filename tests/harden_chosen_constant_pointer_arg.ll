; A constant pointer passed next to a critical value has no use list and is not critical.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll

declare i32 @cfip_harden_var_(i32)
declare void @ext(i32, ptr)

define i32 @defined(i32 %v, ptr %p) {
  %r = add i32 %v, 1
  ret i32 %r
}

; CHECK-LABEL: define i32 @to_defined()
; CHECK: call i32 @defined.hardened.0(i32 42, ptr null)
define i32 @to_defined() {
  %val = call i32 @cfip_harden_var_(i32 42)
  %r = call i32 @defined(i32 %val, ptr null)
  ret i32 %r
}

; CHECK-LABEL: define i32 @to_declaration()
; CHECK: call void @ext(i32 42, ptr null)
; CHECK: add i32 42, 1
; CHECK: add i32 %{{[^ ,]*barrier[^ ,]*}}, 1
define i32 @to_declaration() {
  %val = call i32 @cfip_harden_var_(i32 42)
  call void @ext(i32 %val, ptr null)
  %r = add i32 %val, 1
  ret i32 %r
}

; A call that passes only the constant pointer is not a critical call.
; CHECK-LABEL: define i32 @unrelated()
; CHECK: call i32 @defined(i32 1, ptr null)
define i32 @unrelated() {
  %val = call i32 @cfip_harden_var_(i32 42)
  call void @ext(i32 %val, ptr null)
  %r = call i32 @defined(i32 1, ptr null)
  ret i32 %r
}
