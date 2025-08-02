`timescale 1ns/1ns

`include "alu_pkg.sv"
`include "alu_interface.sv"
`include "alu_design.sv"
/*
`include "defines.sv"
`include "alu_interface.sv"
`include "alu_design.sv"
`include "alu_transaction.sv"
`include "alu_generator.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"
`include "alu_reference_model.sv"
`include "alu_scb.sv"
`include "alu_environment.sv"
`include "alu_test.sv"
*/

module top();

  // Import all classes/types from package
  import alu_pkg::*;

  // Clock and Reset
  bit clk;
  bit rst;

  // Clock Generation
  //initial clk = 0;
  always #5 clk = ~clk;

  // Reset Sequence
  initial begin
    rst = 1;
    @(posedge clk);
    rst = 0;
  end

  // Interface instantiation
  alu_if intf(clk, rst);

  // ALU Design Under Verification (DUV)
  alu_design DUV (
    .OPA(intf.OPA),
    .OPB(intf.OPB),
		.INP_VALID(intf.INP_VALID),
		.CE(intf.CE),
		.MODE(intf.MODE),
		.CIN(intf.CIN),
    .CMD(intf.CMD),
    .RES(intf.RES),
    .COUT(intf.COUT),
    .OFLOW(intf.OFLOW),
		.G(intf.G),
		.E(intf.E),
		.L(intf.L),
		.ERR(intf.ERR),
    .CLK(clk),
    .RST(rst)
  );

  // Test class instantiation
  alu_test test = new(intf.DRV, intf.MON, intf.REF_SB);
	test1 t1 = new(intf.DRV, intf.MON, intf.REF_SB);
	test2 t2 = new(intf.DRV, intf.MON, intf.REF_SB);
	test3 t3 = new(intf.DRV, intf.MON, intf.REF_SB);
	test4 t4 = new(intf.DRV, intf.MON, intf.REF_SB);
	test_regression rt = new(intf.DRV, intf.MON, intf.REF_SB);

  // Start test
  initial begin
    rt.run();
    $finish;
  end

endmodule

