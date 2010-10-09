import ClientServer::*;
import GetPut::*;
import Connectable::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;
import Cache::*;

module mkMIPSCPU#(module#(AvalonMaster#(address_width,32)) mkMaster) (AvalonMasterWires#(address_width,32))
                provisos (Add#(a__, 10, address_width));
    AvalonMaster#(address_width,32) masterAdapter <- mkMaster;
    Cache#(address_width,10,10) cache <- mkCache;
    
    Reg#(Bit#(address_width)) addrReq <- mkReg('h400);
    Reg#(Bit#(address_width)) addrResp <- mkReg('h400);

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);

    rule requestAddr;
        cache.instCache.request.put(AvalonRequest{command: Read, addr: addrReq, data: ?});
        addrReq <= addrReq + 4;
    endrule
    rule displayData;
        let data <- cache.instCache.response.get;
        if(addrResp >= 'h800) $finish();
        $display("%h %h", addrResp, data);
        addrResp <= addrResp + 4;
    endrule

    return masterAdapter.masterWires;
endmodule

(* synthesize *)
module mkMIPS(AvalonMasterWires#(26,32));
    let mips <- mkMIPSCPU(mkAvalonMaster);
    return mips;
endmodule

(* synthesize *)
module mkMIPSEmu();
    AvalonMasterWires#(21,32) mips <- mkMIPSCPU(mkAvalonMasterEmu);
endmodule

