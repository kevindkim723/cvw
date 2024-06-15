///////////////////////////////////////////
// fdivsqrtuslc2.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu 
// Modified:13 January 2022
//
// Purpose: Radix 2 Unified Quotient/Square Root Digit Selection
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// httWS://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module fdivsqrtuslc2kevin ( 
  input  logic [3:0] WS, WC,      // Q4.0 most significant bits of redundant residual
  input logic ws5,wc5,
  output logic       up, uz, un   // {+1, 0, -1}
);
 
  logic        sign;
  logic        [3:0] sum;
  logic        special;

  // Carry chain logic determines if W = WS + WC = -1, < -1, > -1 to choose 0, -1, 1 respectively
 
  

  // Otherwise determine sign using carry chain: sign = p3 ^ g_2:0
  
  assign sum = (WS + WC);
  assign sign = sum[3];
  assign special = |sum | ws5 | wc5;

//if p2 * p1 * p0, W = -1 and choose digit of 0
  assign uz = (sum==4'b1111) | ~special;
  
  

  // Produce digit = +1, 0, or -1
  assign up = ~uz & ~sign;
  assign un = ~uz & sign;
endmodule
