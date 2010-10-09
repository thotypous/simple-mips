import ClientServer::*;
import GetPut::*;
import SpecialFIFOs::*;
import BRAM::*;
import AvalonCommon::*;

interface Cache;
    interface Client#(AvalonRequest#(address_width,32), Bit#(32)) busClient;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) instCache;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) dataCache;
endinterface

module mkCache(Cache);
    interface busClient;
    endinterface

    interface instCache;
    endinterface

    interface dataCache;
    endinterface
endmodule

