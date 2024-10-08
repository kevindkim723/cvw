dst := IP

all: ArtyA7

.PHONY: ArtyA7 vcu118 vcu108

ArtyA7: export XILINX_PART := xc7a100tcsg324-1
ArtyA7: export XILINX_BOARD := digilentinc.com:arty-a7-100:part0:1.1
ArtyA7: export board := ArtyA7
ArtyA7: FPGA_Arty

vcu118: export XILINX_PART := xcvu9p-flga2104-2L-e
vcu118: export XILINX_BOARD := xilinx.com:vcu118:part0:2.4
vcu118: export board := vcu118
vcu118: FPGA_VCU

vcu108: export XILINX_PART := xcvu095-ffva2104-2-e
vcu108: export XILINX_BOARD := xilinx.com:vcu108:part0:1.7
vcu108: export board := vcu108
vcu108: FPGA_VCU

.PHONY: FPGA_Arty FPGA_VCU
FPGA_Arty: PreProcessFiles IP_Arty
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log
FPGA_VCU: PreProcessFiles IP_VCU
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log

# Generate IP Blocks
.PHONY: IP_Arty IP_VCU
IP_VCU: $(dst)/sysrst.log \
	MEM_VCU \
	$(dst)/clkconverter.log \
	$(dst)/ahbaxibridge.log
IP_Arty: $(dst)/sysrst.log \
	MEM_Arty \
	$(dst)/xlnx_mmcm.log \
	$(dst)/clkconverter.log \
	$(dst)/ahbaxibridge.log
#$(dst)/xlnx_axi_crossbar.log \
#$(dst)/xlnx_axi_dwidth_conv_32to64.log \
#$(dst)/xlnx_axi_dwidth_conv_64to32.log \
#$(dst)/xlnx_axi_prtcl_conv.log

# Generate Memory IP Blocks
.PHONY: MEM_VCU MEM_Arty
MEM_VCU:
	$(MAKE) $(dst)/ddr4-$(board).log
MEM_Arty:
	$(MAKE) $(dst)/ddr3-$(board).log

# Copy files and make necessary modifications
.PHONY: PreProcessFiles
PreProcessFiles:
	$(MAKE) -C ../../sim deriv
	rm -rf ../src/CopiedFiles_do_not_add_to_repo/
	cp -r ../../src/ ../src/CopiedFiles_do_not_add_to_repo/
	cp -r ../../addins/verilog-ethernet/*/*.sv ../src/CopiedFiles_do_not_add_to_repo/rvvi
	cp -r ../../addins/verilog-ethernet/*/*/*/*.sv ../src/CopiedFiles_do_not_add_to_repo/rvvi
	mkdir ../src/CopiedFiles_do_not_add_to_repo/config/
	cp ../../config/deriv/fpga/config.vh ../src/CopiedFiles_do_not_add_to_repo/config/
	./insert_debug_comment.sh
	# modify config  *** RT: eventually setup for variably defined sized memory
	#sed -i "s/EXT_MEM_RANGE.*/EXT_MEM_RANGE = 64'h0FFFFFFF;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	# This line allows the Bootloader to be loaded in a Block RAM on the FPGA
	sed -i "s/bit \[DATA_WIDTH-1:0\].*ROM.*/(\* rom_style=\"block\" \*) &/g" ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv
	sed -i 's/$$WALLY/\.\.\/\.\.\/\.\.\//g' ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv
	sed -i 's/$$WALLY/\.\.\/\.\.\/\.\.\//g' ../src/CopiedFiles_do_not_add_to_repo/generic/mem/ram1p1rwbe.sv

# Generate Individual IP Blocks
$(dst)/%.log: %.tcl
	mkdir -p IP
	cd IP;\
	vivado -mode batch -source ../$*.tcl | tee $*.log

# Clean
.PHONY: cleanIP cleanLogs cleanFPGA cleanAll
cleanIP:
	rm -rf IP
cleanLogs:
	rm -rf  *.jou *.log
cleanFPGA:
	rm -rf WallyFPGA.* reports sim .Xil
cleanAll: cleanIP cleanLogs cleanFPGA

# Aliases
.PHONY: arty artya7 VCU118 VCU108
arty artya7: ArtyA7
VCU118: vcu118
VCU108: vcu108
