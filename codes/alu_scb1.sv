//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_scb;
	//alu transaction class handles
	alu_transaction ref2sb_trans,mon2sb_trans;
	mailbox #(alu_transaction) mbx_rs; //ref_mod to scb mailbox
	mailbox #(alu_transaction) mbx_ms; //monitor to scb mailbox

	//associative arrays used for storing data_out (from ref_model, expected result) wrt address in ref model memory and storing data_out (from DUV, actual result) wrt address in monitor memory
	alu_transaction ref_mem [bit[`NO_OF_TRANS:0]];
	alu_transaction mon_mem [bit[`NO_OF_TRANS:0]];

	int MATCH,MISMATCH;

	//constructor to make mailbox connections
	function new(mailbox #(alu_transaction) mbx_rs, mailbox #(alu_transaction) mbx_ms);
		this.mbx_rs = mbx_rs;
		this.mbx_ms = mbx_ms;
	endfunction

	//task to collect data out from ref model and store in mem
	task start();
		for(int i = 0; i < `NO_OF_TRANS; i++)
			begin
				ref2sb_trans = new();
				mon2sb_trans = new();

				mbx_rs.get(ref2sb_trans);
				mbx_ms.get(mon2sb_trans);

				//store each transaction using index i
				ref_mem[i] = ref2sb_trans;
				mon_mem[i] = mon2sb_trans;

				 $display("[%0t] ----------------------- SCOREBOARD ---------------------------\n",$time);
				 $display("### REF[%0d] => RES=%0h, CMD=%0d, OPA=%0d, OPB=%0d\n",
					               i, ref2sb_trans.RES, ref2sb_trans.CMD, ref2sb_trans.OPA, ref2sb_trans.OPB);

				 $display("### MON[%0d] => RES=%0h, CMD=%0d, OPA=%0d, OPB=%0d\n",
							              i, mon2sb_trans.RES, mon2sb_trans.CMD, mon2sb_trans.OPA, mon2sb_trans.OPB);
				compare_results(i);
			end
	endtask
  
	task compare_results(input int index);
  	if (ref_mem.exists(index) && mon_mem.exists(index)) begin
    	if (ref_mem[index].RES === mon_mem[index].RES) begin
      	$display("PASS: Transaction[%0d] RES match => %0h\n", index, ref_mem[index].RES);
      	MATCH++;
    	end else begin
      	$display("FAIL: Transaction[%0d] RES mismatch => REF=%0h, MON=%0h\n",
               index, ref_mem[index].RES, mon_mem[index].RES);
      	MISMATCH++;
    	end
  	end else begin
    $display("MISSING: Transaction[%0d] not found in memory\n", index);
  end
endtask

endclass
