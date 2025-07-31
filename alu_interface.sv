//`include "defines.sv"

interface alu_if(input bit clk, input bit rst);
    // input signals
    logic CE, MODE;
    logic [`DATA_WIDTH-1:0] OPA, OPB;
    logic [1:0] INP_VALID;
    logic [3:0] CMD;
    logic CIN;

    // output signals
    wire ERR, OFLOW, COUT, G, L, E;
    wire [`DATA_WIDTH+1:0] RES;

    // driver clocking block
    clocking drv_cb @(posedge clk);
        output CE, MODE, OPA, OPB, INP_VALID, CMD, CIN;
        input rst;
    endclocking

    // monitor clocking block
    clocking mon_cb @(posedge clk);
        input CE, MODE, OPA, OPB, INP_VALID, CMD, CIN;
        input ERR, OFLOW, COUT, G, L, E, RES;
    endclocking

    // reference model clocking block
    clocking ref_cb @(posedge clk);
			 input CE, MODE, OPA, OPB, INP_VALID, CMD, CIN, rst;
//        output ERR, OFLOW, COUT, G, L, E, RES;
    endclocking

    // modports
    modport DRV(clocking drv_cb, input rst,INP_VALID);
    modport MON(clocking mon_cb);
    modport REF_SB(clocking ref_cb, input rst,INP_VALID);   

endinterface

