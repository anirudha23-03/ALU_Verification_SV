//`include "defines.sv"
//`include "alu_transaction.sv"

class alu_scb;

    // alu transaction class handles
    alu_transaction ref2sb_trans, mon2sb_trans;
    mailbox #(alu_transaction) mbx_rs; // ref_mod to scb mailbox
    mailbox #(alu_transaction) mbx_ms; // monitor to scb mailbox

    // associative arrays to store expected (ref) and actual (mon) transactions
    alu_transaction ref_mem [bit[`NO_OF_TRANS:0]];
    alu_transaction mon_mem [bit[`NO_OF_TRANS:0]];

    int MATCH, MISMATCH;

    // constructor
    function new(mailbox #(alu_transaction) mbx_rs, mailbox #(alu_transaction) mbx_ms);
        this.mbx_rs = mbx_rs;
        this.mbx_ms = mbx_ms;
    endfunction

    // task to start scoreboard checking
    task start();
        for (int i = 0; i < `NO_OF_TRANS; i++) begin
            ref2sb_trans = new();
            mon2sb_trans = new();

            mbx_rs.get(ref2sb_trans);
            mbx_ms.get(mon2sb_trans);

            ref_mem[i] = ref2sb_trans;
            mon_mem[i] = mon2sb_trans;

            $display("[%0t] ----------------------- SCOREBOARD ---------------------------", $time);
            $display("### REF[%0d] => RES=%0h, CMD=%0d, OPA=%0d, OPB=%0d", 
                     i, ref2sb_trans.RES, ref2sb_trans.CMD, ref2sb_trans.OPA, ref2sb_trans.OPB);
            $display("### MON[%0d] => RES=%0h, CMD=%0d, OPA=%0d, OPB=%0d", 
                     i, mon2sb_trans.RES, mon2sb_trans.CMD, mon2sb_trans.OPA, mon2sb_trans.OPB);

            compare_results(i);
        end
    endtask

    // task to compare results
    task compare_results(input int index);
        bit all_match = 1;

        if (ref_mem.exists(index) && mon_mem.exists(index)) begin

            // RES
            if (ref_mem[index].RES === mon_mem[index].RES)
                $display("PASS: RES match => %0h", ref_mem[index].RES);
            else begin
                $display("FAIL: RES mismatch => REF=%0h, MON=%0h", ref_mem[index].RES, mon_mem[index].RES);
                all_match = 0;
            end

            // COUT
            if (ref_mem[index].COUT === mon_mem[index].COUT)
                $display("PASS: COUT match => %0b", ref_mem[index].COUT);
            else begin
                $display("FAIL: COUT mismatch => REF=%0b, MON=%0b", ref_mem[index].COUT, mon_mem[index].COUT);
                all_match = 0;
            end

            // OFLOW
            if (ref_mem[index].OFLOW === mon_mem[index].OFLOW)
                $display("PASS: OFLOW match => %0b", ref_mem[index].OFLOW);
            else begin
                $display("FAIL: OFLOW mismatch => REF=%0b, MON=%0b", ref_mem[index].OFLOW, mon_mem[index].OFLOW);
                all_match = 0;
            end

            // ERR
            if (ref_mem[index].ERR === mon_mem[index].ERR)
                $display("PASS: ERR match => %0b", ref_mem[index].ERR);
            else begin
                $display("FAIL: ERR mismatch => REF=%0b, MON=%0b", ref_mem[index].ERR, mon_mem[index].ERR);
                all_match = 0;
            end

            // G
            if (ref_mem[index].G === mon_mem[index].G)
                $display("PASS: G match => %0b", ref_mem[index].G);
            else begin
                $display("FAIL: G mismatch => REF=%0b, MON=%0b", ref_mem[index].G, mon_mem[index].G);
                all_match = 0;
            end

            // L
            if (ref_mem[index].L === mon_mem[index].L)
                $display("PASS: L match => %0b", ref_mem[index].L);
            else begin
                $display("FAIL: L mismatch => REF=%0b, MON=%0b", ref_mem[index].L, mon_mem[index].L);
                all_match = 0;
            end

            // E
            if (ref_mem[index].E === mon_mem[index].E)
                $display("PASS: E match => %0b", ref_mem[index].E);
            else begin
                $display("FAIL: E mismatch => REF=%0b, MON=%0b", ref_mem[index].E, mon_mem[index].E);
                all_match = 0;
            end

            if (all_match) begin
                $display("PASS: All outputs match for transaction [%0d]\n", index);
                MATCH++;
            end else begin
                $display("FAIL: Mismatch found in transaction [%0d]\n", index);
                MISMATCH++;
            end
        end
        else begin
            $display("MISSING: Transaction[%0d] not found in memory\n", index);
        end
    endtask

endclass

