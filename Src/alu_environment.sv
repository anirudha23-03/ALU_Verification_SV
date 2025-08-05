/*`include "defines.sv"
`include "alu_transaction.sv"
`include "alu_reference_model.sv"
`include "alu_scb.sv"
`include "alu_generator.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"*/
class alu_environment;
	//virtual interfaces for driver, monitor and ref model
	virtual alu_if drv_vif;
	virtual alu_if mon_vif;
	virtual alu_if ref_vif;

	//mailboxes
	mailbox #(alu_transaction) mbx_gd; //gen to drv
	mailbox #(alu_transaction) mbx_dr; //drv to ref
	mailbox #(alu_transaction) mbx_rs; //ref to scb
	mailbox #(alu_transaction) mbx_ms; //mon to scb

	//declaring handles for components
	alu_generator        gen;
	alu_driver           drv;
	alu_monitor          mon;
	alu_reference_model  r_m;
	alu_scb              scb;

	//new constructor to connect virtual interfaces from drv, mon, ref to test
	function new (virtual alu_if drv_vif,
								virtual alu_if mon_vif,
			          virtual alu_if ref_vif);
		this.drv_vif=drv_vif;
		this.mon_vif=mon_vif;
		this.ref_vif=ref_vif;
	endfunction

	//task to create objects for mailboxes and components
	task build();
		begin
			mbx_gd = new();
			mbx_dr = new();
			mbx_rs = new();
			mbx_ms = new();

			gen = new(mbx_gd);
			drv = new(mbx_gd,mbx_dr,drv_vif);
			mon = new(mon_vif,mbx_ms);
			r_m = new(mbx_dr,mbx_rs,ref_vif);
			scb = new(mbx_rs,mbx_ms);
		end
	endtask

	//task to call the start method of each components
	task start();
		fork
			gen.start();
			drv.start();
			mon.start();
			scb.start();
			r_m.start();
		join
		//scb.compare_results();
	endtask

endclass
