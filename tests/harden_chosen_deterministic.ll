; The output must not depend on pointer values, which change between runs.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.0.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.1.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.2.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.3.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.4.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.5.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.6.ll
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.7.ll
; RUN: diff %t.0.ll %t.1.ll
; RUN: diff %t.0.ll %t.2.ll
; RUN: diff %t.0.ll %t.3.ll
; RUN: diff %t.0.ll %t.4.ll
; RUN: diff %t.0.ll %t.5.ll
; RUN: diff %t.0.ll %t.6.ll
; RUN: diff %t.0.ll %t.7.ll

declare i32 @cfip_harden_var_(i32)

define i32 @callee(i32 %x) {
entry:
  %a = mul i32 %x, 3
  %b = mul i32 %x, 5
  %c = icmp eq i32 %a, 15
  br i1 %c, label %t1, label %t0
t1:
  br label %t0
t0:
  %d = mul i32 %b, 7
  %e = mul i32 %a, 11
  %f = add i32 %d, %e
  ret i32 %f
}

define i32 @main() {
entry:
  %val = call i32 @cfip_harden_var_(i32 5)
  %a = mul i32 %val, 3
  %b = mul i32 %val, 5
  %c = icmp eq i32 %a, 15
  br i1 %c, label %t1, label %t0
t1:
  br label %t0
t0:
  %d = mul i32 %b, 7
  %e = mul i32 %a, 11
  %f = add i32 %d, %e
  %g = call i32 @callee(i32 %val)
  %h = add i32 %f, %g
  ret i32 %h
}
