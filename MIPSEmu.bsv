import ClientServer::*;
import GetPut::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;

module mkMIPSEmu();
    AvalonMaster#(21,32) masterAdapter <- mkAvalonMasterEmu;
    Reg#(Bit#(21)) addrReq <- mkReg(0);
    Reg#(Bit#(21)) addrResp <- mkReg(0);
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
endmodule
