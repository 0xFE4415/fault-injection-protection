; A byval input derived from the sret result pointer must not become its own operand after the marker is unwrapped.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

declare void @cfip_harden_var_(ptr sret([1 x i32]), ptr byval([1 x i32]))

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: cfip_harden_var_
; CHECK: sub i32 %{{[^ ,]*barrier[^ ,]*}}, 7
define i32 @main() {
  %result = alloca [2 x i32], align 4
  %input = getelementptr inbounds i8, ptr %result, i64 4
  store i32 7, ptr %input, align 4
  call void @cfip_harden_var_(ptr sret([1 x i32]) %result, ptr byval([1 x i32]) %input)
  %value = load i32, ptr %result, align 4
  %diff = sub i32 %value, 7
  ret i32 %diff
}
