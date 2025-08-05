//`include "defines.sv"

class alu_transaction;
	//input signals
	rand bit [`DATA_WIDTH-1:0] OPA,OPB;
	rand bit [1:0] INP_VALID;
	randc bit [3:0] CMD;
	rand bit CE,CIN,MODE;

	//output signals
	bit [`DATA_WIDTH:0] RES;
  bit ERR,OFLOW,COUT,G,L,E;
	
	constraint ce{ CE dist {0 := 2, 1 := 10};}
	constraint cin_needed { if (!(CMD inside {4'b0010, 4'b0011}) || MODE == 0) CIN == 0;}
/*	constraint c1{
			if(MODE == 1) CMD inside{[0:10]};
			else CMD inside{[0:13]};}
	  constraint c2 { INP_VALID inside{[0:3]};}*/
	
	//copying objects for blueprint
	virtual function alu_transaction copy();
			copy = new();
			copy.OPA = this.OPA;
			copy.OPB = this.OPB;
			copy.INP_VALID = this.INP_VALID;
			copy.CMD = this.CMD;
			copy.CE = this.CE;
			copy.CIN = this.CIN;
			copy.MODE = this.MODE;
			return copy;
		endfunction
endclass

class logical_one extends alu_transaction;
	constraint cmd {CMD inside {[6:11]};}
	constraint mode {MODE == 0;}
	constraint ip_valid {INP_VALID == 3;}
	virtual function logical_one copy();
			copy = new();
			copy.OPA = this.OPA;
			copy.OPB = this.OPB;
			copy.INP_VALID = this.INP_VALID;
			copy.CMD = this.CMD;
			copy.CE = this.CE;
			copy.CIN = this.CIN;
			copy.MODE = this.MODE;
			return copy;
		endfunction
endclass

class arithmetic_one extends alu_transaction;
	constraint cmd {CMD inside {[4:7]};}
	constraint mode {MODE == 1;}
	constraint ip_valid {INP_VALID == 3;}
	virtual function arithmetic_one copy();
			copy = new();
			copy.OPA = this.OPA;
			copy.OPB = this.OPB;
			copy.INP_VALID = this.INP_VALID;
			copy.CMD = this.CMD;
			copy.CE = this.CE;
			copy.CIN = this.CIN;
			copy.MODE = this.MODE;
			return copy;
		endfunction
endclass

class logical_two extends alu_transaction;
	constraint cmd {CMD inside {0,1,2,3,4,5,12,13};}
	constraint mode {MODE == 0;}
	constraint ip_valid {INP_VALID == 3;}
	virtual function logical_two copy();
			copy = new();
			copy.OPA = this.OPA;
			copy.OPB = this.OPB;
			copy.INP_VALID = this.INP_VALID;
			copy.CMD = this.CMD;
			copy.CE = this.CE;
			copy.CIN = this.CIN;
			copy.MODE = this.MODE;
			return copy;
		endfunction
endclass

class arithmetic_two extends alu_transaction;
	constraint cmd {CMD inside {0,1,2,3,8,9,10};}
	constraint mode {MODE == 1;}
	constraint ip_valid {INP_VALID == 3;}
	virtual function arithmetic_two copy();
			copy = new();
			copy.OPA = this.OPA;
			copy.OPB = this.OPB;
			copy.INP_VALID = this.INP_VALID;
			copy.CMD = this.CMD;
			copy.CE = this.CE;
			copy.CIN = this.CIN;
			copy.MODE = this.MODE;
		return copy;
	endfunction
endclass

class delay_16 extends alu_transaction;
	constraint cmd {CMD inside {0,1,2,3,8,9,10};}
	constraint mode {MODE inside {0,1};}
	//constraint ip_valid {INP_VALID != 3;}
	virtual function delay_16 copy();
			copy = new();
			copy.OPA = this.OPA;
			copy.OPB = this.OPB;
			copy.INP_VALID = this.INP_VALID;
			copy.CMD = this.CMD;
			copy.CE = this.CE;
			copy.CIN = this.CIN;
			copy.MODE = this.MODE;
			return copy;
		endfunction
endclass
