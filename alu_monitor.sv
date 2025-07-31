//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_monitor;
	alu_transaction mon_trans;
	mailbox #(alu_transaction) mbx_ms; //monitor to scoreboard
	//virtual interface with monitor modport and its instance
	virtual alu_if.MON vif;

	//Functional coverage for outputs
	covergroup mon_cg;
		ERR: coverpoint mon_trans.ERR {bins err = {0,1};}
		OFLOW: coverpoint mon_trans.OFLOW {bins oflow = {0,1};}
		COUT: coverpoint mon_trans.COUT {bins cout = {0,1};}
		G: coverpoint mon_trans.G {bins g = {0,1};}
		L: coverpoint mon_trans.L {bins l = {0,1};}
		E: coverpoint mon_trans.E {bins e = {0,1};}
		RES: coverpoint mon_trans.RES {bins res = {[0:(`DATA_WIDTH-1)]};}
	endgroup

	//constructor
	function new(virtual alu_if.MON vif, mailbox #(alu_transaction)mbx_ms);
		this.vif = vif;
		this.mbx_ms = mbx_ms;

		//object for covergroup
		mon_cg = new();
	endfunction

	//check if cmd requires 2 or 1 operand
	function bit needs_2_op(logic [3:0] CMD, logic MODE);
		if(MODE == 1)begin
			$display("needs 2 op");
			return (CMD inside {4'd0, 4'd1, 4'd2, 4'd3, 4'd8, 4'd9, 4'd10});
		end else begin
			$display("needs 2 op");
			return (CMD inside {4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd12, 4'd13});
		end
	endfunction

	//delay based on commands
	function int get_output_delay(logic [3:0] CMD,logic MODE);
		if(CMD inside {4'd9,4'd10} && MODE == 1) begin
			$display("delay 3");
			return 3;
		end else begin
			$display("delay 1");
			return 1;
		end
	endfunction

	//task to collect output from interface
	task start();
		int delay, count;
		repeat(4) @(vif.mon_cb);

		$display("[%0t] Monitor Start\n",$time);

		for(int i = 0; i < `NO_OF_TRANS; i++ )begin

			//wait for 2nd inp if needed
			if (needs_2_op(vif.mon_cb.CMD, vif.mon_cb.MODE) && vif.mon_cb.INP_VALID != 2'b11) begin
				while (vif.mon_cb.INP_VALID != 2'b11 && count < 16) begin
					@(vif.mon_cb);
					count++;
				end
			end

			delay = get_output_delay(vif.mon_cb.CMD,vif.mon_cb.MODE);
			//repeat(1) @(vif.mon_cb); //wait 1 or 3 cycles based on cmd for output to become valid 

			mon_trans = new();
			@(vif.mon_cb);
      // Capture inputs
      mon_trans.CE        = vif.mon_cb.CE;
      mon_trans.INP_VALID = vif.mon_cb.INP_VALID;
      mon_trans.MODE      = vif.mon_cb.MODE;
      mon_trans.CMD       = vif.mon_cb.CMD;
      mon_trans.OPA       = vif.mon_cb.OPA;
      mon_trans.OPB       = vif.mon_cb.OPB;
      mon_trans.CIN       = vif.mon_cb.CIN;
			//Capture outputs 
			mon_trans.RES   = vif.mon_cb.RES;
			mon_trans.COUT  = vif.mon_cb.COUT;
			mon_trans.OFLOW = vif.mon_cb.OFLOW;
			mon_trans.ERR   = vif.mon_cb.ERR;
			mon_trans.G     = vif.mon_cb.G;
			mon_trans.L     = vif.mon_cb.L;
			mon_trans.E     = vif.mon_cb.E;
		
			
			$display("[%0t] ---------- ALU MONITOR ----------\n",$time);
			$display("Input signals\n");

			$display("CE = %0d, IP_VALID = %0d, MODE = %0d, CMD = %0d, OPA = %0d, OPB = %0d, CIN = %0d",mon_trans.CE,
											  mon_trans.INP_VALID,mon_trans.MODE,mon_trans.CMD,mon_trans.OPA,mon_trans.OPB,mon_trans.CIN);
			$display("Output signals\n");
			$display("RES = %0d, COUT = %b, OFLOW = %b, ERR = %b, G = %b, L = %b, E = %b\n",mon_trans.RES, 
												mon_trans.COUT, mon_trans.OFLOW,mon_trans.ERR, mon_trans.G, mon_trans.L, mon_trans.E);
			
			//send to scoreboard
			mbx_ms.put(mon_trans);
			mon_cg.sample();
			repeat(1)@(vif.mon_cb);

			$display("MONITOR: Output functional coverage = %0.2f%%", mon_cg.get_coverage());
		end
	endtask
endclass
