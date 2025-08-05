//`include "alu_environment.sv"

class alu_test;
  virtual alu_if drv_vif;
  virtual alu_if mon_vif;
  virtual alu_if ref_vif;
  alu_environment env;

  function new(virtual alu_if drv_vif,
               virtual alu_if mon_vif,
               virtual alu_if ref_vif);
    this.drv_vif = drv_vif;
    this.mon_vif = mon_vif;
    this.ref_vif = ref_vif;
  endfunction

  task run();
    env = new(drv_vif,mon_vif,ref_vif);
    env.build;
    env.start;
  endtask
endclass

class test1 extends alu_test;
	logical_one trans1;
	function new(virtual alu_if drv_vif,
							 virtual alu_if mon_vif,
		           virtual alu_if ref_vif);
		    super.new(drv_vif,mon_vif,ref_vif);
  endfunction

	task run(); 
		env=new(drv_vif,mon_vif,ref_vif);
		env.build;
		begin
			trans1 = new();
			env.gen.blueprint= trans1;
	  end
		   env.start;
	endtask
endclass

class test2 extends alu_test;
	arithmetic_one trans2;
	function new(virtual alu_if drv_vif,
							 virtual alu_if mon_vif,
		           virtual alu_if ref_vif);
		    super.new(drv_vif,mon_vif,ref_vif);
  endfunction

	task run();
		env=new(drv_vif,mon_vif,ref_vif);
		env.build;
		begin
			trans2 = new();
			env.gen.blueprint= trans2;
	  end
		   env.start;
	endtask
endclass


class test3 extends alu_test;
	logical_two trans3;
	function new(virtual alu_if drv_vif,
							 virtual alu_if mon_vif,
		           virtual alu_if ref_vif);
		    super.new(drv_vif,mon_vif,ref_vif);
  endfunction
	task run();
		env=new(drv_vif,mon_vif,ref_vif);
		env.build;
		begin
			trans3 = new();
			env.gen.blueprint= trans3;
	  end
		   env.start;
	endtask
endclass

class test4 extends alu_test;
	arithmetic_two trans4;
	function new(virtual alu_if drv_vif,
							 virtual alu_if mon_vif,
		           virtual alu_if ref_vif);
		    super.new(drv_vif,mon_vif,ref_vif);
  endfunction

	task run();
		env=new(drv_vif,mon_vif,ref_vif);
		env.build;
		begin
			trans4 = new();
			env.gen.blueprint= trans4;
	  end
		   env.start;
	endtask
endclass

class test5 extends alu_test;
	delay_16 trans5;
	function new(virtual alu_if drv_vif,
							 virtual alu_if mon_vif,
		           virtual alu_if ref_vif);
		    super.new(drv_vif,mon_vif,ref_vif);
  endfunction

	task run();
		env=new(drv_vif,mon_vif,ref_vif);
		env.build;
		begin
			trans5 = new();
			env.gen.blueprint= trans5;
	  end
		   env.start;
	endtask
endclass

class test_regression extends alu_test;
	
	alu_transaction  trans;
	logical_one trans1;
	arithmetic_one trans2;
	logical_two trans3;
	arithmetic_two trans4;
	delay_16 trans5;

	function new(virtual alu_if drv_vif,
		virtual alu_if mon_vif,
		virtual alu_if ref_vif);
		super.new(drv_vif,mon_vif,ref_vif);
	endfunction

	task run();
		env=new(drv_vif,mon_vif,ref_vif);
		env.build;

		begin
			trans = new();
			env.gen.blueprint= trans;
		end
		env.start;

		begin
			trans1 = new();
			env.gen.blueprint= trans1;
		end
		env.start;

		begin
			trans2 = new();
			env.gen.blueprint= trans2;
		end
		env.start;

		begin
			trans3 = new();
			env.gen.blueprint= trans3;
		end
		env.start;

		begin
			trans4 = new();
			env.gen.blueprint= trans4;
		end
		env.start;

		begin
			trans5 = new();
			env.gen.blueprint= trans5;
		end
		env.start;
	endtask

endclass
