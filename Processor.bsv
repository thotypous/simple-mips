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
                            Add#(b__, address_width, MaxAddrWidth),
                            Add#(c__, address_width, 32),
                            Add#(d__, 16, address_width));

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
        let pc  = execPC.first;
        let pc1 = pc+1;
        trace($format("[Exec  %h] ", pc)+fshow(inst));
        instFIFO.deq;
        execPC.deq;

        function Bit#(32) zextSh(Sham sh) = zeroExtend(sh);
        function Bit#(32) zextTg(Jtgt tg) = zeroExtend(tg);

        case (inst) matches
            tagged ADD   .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)+rf.rd2(s.rt)                                });
            tagged ADDI  .s: execToWB.enq(WbREG{r:s.rt, data:rf.rd1(s.rs)+signExtend(s.im)                            });
            tagged ADDIU .s: execToWB.enq(WbREG{r:s.rt, data:rf.rd1(s.rs)+signExtend(s.im)                            });
            tagged ADDU  .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)+rf.rd2(s.rt)                                });
            tagged LUI   .s: execToWB.enq(WbREG{r:s.rt, data:{s.im,16'b0}                                             });
            tagged SUB   .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)-rf.rd2(s.rt)                                });
            tagged SUBU  .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)-rf.rd2(s.rt)                                });
            tagged SLL   .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rt)<<zextSh(s.sa)                               });
            tagged SLLV  .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rt)<<zextSh(rf.rd2(s.rs)[4:0])                  });
            tagged SRA   .s: execToWB.enq(WbREG{r:s.rd, data:signedShiftRight(rf.rd1(s.rt),zextSh(s.sa))              });
            tagged SRAV  .s: execToWB.enq(WbREG{r:s.rd, data:signedShiftRight(rf.rd1(s.rt),zextSh(rf.rd2(s.rs)[4:0])) });
            tagged SRL   .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rt)>>zextSh(s.sa)                               });
            tagged SRLV  .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rt)>>zextSh(rf.rd2(s.rs)[4:0])                  });
            tagged AND   .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)&rf.rd2(s.rt)                                });
            tagged ANDI  .s: execToWB.enq(WbREG{r:s.rt, data:rf.rd1(s.rs)&zeroExtend(s.im)                            });
            tagged NOR   .s: execToWB.enq(WbREG{r:s.rd, data:~(rf.rd1(s.rs)|rf.rd2(s.rt))                             });
            tagged OR    .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)|rf.rd2(s.rt)                                });
            tagged ORI   .s: execToWB.enq(WbREG{r:s.rt, data:rf.rd1(s.rs)|zeroExtend(s.im)                            });
            tagged XOR   .s: execToWB.enq(WbREG{r:s.rd, data:rf.rd1(s.rs)^rf.rd2(s.rt)                                });
            tagged XORI  .s: execToWB.enq(WbREG{r:s.rt, data:rf.rd1(s.rs)^zeroExtend(s.im)                            });
            tagged SLT   .s: execToWB.enq(WbREG{r:s.rd, data:zeroExtend(pack(signedLT(rf.rd1(s.rs),rf.rd2(s.rt))))    });
            tagged SLTI  .s: execToWB.enq(WbREG{r:s.rt, data:zeroExtend(pack(signedLT(rf.rd1(s.rs),signExtend(s.im))))});
            tagged SLTIU .s: execToWB.enq(WbREG{r:s.rt, data:zeroExtend(pack(         rf.rd1(s.rs)<signExtend(s.im)) )});
            tagged SLTU  .s: execToWB.enq(WbREG{r:s.rt, data:zeroExtend(pack(         rf.rd1(s.rs)<rf.rd2(s.rt)))     });
            tagged DIV   .s: noAction;
            tagged DIVU  .s: noAction;
            tagged MULT  .s: noAction;
            tagged MULTU .s: noAction;
            tagged MFHI  .s: noAction;
            tagged MFLO  .s: noAction;
            tagged BEQ   .s: if(rf.rd1(s.rs)==rf.rd2(s.rt)) jumpTo.enq(pc1 + signExtend(s.of));
            tagged BGEZ  .s: if(signedGE(rf.rd1(s.rs),0))   jumpTo.enq(pc1 + signExtend(s.of));
            tagged BGTZ  .s: if(signedGT(rf.rd1(s.rs),0))   jumpTo.enq(pc1 + signExtend(s.of));
            tagged BLEZ  .s: if(signedLE(rf.rd1(s.rs),0))   jumpTo.enq(pc1 + signExtend(s.of));
            tagged BLTZ  .s: if(signedLT(rf.rd1(s.rs),0))   jumpTo.enq(pc1 + signExtend(s.of));
            tagged BNE   .s: if(rf.rd1(s.rs)!=rf.rd2(s.rt)) jumpTo.enq(pc1 + signExtend(s.of));
            tagged J     .s: jumpTo.enq(truncate(zextTg(s.tg)));
            tagged JAL   .s:
                action
                    execToWB.enq(WbREG{r:31, data:zeroExtend(pc+2)});
                    jumpTo.enq(truncate(zextTg(s.tg)));
                endaction
            tagged JALR  .s:
                action
                    execToWB.enq(WbREG{r:s.rd, data:zeroExtend(pc+2)});
                    jumpTo.enq(truncate(rf.rd1(s.rs)));
                endaction
            tagged JR    .s: jumpTo.enq(truncate(rf.rd1(s.rs)));
            tagged LB    .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbLB{r:s.rt, addr:zeroExtend(addr), line:absaddr[1:0]});
                endaction
            tagged LBU   .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbLBU{r:s.rt, addr:zeroExtend(addr), line:absaddr[1:0]});
                endaction
            tagged LH    .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbLH{r:s.rt, addr:zeroExtend(addr), line:absaddr[1]});
                endaction
            tagged LHU   .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbLHU{r:s.rt, addr:zeroExtend(addr), line:absaddr[1]});
                endaction
            tagged LW    .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbLW{r:s.rt, addr:zeroExtend(addr)});
                endaction
            tagged SB    .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbSB{data:truncate(rf.rd2(s.rt)), addr:zeroExtend(addr), line:absaddr[1:0]});
                endaction
            tagged SH    .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbSH{data:truncate(rf.rd2(s.rt)), addr:zeroExtend(addr), line:absaddr[1]});
                endaction
            tagged SW    .s:
                action
                    Bit#(32) absaddr = rf.rd1(s.rb)+zeroExtend(s.of);
                    Bit#(address_width) addr = truncate(absaddr>>2);
                    execToWB.enq(WbSW{data:rf.rd2(s.rt), addr:zeroExtend(addr)});
                endaction
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

