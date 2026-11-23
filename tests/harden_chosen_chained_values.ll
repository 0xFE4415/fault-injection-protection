; A hardened value that derives from another hardened value is hardened in both computations.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

declare i32 @cfip_harden_var_(i32)

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: cfip_harden_var_
; CHECK: %[[DERIVED:[0-9]+]] = add i32 40, 2
; CHECK: add i32 %{{[^ ,]*barrier[^ ,]*}}, 2
; CHECK: icmp ne i32 %[[DERIVED]], %{{[^ ,]*barrier[^ ,]*}}
; CHECK: %[[RESULT:[0-9]+]] = sub i32 %[[DERIVED]], 42
; CHECK: sub i32 %{{[^ ,]*barrier[^ ,]*}}, 42
; CHECK: icmp ne i32 %[[RESULT]], %{{[^ ,]*barrier[^ ,]*}}
; CHECK: ret i32 %[[RESULT]]
define i32 @main() {
  %first = call i32 @cfip_harden_var_(i32 40)
  %derived = add i32 %first, 2
  %second = call i32 @cfip_harden_var_(i32 %derived)
  %result = sub i32 %second, 42
  ret i32 %result
}
