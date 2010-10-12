import ClientServer::*;
import GetPut::*;
import Connectable::*;
import AvalonCommon::*;
import AvalonMaster::*;
import AvalonMasterEmu::*;
import Processor::*;

module mkMIPS(AvalonMasterWires#(24,32));
    function ignoreCache(Bit#(24) addr) = addr[23] == 1'b1;
    let mips <- mkProcessor(mkAvalonMaster, ignoreCache);
    return mips;
endmodule

module mkMIPSEmu();
    function ignoreCache(Bit#(24) addr) = False;
    AvalonMasterWires#(24,32) mips <- mkProcessor(mkAvalonMasterEmu, ignoreCache);
endmodule

