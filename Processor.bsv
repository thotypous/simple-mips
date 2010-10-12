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

module mkProcessor#(module#(AvalonMaster#(address_width,32)) mkMaster,
                  function Bool ignoreCache(Bit#(address_width) addr))
                  (AvalonMasterWires#(address_width,32))
                  provisos (Add#(a__, 10, address_width));

    AvalonMaster#(address_width,32) masterAdapter <- mkMaster;
    Cache#(address_width,10,10) cache <- mkCache(ignoreCache);

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);

    Reg#(Bit#(address_width)) addrReq <- mkReg('h100);
    Reg#(Bit#(address_width)) addrResp <- mkReg('h100);

    rule req;
        cache.instCache.request.put(AvalonRequest{command:Read, addr:addrReq, data:?});
        addrReq <= addrReq + 1;
    endrule
    rule resp;
        let codedInstr <- cache.instCache.response.get;
        Instr instr = unpack(codedInstr);
        $display($format("%h ",addrResp)+fshow(instr));
        addrResp <= addrResp + 1;
    endrule

    rule finish(addrResp > 'h150);
        $finish();
    endrule
    
    return masterAdapter.masterWires;
endmodule

