import ClientServer::*;
import GetPut::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;

module mkMIPSCPU#(module#(AvalonMaster#(26,32)) mkMaster) (AvalonMasterWires#(26,32));
    AvalonMaster#(26,32) masterAdapter <- mkMaster;
    Reg#(Bit#(26)) addrReq <- mkReg(0);
    Reg#(Bit#(26)) addrResp <- mkReg(0);

    rule requestAddr;
        masterAdapter.busServer.request.put(AvalonRequest{command: Read, addr: addrReq, data: ?});
        addrReq <= addrReq + 4;
    endrule
    rule displayData;
        let data <- masterAdapter.busServer.response.get;
        if(addrResp >= 10240) $finish();
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
    let mips <- mkMIPSCPU(mkAvalonMasterEmu);
endmodule

