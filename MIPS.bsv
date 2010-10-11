import ClientServer::*;
import GetPut::*;
import Connectable::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;
import Processor::*;

(* synthesize *)
module mkMIPS(AvalonMasterWires#(26,32));
    function ignoreCache(Bit#(26) addr) = addr[25] == 1'b1;
    let mips <- mkProcessor(mkAvalonMaster, ignoreCache);
    return mips;
endmodule

(* synthesize *)
module mkMIPSEmu();
    function ignoreCache(Bit#(21) addr) = False;
    AvalonMasterWires#(21,32) mips <- mkProcessor(mkAvalonMasterEmu, ignoreCache);
endmodule

