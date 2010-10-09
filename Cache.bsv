import ClientServer::*;
import GetPut::*;
import SpecialFIFOs::*;
import BRAM::*;
import AvalonCommon::*;

`define dataCacheSize 10
`define instCacheSize 10

interface Cache#(address_width);
    interface Client#(AvalonRequest#(address_width,32), Bit#(32)) busClient;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) instCache;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) dataCache;
endinterface

typedef struct {
    Bit#(address_width) addr;
    Maybe#(Bit#(32)) data;
} CacheLine#(address_width) deriving (Bits, Eq);

module mkCache(Cache#(address_width));
    BRAM_Configure cfg = defaultValue;
    BRAM2Port#(Bit#(`dataCacheSize), CacheLine#(address_width)) instLines <- mkBRAM2Server(cfg);
    BRAM2Port#(Bit#(`instCacheSize), CacheLine#(address_width)) dataLines <- mkBRAM2Server(cfg);
    FIFO#(Bit#(address_width)) instLineReqs <- mkFIFO;
    FIFO#(Bit#(address_width)) dataLineReqs <- mkFIFO;

    interface busClient;
        interface Get request;
            method ActionValue#(AvalonRequest#(address_width,32)) get();

            endmethod
        endinterface
        interface Put response;
            method Action put(Bit#(32) data);
            endmethod
        endinterface
    endinterface

    interface instCache;
        interface Put request;
            method Action put(AvalonRequest#(address_width,32) req);
                if(req.command == Read)
                  begin
                    instLines.portA.request.put(BRAMRequest{write: False,
                                                            responseOnWrite: False,
                                                            address: truncate(req.addr),
                                                            datain: ?});
                    instLineReqs.enq(req.addr);
                  end
                else
                  begin
                    $display("Cache: Error: Trying to write to the instruction cache");
                  end
            endmethod
        endinterface
        interface Put response;
            method ActionValue#(Bit#(32)) get();
            endmethod
        endinterface
    endinterface

    interface dataCache;
        interface Put request;
            method Action put(AvalonRequest#(address_width,32) req);
                if(req.command == Read)
                  begin
                    dataLines.portA.request.put(BRAMRequest{write: False,
                                                            responseOnWrite: False,
                                                            address: truncate(req.addr),
                                                            datain: ?});
                    dataLineReqs.enq(req.addr);
                  end
                else
                  begin
                    dataLines.portA.request.put(BRAMRequest{write: True,
                                                            responseOnWrite: False,
                                                            address: truncate(req.addr),
                                                            datain: CacheLine{addr: req.addr,
                                                                              data: req.data}});
                  end
            endmethod
        endinterface
        interface Put response;
            method ActionValue#(Bit#(32)) get();
            endmethod
        endinterface
    endinterface
endmodule

