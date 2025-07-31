//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_reference_model;
  //PROPERTIES
  alu_transaction ref_trans;
  mailbox #(alu_transaction) mbx_rs;
  mailbox #(alu_transaction) mbx_dr;
  virtual alu_if.REF_SB vif;

  //METHODS

  //Constructor
  function new(mailbox #(alu_transaction) mbx_dr,
               mailbox #(alu_transaction) mbx_rs,
               virtual alu_if.REF_SB vif);
    this.mbx_dr = mbx_dr;
    this.mbx_rs = mbx_rs;
    this.vif = vif;
  endfunction

  //Start task
  task start();
    for (int i = 0; i < `NO_OF_TRANS; i++) begin
      ref_trans = new();
      mbx_dr.get(ref_trans);

      if (op_wait_req(ref_trans.CMD, ref_trans.MODE, ref_trans.INP_VALID)) begin
        handle_op_wait();
      end else begin
        // repeat (1) @(vif.ref_cb)
         begin
          calculate_expected_results(
            vif.rst,
            ref_trans.CE,
            ref_trans.MODE,
            ref_trans.CIN,
            ref_trans.INP_VALID,
            ref_trans.CMD,
            ref_trans.OPA,
            ref_trans.OPB,
            ref_trans.RES,
            ref_trans.COUT,
            ref_trans.E,
            ref_trans.G,
            ref_trans.L,
            ref_trans.OFLOW,
            ref_trans.ERR
          );

					$display("[%0t]-----------------------REFERENCE MODEL ------------------------\n",$time);
          $display("RST = %0b CE = %0b MODE = %0b INP_VALID = %0b CMD = %0d",
                   vif.rst, ref_trans.CE, ref_trans.MODE, ref_trans.INP_VALID, ref_trans.CMD);
          $display("OPA = %0d OPB = %0d CIN = %0b\n", ref_trans.OPA, ref_trans.OPB, ref_trans.CIN);
          $display("[REF MODEL] Expected: RES = %0d COUT = %0b EGL = %0b OFLOW = %0b ERR = %0b\n",
                   ref_trans.RES, ref_trans.COUT, {ref_trans.E, ref_trans.G, ref_trans.L},
                   ref_trans.OFLOW, ref_trans.ERR);
        end
      end

      mbx_rs.put(ref_trans);
    end
  endtask

  function bit op_wait_req(input [3:0] cmd, input mode, input [1:0] inp_valid);
    bit req_both_op = 0;
    if (mode) begin
      case (cmd)
        `ADD, `SUB, `ADD_CIN, `SUB_CIN, `CMP, `MULT, `SH1_MULT: req_both_op = 1;
        default: req_both_op = 0;
      endcase
    end else begin
      case (cmd)
        `AND, `NAND, `OR, `NOR, `XOR, `XNOR, `ROL_A_B, `ROR_A_B: req_both_op = 1;
        default: req_both_op = 0;
      endcase
    end
    return (req_both_op && (inp_valid == 2'b01 || inp_valid == 2'b10));
  endfunction

  task handle_op_wait();
    int timeout_counter = 0;
    bit op_received = 0;

    $display("[REF MODEL] Time=%0t: Waiting for missing operand, current inp_valid=%0b", $time, ref_trans.INP_VALID);

    for (timeout_counter = 0; timeout_counter < 16; timeout_counter++) begin
      @(vif.ref_cb);
      if (vif.INP_VALID == 2'b11) begin
        op_received = 1;
        ref_trans.INP_VALID = 2'b11;
        ref_trans.OPA = vif.ref_cb.OPA;
        ref_trans.OPB = vif.ref_cb.OPB;
        $display("[REF MODEL] Time=%0t: Missing operand received at cycle %0d", $time, timeout_counter + 1);
        break;
      end
    end

    if (op_received) begin
      calculate_expected_results(
        vif.rst,
        ref_trans.CE,
        ref_trans.MODE,
        ref_trans.CIN,
        ref_trans.INP_VALID,
        ref_trans.CMD,
        ref_trans.OPA,
        ref_trans.OPB,
        ref_trans.RES,
        ref_trans.COUT,
        ref_trans.E,
        ref_trans.G,
        ref_trans.L,
        ref_trans.OFLOW,
        ref_trans.ERR
      );
      $display("[REF MODEL] Time=%0t: Operation completed with both operands", $time);
    end else begin
      ref_trans.RES = 0;
      ref_trans.COUT = 0;
      {ref_trans.E, ref_trans.G, ref_trans.L} = 3'b000;
      ref_trans.OFLOW = 0;
      ref_trans.ERR = 1;
      $display("[REF MODEL] Time=%0t: Timeout after 16 cycles - setting error", $time);
    end

    $display("[REF MODEL] Final: RES = %0d COUT = %0b EGL = %0b OFLOW = %0b ERR = %0b",
             ref_trans.RES, ref_trans.COUT, {ref_trans.E, ref_trans.G, ref_trans.L},
             ref_trans.OFLOW, ref_trans.ERR);
  endtask

  task calculate_expected_results;
    input rst, ce, mode, cin;
    input [1:0] ip_v;
    input [3:0] cmd;
    input [`DATA_WIDTH-1:0] opa, opb;
    output reg [2*`DATA_WIDTH:0] expected_res;
    output reg expected_cout;
    output reg expected_e;
    output reg expected_g;
    output reg expected_l;
    output reg expected_overflow;
    output reg expected_error;

    integer rot_amt;

    begin
      expected_res = 0;
      expected_cout = 0;
      {expected_e, expected_g, expected_l} = 3'b000;
      expected_overflow = 0;
      expected_error = 0;

      if (rst) begin
        expected_res = 0;
        expected_cout = 0;
        {expected_e, expected_g, expected_l} = 3'b000;
        expected_overflow = 0;
        expected_error = 0;
      end else if (ce) begin
        rot_amt = opb[$clog2(`DATA_WIDTH)-1:0];

        case (ip_v)
          2'b00: expected_error = 1;

          2'b01: begin
            if (mode) begin
              case (cmd)
                `INC_A: begin expected_res = opa + 1; expected_error = (opa == {`DATA_WIDTH{1'b1}}); end
                `DEC_A: begin expected_res = opa - 1; expected_error = (opa == {`DATA_WIDTH{1'b0}}); end
                default: expected_error = 1;
              endcase
            end else begin
              case (cmd)
                `NOT_A: expected_res = {{`DATA_WIDTH{1'b0}}, ~opa};
                `SHR1_A: expected_res = {{`DATA_WIDTH{1'b0}}, opa >> 1};
                `SHL1_A: expected_res = {{`DATA_WIDTH{1'b0}}, opa << 1};
                default: expected_error = 1;
              endcase
            end
          end

          2'b10: begin
            if (mode) begin
              case (cmd)
                `INC_B: begin expected_res = opb + 1; expected_error = (opb == {`DATA_WIDTH{1'b1}}); end
                `DEC_B: begin expected_res = opb - 1; expected_error = (opb == {`DATA_WIDTH{1'b0}}); end
                default: expected_error = 1;
              endcase
            end else begin
              case (cmd)
                `NOT_B: expected_res = {{`DATA_WIDTH{1'b0}}, ~opb};
                `SHR1_B: expected_res = {{`DATA_WIDTH{1'b0}}, opb >> 1};
                `SHL1_B: expected_res = {{`DATA_WIDTH{1'b0}}, opb << 1};
                default: expected_error = 1;
              endcase
            end
          end

          2'b11: begin
            if (mode) begin
              case (cmd)
                `ADD: begin expected_res = opa + opb; expected_cout = expected_res[`DATA_WIDTH]; end
                `SUB: begin expected_res = opa - opb; expected_overflow = (opa < opb); end
                `ADD_CIN: begin expected_res = opa + opb + cin; expected_cout = expected_res[`DATA_WIDTH]; end
                `SUB_CIN: begin expected_res = opa - opb - cin; expected_overflow = (opa < (opb + cin)); end
                `INC_A: begin expected_res = opa + 1; expected_error = (opa == {`DATA_WIDTH{1'b1}}); end
                `DEC_A: begin expected_res = opa - 1; expected_error = (opa == {`DATA_WIDTH{1'b0}}); end
                `INC_B: begin expected_res = opb + 1; expected_error = (opb == {`DATA_WIDTH{1'b1}}); end
                `DEC_B: begin expected_res = opb - 1; expected_error = (opb == {`DATA_WIDTH{1'b0}}); end
                `CMP: begin
                  if (opa == opb) {expected_e, expected_g, expected_l} = 3'b100;
                  else if (opa > opb) {expected_e, expected_g, expected_l} = 3'b010;
                  else {expected_e, expected_g, expected_l} = 3'b001;
                end
                `MULT: expected_res = (opa + 1) * (opb + 1);
                `SH1_MULT: expected_res = (opa << 1) * opb;
                default: expected_error = 1;
              endcase
            end else begin
              case (cmd)
                `AND: expected_res = {{`DATA_WIDTH{1'b0}}, opa & opb};
                `NAND: expected_res = {{`DATA_WIDTH{1'b0}}, ~(opa & opb)};
                `OR: expected_res = {{`DATA_WIDTH{1'b0}}, opa | opb};
                `NOR: expected_res = {{`DATA_WIDTH{1'b0}}, ~(opa | opb)};
                `XOR: expected_res = {{`DATA_WIDTH{1'b0}}, opa ^ opb};
                `XNOR: expected_res = {{`DATA_WIDTH{1'b0}}, ~(opa ^ opb)};
                `NOT_A: expected_res = {{`DATA_WIDTH{1'b0}}, ~opa};
                `NOT_B: expected_res = {{`DATA_WIDTH{1'b0}}, ~opb};
                `SHR1_A: expected_res = {{`DATA_WIDTH{1'b0}}, opa >> 1};
                `SHR1_B: expected_res = {{`DATA_WIDTH{1'b0}}, opb >> 1};
                `SHL1_A: expected_res = {{`DATA_WIDTH{1'b0}}, opa << 1};
                `SHL1_B: expected_res = {{`DATA_WIDTH{1'b0}}, opb << 1};
                `ROL_A_B: begin
                  expected_error = |opb[`DATA_WIDTH-1:$clog2(`DATA_WIDTH)];
                  expected_res = {{`DATA_WIDTH{1'b0}}, (rot_amt == 0) ? opa : (opa << rot_amt) | (opa >> (`DATA_WIDTH - rot_amt))};
                end
                `ROR_A_B: begin
                  expected_error = |opb[`DATA_WIDTH-1:$clog2(`DATA_WIDTH)];
                  expected_res = {{`DATA_WIDTH{1'b0}}, (rot_amt == 0) ? opa : (opa >> rot_amt) | (opa << (`DATA_WIDTH - rot_amt))};
                end
                default: expected_error = 1;
              endcase
            end
          end

          default: expected_error = 1;
        endcase
      end else begin
        expected_error = 1;
      end
    end
  endtask

endclass
