//`include "defines.sv"

class alu_transaction;
	//input signals
	rand bit [`DATA_WIDTH-1:0] OPA,OPB;
	rand bit [1:0] INP_VALID;
	randc bit [3:0] CMD;
	rand bit CE,CIN,MODE;

	//output signals
	bit [`DATA_WIDTH+1:0] RES;
  bit ERR,OFLOW,COUT,G,L,E;

	//constraint ip_valid{INP_VALID == 3; MODE == 1; CMD == 0;/*INP_VALID dist {2'b00 := 1, 2'b10 := 2, 2'b01 := 2, 2'b11 := 5 };*/}
	constraint command{CMD inside {[0:13]};} //to cover invalid cmd range also
  constraint cmd_range_c {
  CMD inside {[0:13]}; // Base range constraint
  
		if (MODE == 1) {
    	!(CMD inside {9, 10});
  }
}	
	constraint ce{ CE dist {0 := 2, 1 := 10};}
	constraint cin_needed { if (!(CMD inside {4'b0010, 4'b0011}) || MODE == 0) CIN == 0;} //cin is active only for add and sub in arithmetic op
	
		//METHODS
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
