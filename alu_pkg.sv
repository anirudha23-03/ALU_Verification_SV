// This package includes all the files in the ALU testbench architecture
// which will be imported in the top module

package alu_pkg;
	`include "defines.sv"
  `include "alu_transaction.sv"
  `include "alu_generator.sv"
  `include "alu_driver.sv"
  `include "alu_monitor.sv"
  `include "alu_reference_model.sv"
  `include "alu_scb.sv"
  `include "alu_environment.sv"
  `include "alu_test.sv"

endpackage

