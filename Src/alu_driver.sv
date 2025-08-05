//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_driver;
        alu_transaction drv_trans;
        mailbox #(alu_transaction)mbx_gd; //generator to driver
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
								MODExINP_VALID: cross MODE,INP_VALID;
							  MODExCMD: cross MODE, CMD;
					      CMDxINP_VALID: cross CMD, INP_VALID;
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
				
				function int get_output_delay(logic [3:0] CMD,logic MODE);
					     if(CMD inside {4'd9,4'd10} && MODE == 1) begin
						       return 4;
						   end else begin
							     return 3;
							 end
			  endfunction

        //task to drive stimuli to interface
				task start();
					int delay,c ;
					
					repeat(1)@(vif.drv_cb);

					for(int i = 0; i < `NO_OF_TRANS; i++) begin
						c = 0;
						delay = get_output_delay(vif.drv_cb.CMD,vif.drv_cb.MODE);

						drv_trans = new();
						mbx_gd.get(drv_trans);

						$display("[%0t] ---------- ALU DRIVER----------\n", $time);
						$display("[%0t] CE = %0d, MODE = %0d, INP_VALID = %0d, CMD = %0d, OPA = %0d, OPB = %0d, CIN = %0d\n",$time, drv_trans.CE, drv_trans.MODE, drv_trans.INP_VALID, drv_trans.CMD, drv_trans.OPA, drv_trans.OPB, drv_trans.CIN);

						if(vif.rst == 0) begin
							vif.drv_cb.CE        <= drv_trans.CE;
							vif.drv_cb.MODE      <= drv_trans.MODE;
							vif.drv_cb.CMD       <= drv_trans.CMD;
							vif.drv_cb.CIN       <= drv_trans.CIN;
							vif.drv_cb.OPA       <= drv_trans.OPA;
							vif.drv_cb.OPB       <= drv_trans.OPB;
							vif.drv_cb.INP_VALID <= drv_trans.INP_VALID;

							// Re-randomize until INP_VALID becomes 2'b11 (for dual operand ops)
							if (needs_2_op(drv_trans.CMD, drv_trans.MODE) && drv_trans.INP_VALID != 2'b11) begin

								drv_trans.CMD.rand_mode(0);
								drv_trans.CE.rand_mode(0);
								drv_trans.MODE.rand_mode(0);
								
								while (drv_trans.INP_VALID != 2'b11 && c < 16) begin

									@(vif.drv_cb);
									c++;

									if (!drv_trans.randomize()) begin
										$error("[%0t] ALU DRIVER: Randomization failed", $time);
									end

									vif.drv_cb.OPA       <= drv_trans.OPA;
									vif.drv_cb.OPB       <= drv_trans.OPB;
									vif.drv_cb.INP_VALID <= drv_trans.INP_VALID;
									vif.drv_cb.CIN       <= drv_trans.CIN;
									$display("[%0t] Retry %0d: CE = %0d, MODE = %0d, INP_VALID = %0d, CMD = %0d, OPA = %0d, OPB = %0d, CIN = %0d\n",$time,c, drv_trans.CE, drv_trans.MODE, drv_trans.INP_VALID, drv_trans.CMD, drv_trans.OPA, drv_trans.OPB, drv_trans.CIN);
								end

								if (drv_trans.INP_VALID != 2'b11) begin
									$error("[%0t] ALU DRIVER: INP_VALID did not become 2'b11 within 16 cycles", $time);
								end
							end

							@(vif.drv_cb); // latch

							mbx_dr.put(drv_trans);
							drv_cg.sample();

							repeat(delay) @(vif.drv_cb); // delay here

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
					end

					$display("ALU DRIVER: Input Coverage = %0.2f%%\n", drv_cg.get_coverage());
					repeat(3) @(vif.drv_cb);

				endtask

endclass 
