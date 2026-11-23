; An sret result that overlaps its byval input must be filled with memmove; the escaped buffer keeps SROA from rewriting the copy.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: lli %t.ll

@escaped = global ptr null

declare void @cfip_harden_var_(ptr sret([2 x i32]), ptr byval([2 x i32]))

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: cfip_harden_var_
; CHECK: call void @llvm.memmove.p0.p0.i64(ptr align {{[0-9]+}} %result, ptr align {{[0-9]+}} %buffer, i64 8, i1 false)
define i32 @main() {
  %buffer = alloca [3 x i32], align 4
  store ptr %buffer, ptr @escaped, align 8
  %result = getelementptr inbounds i8, ptr %buffer, i64 4
  store i32 7, ptr %buffer, align 4
  store i32 9, ptr %result, align 4
  call void @cfip_harden_var_(ptr sret([2 x i32]) %result, ptr byval([2 x i32]) %buffer)
  %first = load i32, ptr %result, align 4
  %second_ptr = getelementptr inbounds i8, ptr %result, i64 4
  %second = load i32, ptr %second_ptr, align 4
  %first_diff = sub i32 %first, 7
  %second_diff = sub i32 %second, 9
  %diff = or i32 %first_diff, %second_diff
  ret i32 %diff
}
