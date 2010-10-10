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
    
    Reg#(Bit#(address_width)) addrInstReq <- mkReg('h400);
    Reg#(Bit#(address_width)) addrInstResp <- mkReg('h400);
    Reg#(Bit#(address_width)) addrDataReq <- mkReg('h400);
    Reg#(Bit#(address_width)) addrDataResp <- mkReg('h400);

    mkConnection(cache.busClient.request, masterAdapter.busServer.request);
    mkConnection(masterAdapter.busServer.response, cache.busClient.response);

    rule requestInstAddr;
        cache.instCache.request.put(AvalonRequest{command: Read, addr: addrInstReq, data: ?});
        addrInstReq <= addrInstReq + 4;
    endrule
    rule displayInstData;
        let data <- cache.instCache.response.get;
        $display("I> %h %h", addrInstResp, data);
        addrInstResp <= addrInstResp + 4;
    endrule

    rule requestDataAddr;
        cache.dataCache.request.put(AvalonRequest{command: Read, addr: addrDataReq, data: ?});
        addrDataReq <= addrDataReq + 4;
    endrule
    rule displayDataData;
        let data <- cache.dataCache.response.get;
        $display("D> %h %h", addrDataResp, data);
        addrDataResp <= addrDataResp + 4;
    endrule

    rule doFinish;
        if(addrInstResp >= 'h800 && addrDataResp >= 'h800) $finish();
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

