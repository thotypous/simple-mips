import ClientServer::*;
import GetPut::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;

module mkMIPSCPU#(module#(AvalonMaster#(address_width,32)) mkMaster) (AvalonMasterWires#(address_width,32));
    AvalonMaster#(address_width,32) masterAdapter <- mkMaster;
    Reg#(Bit#(address_width)) addrReq <- mkReg(0);
    Reg#(Bit#(address_width)) addrResp <- mkReg(0);

    rule requestAddr;
        masterAdapter.busServer.request.put(AvalonRequest{command: Read, addr: addrReq, data: ?});
        addrReq <= addrReq + 4;
    endrule
    rule displayData;
        let data <- masterAdapter.busServer.response.get;
        if(addrResp >= 'h500) $finish();
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

