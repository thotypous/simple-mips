import ClientServer::*;
import GetPut::*;
import AvalonCommon::*;

interface Cache;
    interface Client#(AvalonRequest#(address_width,32), Bit#(32)) busClient;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) instCache;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) dataCache;
endinterface

module mkCache(Cache);
    
endmodule

