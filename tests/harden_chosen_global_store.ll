; A critical value stored to a global must not pull instructions of other functions into this function's hardening.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: opt -passes='cfip<check-asap>' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o /dev/null

declare i32 @cfip_harden_var_(i32)

@g = global i32 0

; CHECK-LABEL: define i32 @other()
; CHECK-NOT: poison
; CHECK: ret i32
define i32 @other() {
  %v = load i32, ptr @g
  %r = add i32 %v, 1
  ret i32 %r
}

define i32 @main() {
  %val = call i32 @cfip_harden_var_(i32 42)
  store i32 %val, ptr @g
  ret i32 0
}
