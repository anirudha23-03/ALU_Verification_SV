//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_driver;
	alu_transaction drv_trans;
	mailbox #(alu_transaction)mbx_gd; //genetator to driver
	mailbox #(alu_transaction)mbx_dr; //driver to reference model
	//virtual interface with driver modport and it's instance
	virtual alu_if.DRV vif;

	//functional coverage for inputs
	covergroup drv_cg;
		OPA : coverpoint drv_trans.OPA { bins opa = {[0:`DATA_WIDTH-1]};}
		OPB : coverpoint drv_trans.OPB { bins opb = {[0:`DATA_WIDTH-1]};}
		CIN : coverpoint drv_trans.CE { bins cin = {0,1};}
		INP_VALID : coverpoint drv_trans.INP_VALID {bins ip_valid[] = {2'b00, 2'b01, 2'b10, 2'b11};}
		CMD : coverpoint drv_trans.CMD { bins command[] = {[0:15]};}
		MODE : coverpoint drv_trans.MODE { bins mode[] = {0,1};}
		CE : coverpoint drv_trans.CE { bins ce[] = {0,1};}
	endgroup

	//constrctor 
	function new(mailbox #(alu_transaction)mbx_gd,mailbox #(alu_transaction)mbx_dr, virtual alu_if.DRV vif);
		this.mbx_gd = mbx_gd;
		this.mbx_dr = mbx_dr;
		this.vif = vif;
		//create object for covergroup
		drv_cg = new();
	endfunction

	//function to check if cmd needs 2 operands
	function bit needs_2_op(logic [3:0] CMD, logic MODE);
		if(MODE == 1)begin
			return (CMD inside {4'd0,4'd1,4'd2,4'd3,4'd8,4'd9,4'd10});
		end else begin
			return (CMD inside {4'd0,4'd1,4'd2,4'd3,4'd4,4'd5,4'd12,4'd13});
		end
	endfunction

	//task to drive stimuli to interface
	task start();
		
		int c = 0;

		$display("[%0t] Driver Start", $time);
		repeat(1)@(vif.drv_cb);
		$display("[%0t] before loop",$time);

		for(int i = 0; i < `NO_OF_TRANS; i++) begin
			drv_trans = new();
			mbx_gd.get(drv_trans);

			$display("[%0t] ---------- ALU DRIVER----------\n",$time);
			$display("[%0t] CE = %0d, MODE = %0d, INP_VALID = %0d, CMD = %0d, OPA = %0d, OPB = %0d, CIN = %0d\n", $time, drv_trans.CE, 
					         drv_trans.MODE, drv_trans.INP_VALID, drv_trans.CMD,drv_trans.OPA, drv_trans.OPB, drv_trans.CIN);
			
			if(vif.rst == 0) begin 
				vif.drv_cb.CE        <= drv_trans.CE;
				vif.drv_cb.MODE      <= drv_trans.MODE;
        vif.drv_cb.CMD       <= drv_trans.CMD;
        vif.drv_cb.CIN       <= drv_trans.CIN;
        vif.drv_cb.OPA       <= drv_trans.OPA;
        vif.drv_cb.OPB       <= drv_trans.OPB;
        vif.drv_cb.INP_VALID <= drv_trans.INP_VALID;

				if(needs_2_op(drv_trans.CMD, drv_trans.MODE) && drv_trans.INP_VALID != 2'b11) begin
					//wait up to 16 cycles 
					while (vif.INP_VALID != 2'b11 && c < 16) begin
						@(vif.drv_cb);
						c++;

						//checking mailbox for updated inputs
						if (mbx_gd.num()>0) begin
							alu_transaction upd_trans;
							mbx_gd.get(upd_trans);

							//drives updated latest values into DUT
							vif.drv_cb.OPA <= upd_trans.OPA;
							vif.drv_cb.OPB <= upd_trans.OPB;
							
							//update in transaction local copy
							drv_trans.OPA = upd_trans.OPA;
							drv_trans.OPB = upd_trans.OPB;

							//update inp_valid to 11
							vif.drv_cb.INP_VALID <= 2'b11;
							drv_trans.INP_VALID = 2'b11;
						end
					end
				end

				@(vif.drv_cb); //ALU to latch inputs

				//send to reference model
				mbx_dr.put(drv_trans);
				drv_cg.sample();

			end else begin
        // During reset
        vif.drv_cb.CE        <= 0;
        vif.drv_cb.OPA       <= 0;
        vif.drv_cb.OPB       <= 0;
        vif.drv_cb.INP_VALID <= 0;
        vif.drv_cb.CMD       <= 0;
        vif.drv_cb.CIN       <= 0;
        vif.drv_cb.MODE      <= 0;
        $display("[%0t] ALU DRIVER: DUT is in reset\n", $time);
      repeat(1)@(vif.drv_cb);
      end

 //     repeat(1)@(vif.drv_cb);
    end

    $display("ALU DRIVER: Input Coverage = %0.2f%%\n", drv_cg.get_coverage());
  endtask
endclass
