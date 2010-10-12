import ClientServer::*;
import GetPut::*;
import Connectable::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;
import Processor::*;

(* synthesize *)
module mkMIPS(AvalonMasterWires#(24,32));
    function ignoreCache(Bit#(24) addr) = addr[23] == 1'b1;
    let mips <- mkProcessor(mkAvalonMaster, ignoreCache);
    return mips;
endmodule

(* synthesize *)
module mkMIPSEmu();
    function ignoreCache(Bit#(19) addr) = False;
    AvalonMasterWires#(19,32) mips <- mkProcessor(mkAvalonMasterEmu, ignoreCache);
endmodule

