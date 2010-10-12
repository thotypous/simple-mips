import ClientServer::*;
import GetPut::*;
import Connectable::*;
import FIFO::*;
import SpecialFIFOs::*;
import RegFile::*;
import FShow::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;
import Cache::*;
import Instructions::*;

interface RFile;
    method Action wr(Ridx ridx, Bit#(32) data);
    method Bit#(32) rd1(Ridx ridx);
    method Bit#(32) rd2(Ridx ridx);
endinterface

module mkRFile(RFile);
    RegFile#(Ridx,Bit#(32)) rf <- mkRegFileWCF(0,31);
    RWire#(Tuple2#(Ridx,Bit#(32))) rwout <- mkRWire;
    method Action wr(Ridx ridx, Bit#(32) data);
        rf.upd(ridx, data);
        rwout.wset(tuple2(ridx, data));
    endmethod
    method Bit#(32) rd1(Ridx ridx);
        case (rwout.wget) matches
            tagged Valid {.wr,.d}: return (ridx == 0) ? 0 : (wr==ridx) ? d : rf.sub(ridx);
		    tagged Invalid: return (ridx == 0) ? 0 : rf.sub(ridx);
        endcase
    endmethod
    method Bit#(32) rd2(Ridx ridx);
        case (rwout.wget) matches
            tagged Valid {.wr,.d}: return (ridx == 0) ? 0 : (wr==ridx) ? d : rf.sub(ridx);
		    tagged Invalid: return (ridx == 0) ? 0 : rf.sub(ridx);
        endcase
    endmethod
endmodule

module mkProcessor#(module#(AvalonMaster#(address_width,32)) mkMaster,
                  function Bool ignoreCache(Bit#(address_width) addr))
                  (AvalonMasterWires#(address_width,32))
                  provisos (Add#(a__, 12, address_width));

    AvalonMaster#(address_width,32) masterAdapter <- mkMaster;
    Cache#(address_width,12,12) cache <- mkCache(ignoreCache);
    
    RWire#(Bit#(address_width)) newpc <- mkRWire;
    Reg#(Bit#(address_width)) pc <- mkReg('h100);

    RFile rf <- mkRFile; 

    Reg#(Bool) first <- mkReg(True);

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);

    rule fetchStage;
        cache.instCache.request.put(AvalonRequest{command: Read, addr: pc, data: ?});
        $display("fetching %h", pc);
        pc <= fromMaybe(pc + 1, newpc.wget);
    endrule

    rule execStage;
        Instr instr <- liftM(unpack)(cache.instCache.response.get);
        $display(fshow(instr));
        if(first)
            newpc.wset('h109);
        first <= False;
    endrule

    rule finish(pc >= 'h130);
        $finish;
    endrule

    return masterAdapter.masterWires;
endmodule

