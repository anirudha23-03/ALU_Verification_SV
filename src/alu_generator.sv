//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_generator;
	alu_transaction blueprint;
	mailbox #(alu_transaction)mbx_gd; //mailbox for generator to driver
	
	function new(mailbox#(alu_transaction)mbx_gd);
		this.mbx_gd = mbx_gd;
		blueprint = new();
	endfunction

	//random stimulus generation
	task start();
		for(int i = 0; i < `NO_OF_TRANS; i++) 
			begin
				void'(blueprint.randomize());
				mbx_gd.put(blueprint.copy());
				$display("GENERATOR Randomized transaction: %d\n",i);
				$display("[%0t] CE = %0d, INP_VALID = %0d, MODE = %0d, CMD = %0d, OPA = %0d, OPB = %0d, CIN = %0d\n",$time,blueprint.CE,blueprint.INP_VALID,blueprint.MODE,blueprint.CMD, blueprint.OPA,blueprint.OPB,blueprint.CIN);
			end
		$display("******************** GENERATOR COMPLETED ********************\n");
	endtask
endclass


