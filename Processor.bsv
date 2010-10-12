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
    Reg#(Bit#(11)) cycles <- mkReg(0);
    Reg#(Bit#(16)) realCycles <- mkReg(0);
    RFile rf <- mkRFile; 

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);

    rule fetchAhead(!jumpTo.notEmpty);
        trace($format("[Fetch %h] pc=%h", realCycles, pc));
        cache.instCache.request.put(AvalonRequest{command: Read, addr: pc, data: ?});
        pc <= pc + 1;
    endrule

    rule fetchJump(jumpTo.notEmpty);
        trace($format("[Fetch %h] [jump %h] pc=%h", realCycles, jumpTo.first, pc));
        cache.instCache.request.put(AvalonRequest{command: Read, addr: pc, data: ?});
        pc <= jumpTo.first;
        jumpTo.deq;
    endrule

    rule exec;
        Instr instr <- liftM(unpack)(cache.instCache.response.get);
        trace($format("[Exec  %h] ", realCycles)+fshow(instr));
        if(instr matches tagged JAL .s)
            jumpTo.enq('h109);
        if(instr matches tagged JR .s)
            jumpTo.enq('h100);
        cycles <= cycles + 1;
    endrule

    rule finish(cycles > 1024);
        $finish;
    endrule

    rule upcycles;
        realCycles <= realCycles + 1;
    endrule

    return masterAdapter.masterWires;
endmodule

