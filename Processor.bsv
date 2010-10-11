import ClientServer::*;
import GetPut::*;
import Connectable::*;
import FIFO::*;
import SpecialFIFOs::*;
import RegFile::*;
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

    return masterAdapter.masterWires;
endmodule

