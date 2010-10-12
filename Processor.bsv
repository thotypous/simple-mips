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
import AvalonMasterEmu::*;
import Cache::*;
import Instructions::*;
import Trace::*;
import RFile::*;

module mkProcessor#(module#(AvalonMaster#(address_width,32)) mkMaster,
                  function Bool ignoreCache(Bit#(address_width) addr))
                  (AvalonMasterWires#(address_width,32))
                  provisos (Add#(a__, 12, address_width));

    AvalonMaster#(address_width,32) masterAdapter <- mkMaster;
    Cache#(address_width,12,12) cache <- mkCache(ignoreCache);
    FIFOF#(Bit#(address_width)) jumpTo <- mkBypassFIFOF;
    Reg#(Bit#(address_width)) pc <- mkReg('h100);
    RFile rf <- mkRFile; 

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);

    rule fetchAhead(!jumpTo.notEmpty);
        trace($format("[Fetch] pc=%h", pc));
        cache.instCache.request.put(AvalonRequest{command: Read, addr: pc, data: ?});
        pc <= pc + 1;
    endrule

    rule fetchJump(jumpTo.notEmpty);
        trace($format("[Fetch] pc=%h [jump %h]", pc, jumpTo.first));
        cache.instCache.request.put(AvalonRequest{command: Read, addr: pc, data: ?});
        pc <= jumpTo.first;
        jumpTo.deq;
    endrule

    rule exec;
        Instr instr <- liftM(unpack)(cache.instCache.response.get);
        trace($format("[Exec ] ")+fshow(instr));

        case (instr) matches
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
            tagged ILLEGAL :
        endcase
    endrule

    return masterAdapter.masterWires;
endmodule

