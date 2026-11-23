; An sret result pointer that is used before the byval input is defined must still dominate its uses after the marker is unwrapped.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

@escaped = global ptr null

declare void @cfip_harden_var_(ptr sret([1 x i32]), ptr byval([1 x i32]))

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: cfip_harden_var_
; CHECK: sub i32 %{{[^ ,]*barrier[^ ,]*}}, 7
define i32 @main() {
  %result = alloca [1 x i32], align 4
  store ptr %result, ptr @escaped, align 8
  %input = alloca [1 x i32], align 4
  store i32 7, ptr %input, align 4
  call void @cfip_harden_var_(ptr sret([1 x i32]) %result, ptr byval([1 x i32]) %input)
  %escaped_result = load ptr, ptr @escaped, align 8
  %value = load i32, ptr %escaped_result, align 4
  %diff = sub i32 %value, 7
  ret i32 %diff
}
