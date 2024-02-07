///////////////////////////////////////////
// testbench.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Testbench and helper modules
//          Applies test programs from the riscv-arch-test and Imperas suites
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "config.vh"
`include "tests.vh"
`include "BranchPredictorType.vh"

import cvw::*;

module testbench;
  /* verilator lint_off WIDTHTRUNC */
  /* verilator lint_off WIDTHEXPAND */
  parameter DEBUG=0;
  parameter string TEST="arch64m";
  parameter PrintHPMCounters=0;
  parameter BPRED_LOGGER=0;
  parameter I_CACHE_ADDR_LOGGER=0;
  parameter D_CACHE_ADDR_LOGGER=0;
  parameter RISCV_DIR = "/opt/riscv";
  parameter INSTR_LIMIT = 0;
  
`include "parameter-defs.vh"

  logic        clk;
  logic        reset_ext, reset;
  logic        ResetMem;

  // DUT signals
  logic [P.AHBW-1:0]    HRDATAEXT;
  logic                 HREADYEXT, HRESPEXT;
  logic                 HSELEXTSDC;
  logic [P.PA_BITS-1:0] HADDR;
  logic [P.AHBW-1:0]    HWDATA;
  logic [P.XLEN/8-1:0]  HWSTRB;
  logic                 HWRITE;
  logic [2:0]           HSIZE;
  logic [2:0]           HBURST;
  logic [3:0]           HPROT;
  logic [1:0]           HTRANS;
  logic                 HMASTLOCK;
  logic                 HCLK, HRESETn;

  logic [31:0] GPIOIN, GPIOOUT, GPIOEN;
  logic        UARTSin, UARTSout;
  logic        SPIIn, SPIOut;
  logic [3:0]  SPICS;
  logic        SDCIntr;

  logic        HREADY;
  logic        HSELEXT;

  
  string  ProgramAddrMapFile, ProgramLabelMapFile;
  integer ProgramAddrLabelArray [string];

  int test, i, errors, totalerrors;

  string outputfile;
  integer outputFilePointer;

  string tests[];
  logic DCacheFlushDone, DCacheFlushStart;
  logic riscofTest; 
  logic Validate;
  logic SelectTest;
  logic TestComplete;

  // pick tests based on modes supported
  initial begin
    $display("TEST is %s", TEST);
    //tests = '{};
    if (P.XLEN == 64) begin // RV64
      case (TEST)
        "arch64i":                                tests = arch64i;
        "arch64priv":                             tests = arch64priv;
        "arch64c":      if (P.C_SUPPORTED) 
                          if (P.ZICSR_SUPPORTED)  tests = {arch64c, arch64cpriv};
                          else                    tests = {arch64c};
        "arch64m":      if (P.M_SUPPORTED)        tests = arch64m;
        "arch64a":      if (P.A_SUPPORTED)        tests = arch64a;
        "arch64f":      if (P.F_SUPPORTED)        tests = arch64f;
        "arch64d":      if (P.D_SUPPORTED)        tests = arch64d;  
        "arch64f_fma":  if (P.F_SUPPORTED)        tests = arch64f_fma;
        "arch64d_fma":  if (P.D_SUPPORTED)        tests = arch64d_fma;  
        "arch64f_divsqrt":  if (P.F_SUPPORTED)        tests = arch64f_divsqrt;
        "arch64d_divsqrt":  if (P.D_SUPPORTED)        tests = arch64d_divsqrt;  
        "arch64zifencei":  if (P.ZIFENCEI_SUPPORTED) tests = arch64zifencei;
        "arch64zicond":  if (P.ZICOND_SUPPORTED)  tests = arch64zicond;
        "imperas64i":                             tests = imperas64i;
        "imperas64f":   if (P.F_SUPPORTED)        tests = imperas64f;
        "imperas64d":   if (P.D_SUPPORTED)        tests = imperas64d;
        "imperas64m":   if (P.M_SUPPORTED)        tests = imperas64m;
        "wally64a":     if (P.A_SUPPORTED)        tests = wally64a;
        "imperas64c":   if (P.C_SUPPORTED)        tests = imperas64c;
                        else                      tests = imperas64iNOc;
        "custom":                                 tests = custom;
        "wally64i":                               tests = wally64i; 
        "wally64priv":                            tests = wally64priv;
        "wally64periph":                          tests = wally64periph;
        "coremark":                               tests = coremark;
        "fpga":                                   tests = fpga;
        "ahb64" :                                 tests = ahb64;
        "coverage64gc" :                          tests = coverage64gc;
        "arch64zba":     if (P.ZBA_SUPPORTED)     tests = arch64zba;
        "arch64zbb":     if (P.ZBB_SUPPORTED)     tests = arch64zbb;
        "arch64zbc":     if (P.ZBC_SUPPORTED)     tests = arch64zbc;
        "arch64zbs":     if (P.ZBS_SUPPORTED)     tests = arch64zbs;
        "arch64zicboz":  if (P.ZICBOZ_SUPPORTED)  tests = arch64zicboz;
        "arch64zcb":     if (P.ZCB_SUPPORTED)     tests = arch64zcb;
        "arch64zfh":     if (P.ZFH_SUPPORTED)     tests = arch64zfh;
        "arch64zfh_fma": if (P.ZFH_SUPPORTED)     tests = arch64zfh_fma; 
        "arch64zfh_divsqrt":     if (P.ZFH_SUPPORTED)     tests = arch64zfh_divsqrt;
        "arch64zfaf":    if (P.ZFA_SUPPORTED)     tests = arch64zfaf;
        "arch64zfad":    if (P.ZFA_SUPPORTED & P.D_SUPPORTED)  tests = arch64zfad;
        "buildroot":                              tests = buildroot;
      endcase 
    end else begin // RV32
      case (TEST)
        "arch32e":                                tests = arch32e; 
        "arch32i":                                tests = arch32i;
        "arch32priv":                             tests = arch32priv;
        "arch32c":      if (P.C_SUPPORTED) 
                          if (P.ZICSR_SUPPORTED)  tests = {arch32c, arch32cpriv};
                          else                    tests = {arch32c};
        "arch32m":      if (P.M_SUPPORTED)        tests = arch32m;
        "arch32a":      if (P.A_SUPPORTED)        tests = arch32a;
        "arch32f":      if (P.F_SUPPORTED)        tests = arch32f;
        "arch32d":      if (P.D_SUPPORTED)        tests = arch32d;
        "arch32f_fma":  if (P.F_SUPPORTED)        tests = arch32f_fma;
        "arch32d_fma":  if (P.D_SUPPORTED)        tests = arch32d_fma;
        "arch32f_divsqrt":  if (P.F_SUPPORTED)        tests = arch32f_divsqrt;
        "arch32d_divsqrt":  if (P.D_SUPPORTED)        tests = arch32d_divsqrt;  
        "arch32zifencei":     if (P.ZIFENCEI_SUPPORTED) tests = arch32zifencei;
        "arch32zicond":  if (P.ZICOND_SUPPORTED)  tests = arch32zicond;
        "imperas32i":                             tests = imperas32i;
        "imperas32f":   if (P.F_SUPPORTED)        tests = imperas32f;
        "imperas32m":   if (P.M_SUPPORTED)        tests = imperas32m;
        "wally32a":     if (P.A_SUPPORTED)        tests = wally32a;
        "imperas32c":   if (P.C_SUPPORTED)        tests = imperas32c;
                        else                      tests = imperas32iNOc;
        "wally32i":                               tests = wally32i; 
        "wally32priv":                            tests = wally32priv;
        "wally32periph":                          tests = wally32periph;
        "ahb32" :                                 tests = ahb32;
        "embench":                                tests = embench;
        "coremark":                               tests = coremark;
        "arch32zba":     if (P.ZBA_SUPPORTED)     tests = arch32zba;
        "arch32zbb":     if (P.ZBB_SUPPORTED)     tests = arch32zbb;
        "arch32zbc":     if (P.ZBC_SUPPORTED)     tests = arch32zbc;
        "arch32zbs":     if (P.ZBS_SUPPORTED)     tests = arch32zbs;
        "arch32zicboz":  if (P.ZICBOZ_SUPPORTED)  tests = arch32zicboz;
        "arch32zcb":     if (P.ZCB_SUPPORTED)     tests = arch32zcb;
        "arch32zfh":     if (P.ZFH_SUPPORTED)     tests = arch32zfh;
        "arch32zfh_fma": if (P.ZFH_SUPPORTED)     tests = arch32zfh_fma; 
        "arch32zfh_divsqrt":     if (P.ZFH_SUPPORTED)     tests = arch32zfh_divsqrt;
        "arch32zfaf":    if (P.ZFA_SUPPORTED)     tests = arch32zfaf;
        "arch32zfad":    if (P.ZFA_SUPPORTED & P.D_SUPPORTED)  tests = arch32zfad;
      endcase
    end
    if (tests.size() == 0) begin
      $display("TEST %s not supported in this configuration", TEST);
      $finish;
    end
  end // initial begin

  // Model the testbench as an fsm.
  // Do this in parts so it easier to verify
  // part 1: build a version which echos the same behavior as the below code, but does not drive anything
  // part 2: drive some of the controls
  // part 3: drive all logic and remove old inital and always @ negedge clk block

  typedef enum logic [3:0]{STATE_TESTBENCH_RESET,
                           STATE_INIT_TEST,
                           STATE_RESET_MEMORIES,
                           STATE_RESET_MEMORIES2,
                           STATE_LOAD_MEMORIES,
                           STATE_RESET_TEST,
                           STATE_RUN_TEST,
                           STATE_COPY_RAM,
                           STATE_CHECK_TEST,
                           STATE_CHECK_TEST_WAIT,
                           STATE_VALIDATE,
                           STATE_INCR_TEST} statetype;
  statetype CurrState, NextState;
  logic        TestBenchReset;
  logic [2:0]  ResetCount, ResetThreshold;
  logic        LoadMem;
  logic        ResetCntEn;
  logic        ResetCntRst;
  logic        CopyRAM;

  string  signame, memfilename, bootmemfilename, pathname;
  integer begin_signature_addr, end_signature_addr, signature_size;

  assign ResetThreshold = 3'd5;

  initial begin
    TestBenchReset = 1;
    # 100;
    TestBenchReset = 0;
  end

  always_ff @(posedge clk)
    if (TestBenchReset) CurrState <= #1 STATE_TESTBENCH_RESET;
    else CurrState <= #1 NextState;  

  // fsm next state logic
  always_comb begin
    // riscof tests have a different signature, tests[0] == "1" refers to RiscvArchTests 
    // and tests[0] == "2" refers to WallyRiscvArchTests 
    riscofTest = tests[0] == "1" | tests[0] == "2"; 
    pathname = tvpaths[tests[0].atoi()];

    case(CurrState)
      STATE_TESTBENCH_RESET:                      NextState = STATE_INIT_TEST;
      STATE_INIT_TEST:                            NextState = STATE_RESET_MEMORIES;
      STATE_RESET_MEMORIES:                       NextState = STATE_RESET_MEMORIES2;
      STATE_RESET_MEMORIES2:                      NextState = STATE_LOAD_MEMORIES;  // Give the reset enough time to ensure the bus is reset before loading the memories.
      STATE_LOAD_MEMORIES:                        NextState = STATE_RESET_TEST;
      STATE_RESET_TEST:      if(ResetCount < ResetThreshold) NextState = STATE_RESET_TEST;
                             else                 NextState = STATE_RUN_TEST;
      STATE_RUN_TEST:        if(TestComplete)     NextState = STATE_COPY_RAM;
                             else                 NextState = STATE_RUN_TEST;
      STATE_COPY_RAM:                             NextState = STATE_CHECK_TEST;
      STATE_CHECK_TEST:      if (DCacheFlushDone) NextState = STATE_VALIDATE;
                             else                 NextState = STATE_CHECK_TEST_WAIT;
      STATE_CHECK_TEST_WAIT: if(DCacheFlushDone)  NextState = STATE_VALIDATE;
                             else                 NextState = STATE_CHECK_TEST_WAIT;
      STATE_VALIDATE:                             NextState = STATE_INIT_TEST;
      STATE_INCR_TEST:                            NextState = STATE_INIT_TEST;
      default:                                    NextState = STATE_TESTBENCH_RESET;
    endcase
  end // always_comb
  // fsm output control logic 
  assign reset_ext = CurrState == STATE_TESTBENCH_RESET | CurrState == STATE_INIT_TEST | 
                     CurrState == STATE_RESET_MEMORIES | CurrState == STATE_RESET_MEMORIES2 | 
                     CurrState == STATE_LOAD_MEMORIES | CurrState ==STATE_RESET_TEST;
  // this initialization is very expensive, only do it for coremark.  
  assign ResetMem = (CurrState == STATE_RESET_MEMORIES | CurrState == STATE_RESET_MEMORIES2) & TEST == "coremark";
  assign LoadMem = CurrState == STATE_LOAD_MEMORIES;
  assign ResetCntRst = CurrState == STATE_INIT_TEST;
  assign ResetCntEn = CurrState == STATE_RESET_TEST;
  assign Validate = CurrState == STATE_VALIDATE;
  assign SelectTest = CurrState == STATE_INIT_TEST;
  assign CopyRAM = TestComplete & CurrState == STATE_RUN_TEST;
  assign DCacheFlushStart = CurrState == STATE_COPY_RAM;

  // fsm reset counter
  counter #(3) RstCounter(clk, ResetCntRst, ResetCntEn, ResetCount);

  ////////////////////////////////////////////////////////////////////////////////
  // Find the test vector files and populate the PC to function label converter
  ////////////////////////////////////////////////////////////////////////////////
  logic [P.XLEN-1:0] testadr;
  assign begin_signature_addr = ProgramAddrLabelArray["begin_signature"];
  assign end_signature_addr = ProgramAddrLabelArray["sig_end_canary"];
  assign signature_size = end_signature_addr - begin_signature_addr;
  always @(posedge clk) begin
    if(SelectTest) begin
      if (riscofTest) memfilename = {pathname, tests[test], "/ref/ref.elf.memfile"};
      else if(TEST == "buildroot") begin 
        memfilename = {RISCV_DIR, "/linux-testvectors/ram.bin"};
        bootmemfilename = {RISCV_DIR, "/linux-testvectors/bootmem.bin"};
      end
      else            memfilename = {pathname, tests[test], ".elf.memfile"};
      if (riscofTest) begin
        ProgramAddrMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.addr"};
        ProgramLabelMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.lab"};
      end else if (TEST == "buildroot") begin
        ProgramAddrMapFile = {RISCV_DIR, "/buildroot/output/images/disassembly/vmlinux.objdump.addr"};
        ProgramLabelMapFile = {RISCV_DIR, "/buildroot/output/images/disassembly/vmlinux.objdump.lab"};
      end else begin
        ProgramAddrMapFile = {pathname, tests[test], ".elf.objdump.addr"};
        ProgramLabelMapFile = {pathname, tests[test], ".elf.objdump.lab"};
      end
      // declare memory labels that interest us, the updateProgramAddrLabelArray task will find 
      // the addr of each label and fill the array. To expand, add more elements to this array 
      // and initialize them to zero (also initilaize them to zero at the start of the next test)
      updateProgramAddrLabelArray(ProgramAddrMapFile, ProgramLabelMapFile, ProgramAddrLabelArray);
    end
    
  ////////////////////////////////////////////////////////////////////////////////
  // Verify the test ran correctly by checking the memory against a known signature.
  ////////////////////////////////////////////////////////////////////////////////
    if(TestBenchReset) test = 1;
    if (TEST == "coremark")
      if (dut.core.priv.priv.EcallFaultM) begin
        $display("Benchmark: coremark is done.");
        $finish;
      end
    if(Validate) begin
      if (TEST == "embench") begin
        // Writes contents of begin_signature to .sim.output file
        // this contains instret and cycles for start and end of test run, used by embench 
        // python speed script to calculate embench speed score. 
        // also, begin_signature contains the results of the self checking mechanism, 
        // which will be read by the python script for error checking
        $display("Embench Benchmark: %s is done.", tests[test]);
        if (riscofTest) outputfile = {pathname, tests[test], "/ref/ref.sim.output"};
        else outputfile = {pathname, tests[test], ".sim.output"};
        outputFilePointer = $fopen(outputfile, "w");
        i = 0;
        testadr = ($unsigned(begin_signature_addr))/(P.XLEN/8);
        while ($unsigned(i) < $unsigned(5'd5)) begin
          $fdisplayh(outputFilePointer, DCacheFlushFSM.ShadowRAM[testadr+i]);
          i = i + 1;
        end
        $fclose(outputFilePointer);
        $display("Embench Benchmark: created output file: %s", outputfile);
      end else if (TEST == "coverage64gc") begin
        $display("Coverage tests don't get checked");
      end else begin 
        // for tests with no self checking mechanism, read .signature.output file and compare to check for errors
        // clear signature to prevent contamination from previous tests
        if (!begin_signature_addr)
          $display("begin_signature addr not found in %s", ProgramLabelMapFile);
        else if (TEST != "embench") begin   // *** quick hack for embench.  need a better long term solution
          CheckSignature(pathname, tests[test], riscofTest, begin_signature_addr, errors);
          if(errors > 0) totalerrors = totalerrors + 1;
        end
      end
      test = test + 1; // *** this probably needs to be moved.
      if (test == tests.size()) begin
        if (totalerrors == 0) $display("SUCCESS! All tests ran without failures.");
        else $display("FAIL: %d test programs had errors", totalerrors);
        $finish;
      end
    end
  end


  ////////////////////////////////////////////////////////////////////////////////
  // load memories with program image
  ////////////////////////////////////////////////////////////////////////////////

  integer ShadowIndex;
  integer LogXLEN;
  integer StartIndex;
  integer EndIndex;
  integer BaseIndex;
  integer memFile;
  integer readResult;
  if (P.SDC_SUPPORTED) begin
    always @(posedge clk) begin
      if (LoadMem) begin
        string romfilename, sdcfilename;
        romfilename = {"../tests/custom/fpga-test-sdc/bin/fpga-test-sdc.memfile"};
        sdcfilename = {"../testbench/sdc/ramdisk2.hex"};   
        //$readmemh(romfilename, dut.uncore.uncore.bootrom.bootrom.memory.ROM);
        //$readmemh(sdcfilename, sdcard.sdcard.FLASHmem);
        // shorten sdc timers for simulation
        //dut.uncore.uncore.sdc.SDC.LimitTimers = 1;
      end
    end
  end else if (P.IROM_SUPPORTED) begin
    always @(posedge clk) begin
      if (LoadMem) begin
        $readmemh(memfilename, dut.core.ifu.irom.irom.rom.ROM);
      end
    end
  end else if (P.BUS_SUPPORTED) begin : bus_supported
    always @(posedge clk) begin
      if (LoadMem) begin
        if (TEST == "buildroot") begin
          memFile = $fopen(bootmemfilename, "rb");
          readResult = $fread(dut.uncore.uncore.bootrom.bootrom.memory.ROM, memFile);
          $fclose(memFile);
          memFile = $fopen(memfilename, "rb");
          readResult = $fread(dut.uncore.uncore.ram.ram.memory.RAM, memFile);
          $fclose(memFile);
        end else 
          $readmemh(memfilename, dut.uncore.uncore.ram.ram.memory.RAM);
        if (TEST == "embench") $display("Read memfile %s", memfilename);
      end
      if (CopyRAM) begin
        LogXLEN = (1 + P.XLEN/32); // 2 for rv32 and 3 for rv64
        StartIndex = begin_signature_addr >> LogXLEN;
        EndIndex = (end_signature_addr >> LogXLEN) + 8;
        BaseIndex = P.UNCORE_RAM_BASE >> LogXLEN;
        for(ShadowIndex = StartIndex; ShadowIndex <= EndIndex; ShadowIndex++) begin
          testbench.DCacheFlushFSM.ShadowRAM[ShadowIndex] = dut.uncore.uncore.ram.ram.memory.RAM[ShadowIndex - BaseIndex];
        end
      end
    end
  end 
  if (P.DTIM_SUPPORTED) begin
    always @(posedge clk) begin
      if (LoadMem) begin
        $readmemh(memfilename, dut.core.lsu.dtim.dtim.ram.RAM);
        $display("Read memfile %s", memfilename);
      end
      if (CopyRAM) begin
        LogXLEN = (1 + P.XLEN/32); // 2 for rv32 and 3 for rv64
        StartIndex = begin_signature_addr >> LogXLEN;
        EndIndex = (end_signature_addr >> LogXLEN) + 8;
        BaseIndex = P.UNCORE_RAM_BASE >> LogXLEN;
        for(ShadowIndex = StartIndex; ShadowIndex <= EndIndex; ShadowIndex++) begin
          testbench.DCacheFlushFSM.ShadowRAM[ShadowIndex] = dut.core.lsu.dtim.dtim.ram.RAM[ShadowIndex - BaseIndex];
        end
      end
    end
  end

  integer adrindex;
  if (P.UNCORE_RAM_SUPPORTED)
    always @(posedge clk) 
      if (ResetMem)  // program memory is sometimes reset (e.g. for CoreMark, which needs zeroed memory)
        for (adrindex=0; adrindex<(P.UNCORE_RAM_RANGE>>1+(P.XLEN/32)); adrindex = adrindex+1) 
          dut.uncore.uncore.ram.ram.memory.RAM[adrindex] = '0;

  ////////////////////////////////////////////////////////////////////////////////
  // Actual hardware
  ////////////////////////////////////////////////////////////////////////////////

  // instantiate device to be tested
  assign GPIOIN = 0;
  assign UARTSin = 1;
  assign SPIIn = 0;

  if(P.EXT_MEM_SUPPORTED) begin
    ram_ahb #(.BASE(P.EXT_MEM_BASE), .RANGE(P.EXT_MEM_RANGE)) 
    ram (.HCLK, .HRESETn, .HADDR, .HWRITE, .HTRANS, .HWDATA, .HSELRam(HSELEXT), 
      .HREADRam(HRDATAEXT), .HREADYRam(HREADYEXT), .HRESPRam(HRESPEXT), .HREADY, .HWSTRB);
  end else begin 
    assign HREADYEXT = 1;
    assign {HRESPEXT, HRDATAEXT} = '0;
  end

  if(P.SDC_SUPPORTED) begin : sdcard
    // *** fix later
/* -----\/----- EXCLUDED -----\/-----
    sdModel sdcard
      (.sdClk(SDCCLK),
       .cmd(SDCCmd), 
       .dat(SDCDat));

    assign SDCCmd = SDCCmdOE ? SDCCmdOut : 1'bz;
    assign SDCCmdIn = SDCCmd;
    assign SDCDat = sd_dat_reg_t ? sd_dat_reg_o : sd_dat_i;
    assign SDCDatIn = SDCDat;
 -----/\----- EXCLUDED -----/\----- */
    assign SDCIntr = '0;
  end else begin
    assign SDCIntr = '0;
  end

  wallypipelinedsoc  #(P) dut(.clk, .reset_ext, .reset, .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HSELEXT, .HSELEXTSDC,
    .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
    .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOIN, .GPIOOUT, .GPIOEN,
    .UARTSin, .UARTSout, .SDCIntr, .SPIIn, .SPIOut, .SPICS); 

  // generate clock to sequence tests
  always begin
    clk = 1; # 5; clk = 0; # 5;
  end

  /*
  // Print key info  each cycle for debugging
  always @(posedge clk) begin 
    #2;
    $display("PCM: %x  InstrM: %x (%5s) WriteDataM: %x  IEUResultM: %x",
         dut.core.PCM, dut.core.InstrM, InstrMName, dut.core.WriteDataM, dut.core.ieu.dp.IEUResultM);
  end
  */

  ////////////////////////////////////////////////////////////////////////////////
  // Support logic
  ////////////////////////////////////////////////////////////////////////////////

  // Duplicate copy of pipeline registers that are optimized out of some configurations
  logic [31:0] NextInstrE, InstrM;
  mux2    #(32)     FlushInstrMMux(dut.core.ifu.InstrE, dut.core.ifu.nop, dut.core.ifu.FlushM, NextInstrE);
  flopenr #(32)     InstrMReg(clk, reset, ~dut.core.ifu.StallM, NextInstrE, InstrM);

  // Track names of instructions
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  flopenr #(32)    InstrWReg(clk, reset, ~dut.core.ieu.dp.StallW,  InstrM, InstrW);
  instrTrackerTB it(clk, reset, dut.core.ieu.dp.FlushE,
                dut.core.ifu.InstrRawF[31:0],
                dut.core.ifu.InstrD, dut.core.ifu.InstrE,
                InstrM,  InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // watch for problems such as lockup, reading unitialized memory, bad configs
  watchdog #(P.XLEN, 1000000) watchdog(.clk, .reset);  // check if PCW is stuck
  ramxdetector #(P.XLEN, P.LLEN) ramxdetector(clk, dut.core.lsu.MemRWM[1], dut.core.lsu.LSULoadAccessFaultM, dut.core.lsu.ReadDataM, 
                                      dut.core.ifu.PCM, InstrM, dut.core.lsu.IEUAdrM, InstrMName);
  riscvassertions #(P) riscvassertions();  // check assertions for a legal configuration
  loggers #(P, TEST, PrintHPMCounters, I_CACHE_ADDR_LOGGER, D_CACHE_ADDR_LOGGER, BPRED_LOGGER)
  loggers (clk, reset, DCacheFlushStart, DCacheFlushDone, memfilename);

  // track the current function or global label
  if (DEBUG == 1 | ((PrintHPMCounters | BPRED_LOGGER) & P.ZICNTR_SUPPORTED)) begin : FunctionName
    FunctionName #(P) FunctionName(.reset(reset_ext | TestBenchReset),
			      .clk(clk), .ProgramAddrMapFile(ProgramAddrMapFile), .ProgramLabelMapFile(ProgramLabelMapFile));
  end


  // Termination condition
  // terminate on a specific ECALL after li x3,1 for old Imperas tests,  *** remove this when old imperas tests are removed
  // or sw	gp,-56(t0) for new Imperas tests
  // or sd gp, -56(t0) 
  // or on a jump to self infinite loop (6f) for RISC-V Arch tests
  logic ecf; // remove this once we don't rely on old Imperas tests with Ecalls
  if (P.ZICSR_SUPPORTED) assign ecf = dut.core.priv.priv.EcallFaultM;
  else                  assign ecf = 0;
  assign TestComplete = ecf & 
			    (dut.core.ieu.dp.regf.rf[3] == 1 | 
			     (dut.core.ieu.dp.regf.we3 & 
			      dut.core.ieu.dp.regf.a3 == 3 & 
			      dut.core.ieu.dp.regf.wd3 == 1)) |
           ((InstrM == 32'h6f | InstrM == 32'hfc32a423 | InstrM == 32'hfc32a823) & dut.core.ieu.c.InstrValidM ) |
           ((dut.core.lsu.IEUAdrM == ProgramAddrLabelArray["tohost"]) & InstrMName == "SW" );
  //assign DCacheFlushStart =  TestComplete;
  
  DCacheFlushFSM #(P) DCacheFlushFSM(.clk(clk), .reset(reset), .start(DCacheFlushStart), .done(DCacheFlushDone));

  if(P.ZICSR_SUPPORTED) begin
    logic [P.XLEN-1:0] Minstret;
    assign Minstret = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2];  
    always @(negedge clk) begin
      if((Minstret != 0) && (Minstret % 'd100000 == 0)) $display("Reached %d instructions, %d", Minstret, INSTR_LIMIT);
      if((Minstret == INSTR_LIMIT) & (INSTR_LIMIT!=0)) begin $stop; $stop; end
    end
  end

  task automatic CheckSignature;
    // This task must be declared inside this module as it needs access to parameter P.  There is
    // no way to pass P to the task unless we convert it to a module.
    
    input string  pathname;
    input string  TestName;
    input logic   riscofTest;
    input integer begin_signature_addr;
    output integer errors;
    int fd, code;
    string line;
    int siglines, sigentries;

    localparam SIGNATURESIZE = 5000000;
    integer        i;
    logic [31:0]   sig32[0:SIGNATURESIZE];
    logic [31:0]   parsed;
    logic [P.XLEN-1:0] signature[0:SIGNATURESIZE];
    string            signame;
    logic [P.XLEN-1:0] testadr, testadrNoBase;
    
    // read .signature.output file and compare to check for errors
    if (riscofTest) signame = {pathname, TestName, "/ref/Reference-sail_c_simulator.signature"};
    else signame = {pathname, TestName, ".signature.output"};

    // read signature file from memory and count lines.  Can't use readmemh because we need the line count
    // $readmemh(signame, sig32);
    fd = $fopen(signame, "r");
    siglines = 0;
    if (fd == 0) $display("Unable to read %s", signame);
    else begin
      while (!$feof(fd)) begin
        code = $fgets(line, fd);
        if (code != 0) begin
          int errno;
          string errstr;
          errno = $ferror(fd, errstr);
          if (errno != 0) $display("Error %d (code %d) reading line %d of %s: %s", errno, code, siglines, signame, errstr);
          if (line.len() > 1) begin // skip blank lines
            if ($sscanf(line, "%x", parsed) != 0) begin
              sig32[siglines] = parsed;
              siglines = siglines + 1; // increment if line is not blank
            end
          end
        end
      end
      $fclose(fd);
    end

    // Check valid number of lines were read
    if (siglines == 0) begin  
      errors = 1; 
      $display("Error: empty test file %s", signame);
    end else if (P.XLEN == 64 & (siglines % 2)) begin
      errors = 1;
      $display("Error: RV64 signature has odd number of lines %s", signame);
    end else errors = 0;

    // copy lines into signature, converting to XLEN if necessary
    sigentries = (P.XLEN == 32) ? siglines : siglines/2; // number of signature entries
    for (i=0; i<sigentries; i++) begin
      signature[i] = (P.XLEN == 32) ? sig32[i] : {sig32[i*2+1], sig32[i*2]};
      //$display("XLEN = %d signature[%d] = %x", P.XLEN, i, signature[i]);
    end

    // Check errors
    testadr = ($unsigned(begin_signature_addr))/(P.XLEN/8);
    testadrNoBase = (begin_signature_addr - P.UNCORE_RAM_BASE)/(P.XLEN/8);
    for (i=0; i<sigentries; i++) begin
      logic [P.XLEN-1:0] sig;
      // **************************************
      // ***** BUG BUG BUG make sure RT undoes this.
      //if (P.DTIM_SUPPORTED) sig = testbench.dut.core.lsu.dtim.dtim.ram.RAM[testadrNoBase+i];
      //else if (P.UNCORE_RAM_SUPPORTED) sig = testbench.dut.uncore.uncore.ram.ram.memory.RAM[testadrNoBase+i];
      if (P.UNCORE_RAM_SUPPORTED) sig = testbench.dut.uncore.uncore.ram.ram.memory.RAM[testadrNoBase+i];
      //if (P.UNCORE_RAM_SUPPORTED) sig = testbench.dut.uncore.uncore.ram.ram.memory.RAM[testadrNoBase+i];
      //$display("signature[%h] = %h sig = %h", i, signature[i], sig);
      //if (signature[i] !== sig & (signature[i] !== testbench.DCacheFlushFSM.ShadowRAM[testadr+i])) begin
      if (signature[i] !== testbench.DCacheFlushFSM.ShadowRAM[testadr+i]) begin  
        errors = errors+1;
        $display("  Error on test %s result %d: adr = %h sim (D$) %h sim (DTIM_SUPPORTED) = %h, signature = %h", 
			     TestName, i, (testadr+i)*(P.XLEN/8), testbench.DCacheFlushFSM.ShadowRAM[testadr+i], sig, signature[i]);
        $finish;
      end
    end
    if (errors) $display("%s failed with %d errors. :(", TestName, errors);
    else $display("%s succeeded.  Brilliant!!!", TestName);
  endtask
  
  /* verilator lint_on WIDTHTRUNC */
  /* verilator lint_on WIDTHEXPAND */

endmodule

/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

task automatic updateProgramAddrLabelArray;
  /* verilator lint_off WIDTHTRUNC */
  /* verilator lint_off WIDTHEXPAND */
  input string ProgramAddrMapFile, ProgramLabelMapFile;
  inout  integer ProgramAddrLabelArray [string];
  // Gets the memory location of begin_signature
  integer ProgramLabelMapFP, ProgramAddrMapFP;

  ProgramLabelMapFP = $fopen(ProgramLabelMapFile, "r");
  ProgramAddrMapFP = $fopen(ProgramAddrMapFile, "r");

  if (ProgramLabelMapFP & ProgramAddrMapFP) begin // check we found both files
    ProgramAddrLabelArray["begin_signature"] = 0;
    ProgramAddrLabelArray["tohost"] = 0;
    ProgramAddrLabelArray["sig_end_canary"] = 0;
    while (!$feof(ProgramLabelMapFP)) begin
      string label, adrstr;
      integer returncode;
      returncode = $fscanf(ProgramLabelMapFP, "%s\n", label);
      returncode = $fscanf(ProgramAddrMapFP, "%s\n", adrstr);
      if (ProgramAddrLabelArray.exists(label)) ProgramAddrLabelArray[label] = adrstr.atohex();
    end
  end

//  if(ProgramAddrLabelArray["begin_signature"] == 0) $display("Couldn't find begin_signature in %s", ProgramLabelMapFile);
//  if(ProgramAddrLabelArray["sig_end_canary"] == 0) $display("Couldn't find sig_end_canary in %s", ProgramLabelMapFile);

  $fclose(ProgramLabelMapFP);
  $fclose(ProgramAddrMapFP);
  /* verilator lint_on WIDTHTRUNC */
  /* verilator lint_on WIDTHEXPAND */
endtask

