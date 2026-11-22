; A fault detected before an unwind must be checked before the function exits through resume.
; RUN: opt -passes='cfip' -load-pass-plugin=../build/lib/LLVMCfip.so %s -S -o %t.ll
; RUN: FileCheck %s < %t.ll

declare i32 @cfip_harden_var_(i32)
declare void @may_throw()
declare i32 @__gxx_personality_v0(...)

; CHECK-LABEL: define i32 @main()
; CHECK-LABEL: {{^}}lp:
; CHECK: landingpad
; CHECK: label %error_handling
; CHECK: resume
define i32 @main() personality ptr @__gxx_personality_v0 {
  %val = call i32 @cfip_harden_var_(i32 7)
  %x = mul i32 %val, 3
  invoke void @may_throw() to label %ok unwind label %lp
ok:
  ret i32 %x
lp:
  %e = landingpad { ptr, i32 } cleanup
  resume { ptr, i32 } %e
}
