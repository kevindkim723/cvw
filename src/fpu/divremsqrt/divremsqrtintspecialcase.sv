module divremsqrtintspecialcase import cvw::*; #(parameter cvw_t P) (
    input logic BZeroM,RemOpM, ALTBM,
    input logic [P.XLEN-1:0] AM,BM,
    input  signed [P.INTDIVb+3:0] PreIntResultM,
    output logic [P.XLEN-1:0] IntDivResultM
);
   logic intoverflow;
   assign intoverflow = AM == {{1'b1},{P.XLEN-1{1'b0}}} && &BM;
always_comb
     if (BZeroM) begin         // Divide by zero
        if (RemOpM) IntDivResultM = AM;  
        else        IntDivResultM = {(P.XLEN){1'b1}};
     end else if (ALTBM) begin // Numerator is small
        if (RemOpM) IntDivResultM = AM;
        else        IntDivResultM = 0;
     end else if (intoverflow) begin
                    IntDivResultM = (RemOpM) ? 0 : AM;
     end else       IntDivResultM = PreIntResultM[P.XLEN-1:0];
endmodule