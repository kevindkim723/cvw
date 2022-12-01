///////////////////////////////////////////
// intdivrestoring.sv
//
// Written: David_Harris@hmc.edu 12 September 2021
// Modified: 
//
// Purpose: Restoring integer division using a shift register and subtractor
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

  /* verilator lint_off UNOPTFLAT */

module intdivrestoring (
  input  logic clk,
  input  logic reset,
  input  logic StallM,
  input  logic TrapM,
  input  logic DivSignedE, W64E,
  input  logic DivE,
  //input logic [`XLEN-1:0] 	SrcAE, SrcBE,
	input logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  output logic DivBusyE, 
  output logic [`XLEN-1:0] QuotM, RemM
 );

  typedef enum logic [1:0] {IDLE, BUSY, DONE} statetype;
  statetype state;

  logic [`XLEN-1:0] W[`DIV_BITSPERCYCLE:0];
  logic [`XLEN-1:0] XQ[`DIV_BITSPERCYCLE:0];
  logic [`XLEN-1:0] DinE, XinE, DnE, DAbsBE, DAbsB, XnE, XInitE, WnM, XQnM;
  localparam STEPBITS = $clog2(`XLEN/`DIV_BITSPERCYCLE);
  logic [STEPBITS:0] step;
  logic Div0E, Div0M;
  logic DivStartE, SignXE, SignDE, NegQE, NegWM, NegQM;
  logic [`XLEN-1:0] WNext, XQNext;
 
  //////////////////////////////
  // Execute Stage: prepare for division calculation with control logic, W logic and absolute values, initialize W and XQ
  //////////////////////////////

  // Divider control signals
  assign DivStartE = DivE & (state == IDLE) & ~StallM; 
  assign DivBusyE = (state == BUSY) | DivStartE;

  // Handle sign extension for W-type instructions
  if (`XLEN == 64) begin:rv64 // RV64 has W-type instructions
    mux2 #(`XLEN) xinmux(ForwardedSrcAE, {ForwardedSrcAE[31:0], 32'b0}, W64E, XinE);
    mux2 #(`XLEN) dinmux(ForwardedSrcBE, {{32{ForwardedSrcBE[31]&DivSignedE}}, ForwardedSrcBE[31:0]}, W64E, DinE);
  end else begin // RV32 has no W-type instructions
    assign XinE = ForwardedSrcAE;
    assign DinE = ForwardedSrcBE;	    
    end   

  // Extract sign bits and check fo division by zero
  assign SignDE = DivSignedE & DinE[`XLEN-1]; 
  assign SignXE = DivSignedE & XinE[`XLEN-1];
  assign NegQE = SignDE ^ SignXE;
  assign Div0E = (DinE == 0);

  // Take absolute value for signed operations, and negate D to handle subtraction in divider stages
  neg #(`XLEN) negd(DinE, DnE);
  mux2 #(`XLEN) dabsmux(DnE, DinE, SignDE, DAbsBE);  // take absolute value for signed operations, and negate for subtraction setp
  neg #(`XLEN) negx(XinE, XnE);
  mux3 #(`XLEN) xabsmux(XinE, XnE, ForwardedSrcAE, {Div0E, SignXE}, XInitE);  // take absolute value for signed operations, or keep original value for divide by 0

  //////////////////////////////
  // Division Iterations (effectively stalled execute stage, no suffix)
  //////////////////////////////

  // initialization multiplexers on first cycle of operation
  mux2 #(`XLEN) wmux(W[`DIV_BITSPERCYCLE], {`XLEN{1'b0}}, DivStartE, WNext);
  mux2 #(`XLEN) xmux(XQ[`DIV_BITSPERCYCLE], XInitE, DivStartE, XQNext);

  // registers before division steps
  flopen #(`XLEN) wreg(clk, DivBusyE, WNext, W[0]); 
  flopen #(`XLEN) xreg(clk, DivBusyE, XQNext, XQ[0]);
  flopen #(`XLEN) dabsreg(clk, DivStartE, DAbsBE, DAbsB);

  // one copy of divstep for each bit produced per cycle
  genvar i;
  for (i=0; i<`DIV_BITSPERCYCLE; i = i+1)
    intdivrestoringstep divstep(W[i], XQ[i], DAbsB, W[i+1], XQ[i+1]);

  //////////////////////////////
  // Memory Stage: output sign correction and special cases
  //////////////////////////////

  flopen #(3) Div0eMReg(clk, DivStartE, {Div0E, NegQE, SignXE}, {Div0M, NegQM, NegWM});
  
  // On final setp of signed operations, negate outputs as needed to get correct sign
  neg #(`XLEN) qneg(XQ[0], XQnM);
  neg #(`XLEN) wneg(W[0], WnM);
  // Select appropriate output: normal, negated, or for divide by zero
  mux3 #(`XLEN) qmux(XQ[0], XQnM, {`XLEN{1'b1}}, {Div0M, NegQM}, QuotM); // Q taken from XQ register, negated if necessary, or all 1s when dividing by zero
  mux3 #(`XLEN) remmux(W[0], WnM, XQ[0], {Div0M, NegWM}, RemM); // REM taken from W register, negated if necessary, or from X when dividing by zero

  //////////////////////////////
  // Divider FSM to sequence Busy and Done
  //////////////////////////////

 always_ff @(posedge clk) 
    if (reset | TrapM) begin
        state <= IDLE; 
    end else if (DivStartE) begin 
        step <= 1;
        if (Div0E) state <= DONE;
        else       state <= BUSY;
     end else if (state == BUSY) begin // pause one cycle at beginning of signed operations for absolute value
        if (step[STEPBITS] | (`XLEN==64) & W64E & step[STEPBITS-1]) begin // complete in half the time for W-type instructions
            state <= DONE;
        end
        step <= step + 1;
    end else if (state == DONE) begin
      if (StallM) state <= DONE;
      else        state <= IDLE;
    end 
endmodule 

/* verilator lint_on UNOPTFLAT */
