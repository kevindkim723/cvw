
add wave -noupdate /testbenchfp/clk
add wave -noupdate -radix decimal /testbenchfp/VectorNum
add wave -noupdate /testbenchfp/FrmNum
add wave -noupdate /testbenchfp/X
add wave -noupdate /testbenchfp/Y
add wave -noupdate /testbenchfp/Z
add wave -noupdate /testbenchfp/Res
add wave -noupdate /testbenchfp/Ans
add wave -noupdate /testbenchfp/reset
add wave -noupdate /testbenchfp/DivStart
add wave -noupdate /testbenchfp/FDivBusyE
add wave -noupdate /testbenchfp/CheckNow
add wave -noupdate /testbenchfp/DivDone
add wave -noupdate /testbenchfp/ResMatch
add wave -noupdate /testbenchfp/FlagMatch
add wave -noupdate /testbenchfp/CheckNow
add wave -noupdate /testbenchfp/NaNGood
add wave -noupdate /testbenchfp/divremsqrt/drsu/divremsqrt/divremsqrtfdivsqrtpreproc/ForwardedSrcAE
add wave -noupdate /testbenchfp/divremsqrt/drsu/divremsqrt/divremsqrtfdivsqrtpreproc/ForwardedSrcBE
add wave -group {intspecialcase} -noupdate /testbenchfp/divremsqrt/drsu/divremsqrt/fdivsqrtpostproc/intpostproc/intspecialcase/*
add wave -group {cycles} -noupdate /testbenchfp/divremsqrt/drsu/divremsqrt/divremsqrtfdivsqrtpreproc/cyclecalc/*

add wave -group {Testbench} -noupdate /testbenchfp/*
add wave -group {Testbench} -noupdate /testbenchfp/readvectors/*