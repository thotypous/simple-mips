import ClientServer::*;
import GetPut::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import RegFile::*;
import FShow::*;
import AvalonCommon::*;
import AvalonMaster::*;
import Cache::*;
import Instructions::*;
import Trace::*;
import RFile::*;

typedef 12 CacheWidth;
typedef 24 MaxAddrWidth;

typedef union tagged {
    struct { Ridx     r;    Bit#(32) data;                         } WbREG;
    struct { Ridx     r;    Bit#(MaxAddrWidth) addr; Bit#(2) line; } WbLB;
    struct { Ridx     r;    Bit#(MaxAddrWidth) addr; Bit#(2) line; } WbLBU;
    struct { Ridx     r;    Bit#(MaxAddrWidth) addr; Bit#(1) line; } WbLH;
    struct { Ridx     r;    Bit#(MaxAddrWidth) addr; Bit#(1) line; } WbLHU;
    struct { Ridx     r;    Bit#(MaxAddrWidth) addr;               } WbLW;
    struct { Bit#( 8) data; Bit#(MaxAddrWidth) addr; Bit#(2) line; } WbSB;
    struct { Bit#(16) data; Bit#(MaxAddrWidth) addr; Bit#(1) line; } WbSH;
    struct { Bit#(32) data; Bit#(MaxAddrWidth) addr;               } WbSW;
} WBOp#(numeric type address_width) deriving (Eq, Bits);

module mkProcessor#(module#(AvalonMaster#(address_width,32)) mkMaster,
                  function Bool ignoreCache(Bit#(address_width) addr))
                  (AvalonMasterWires#(address_width,32))
                  provisos (Add#(a__, CacheWidth, address_width),
                            Add#(b__, address_width, MaxAddrWidth));

    AvalonMaster#(address_width,32) masterAdapter <- mkMaster;
    Cache#(address_width,CacheWidth,CacheWidth) cache <- mkCache(ignoreCache);
    Reg  #(Bit#(address_width)) fetchPC <- mkReg('h100);
    FIFOF#(Bit#(address_width)) jumpTo <- mkBypassFIFOF;
    FIFOF#(Bit#(address_width)) execPC <- mkPipelineFIFOF;
    FIFOF#(Bit#(32)) instFIFO <- mkBypassFIFOF;
    FIFOF#(Bit#(32)) dataFIFO <- mkBypassFIFOF;
    FIFOF#(WBOp#(address_width)) pendingLoad <- mkPipelineFIFOF;
    FIFOF#(WBOp#(address_width)) execToWB <- mkPipelineFIFOF;
    RFile rf <- mkRFile; 

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);
    mkConnection(cache.instCache.response, toPut(instFIFO));
    mkConnection(cache.dataCache.response, toPut(dataFIFO));

    rule fetchAhead(!jumpTo.notEmpty);
        trace($format("[Fetch %h]", fetchPC));
        cache.instCache.request.put(AvalonRequest{command: Read, addr: fetchPC, data: ?});
        execPC.enq(fetchPC);
        fetchPC <= fetchPC + 1;
    endrule

    rule fetchJump(jumpTo.notEmpty);
        trace($format("[Fetch %h] [jump %h]", fetchPC, jumpTo.first));
        cache.instCache.request.put(AvalonRequest{command: Read, addr: fetchPC, data: ?});
        execPC.enq(fetchPC);
        fetchPC <= jumpTo.first;
        jumpTo.deq;
    endrule

    rule exec(!pendingLoad.notEmpty);
        Instr inst = unpack(instFIFO.first);
        let pc = execPC.first;
        trace($format("[Exec  %h] ", pc)+fshow(inst));
        instFIFO.deq;
        execPC.deq;

        case (inst) matches
            tagged ADD   .s: 
            tagged ADDI  .s: 
            tagged ADDIU .s: 
            tagged ADDU  .s: 
            tagged LUI   .s: 
            tagged SUB   .s: 
            tagged SUBU  .s: 
            tagged SLL   .s: 
            tagged SLLV  .s: 
            tagged SRA   .s: 
            tagged SRAV  .s: 
            tagged SRL   .s: 
            tagged SRLV  .s: 
            tagged AND   .s: 
            tagged ANDI  .s: 
            tagged NOR   .s: 
            tagged OR    .s: 
            tagged ORI   .s: 
            tagged XOR   .s: 
            tagged XORI  .s: 
            tagged SLT   .s: 
            tagged SLTI  .s: 
            tagged SLTIU .s: 
            tagged SLTU  .s: 
            tagged DIV   .s: 
            tagged DIVU  .s: 
            tagged MULT  .s: 
            tagged MULTU .s: 
            tagged MFHI  .s: 
            tagged MFLO  .s: 
            tagged BEQ   .s: 
            tagged BGEZ  .s: 
            tagged BGTZ  .s: 
            tagged BLEZ  .s: 
            tagged BLTZ  .s: 
            tagged BNE   .s: 
            tagged J     .s: 
            tagged JAL   .s: 
            tagged JALR  .s:
            tagged JR    .s:
            tagged LB    .s:
            tagged LBU   .s:
            tagged LH    .s:
            tagged LHU   .s:
            tagged LW    .s:
            tagged SB    .s:
            tagged SH    .s:
            tagged SW    .s:
            tagged ILLEGAL : $display("Exec error: Invalid instruction %h at pc=%h", pack(inst), pc);
        endcase
    endrule

    rule wbLoadResult(dataFIFO.notEmpty);
        let wbOp = pendingLoad.first;
        let data = dataFIFO.first;
        function Bit#(8) byteLine(Bit#(32) d, Bit#(2) line); 
            return (case(line)
                2'h0: d[31:24];
                2'h1: d[23:16];
                2'h2: d[15: 8];
                2'h3: d[ 7: 0];
            endcase);
        endfunction
        function Bit#(16) halfLine(Bit#(32) d, Bit#(1) line);
            return (case(line)
                1'h0: d[31:16];
                1'h1: d[15: 0];
            endcase);
        endfunction
        function Bit#(32) byteSub(Bit#(32) d, Bit#(2) line, Bit#(8) newd);
            case(line)
                2'h0: d[31:24] = newd;
                2'h1: d[23:16] = newd;
                2'h2: d[15: 8] = newd;
                2'h3: d[ 7: 0] = newd;
            endcase
            return d;
        endfunction
        function Bit#(32) halfSub(Bit#(32) d, Bit#(1) line, Bit#(16) newd);
            case(line)
                1'h0: d[31:16] = newd;
                1'h1: d[15: 0] = newd;
            endcase
            return d;
        endfunction
        case (wbOp) matches
            tagged WbREG .s: $display("WB error: wbREG shouldn't cause a pending load");
            tagged WbLB  .s: rf.wr(s.r, signExtend(byteLine(data, s.line)));
            tagged WbLBU .s: rf.wr(s.r, zeroExtend(byteLine(data, s.line)));
            tagged WbLH  .s: rf.wr(s.r, signExtend(halfLine(data, s.line)));
            tagged WbLHU .s: rf.wr(s.r, zeroExtend(halfLine(data, s.line)));
            tagged WbLW  .s: rf.wr(s.r, data);
            tagged WbSB  .s: cache.dataCache.request.put(AvalonRequest{command: Write, addr: truncate(s.addr),
                                                                       data: byteSub(data, s.line, s.data)});
            tagged WbSH  .s: cache.dataCache.request.put(AvalonRequest{command: Write, addr: truncate(s.addr),
                                                                       data: halfSub(data, s.line, s.data)});
            tagged WbSW  .s: $display("WB error: wbSW shouldn't cause a pending load");
        endcase
        dataFIFO.deq;
        pendingLoad.deq;
    endrule

    rule wbFromExec(!dataFIFO.notEmpty);
        let wbOp = execToWB.first;
        function Action reqLoad(Bit#(MaxAddrWidth) addr) = action
            cache.dataCache.request.put(AvalonRequest{command:Read, addr:truncate(addr), data:?});
            pendingLoad.enq(wbOp);
        endaction;
        case (wbOp) matches
            tagged WbREG .s: rf.wr(s.r, s.data);
            tagged WbLB  .s: reqLoad(s.addr);
            tagged WbLBU .s: reqLoad(s.addr);
            tagged WbLH  .s: reqLoad(s.addr);
            tagged WbLHU .s: reqLoad(s.addr);
            tagged WbLW  .s: reqLoad(s.addr);
            tagged WbSB  .s: reqLoad(s.addr);
            tagged WbSH  .s: reqLoad(s.addr);
            tagged WbSW  .s:
                cache.dataCache.request.put(AvalonRequest{command:Write, addr:truncate(s.addr), data:s.data});
        endcase
        execToWB.deq;
    endrule

    return masterAdapter.masterWires;
endmodule

