import ClientServer::*;
import GetPut::*;
import SpecialFIFOs::*;
import BRAM::*;
import AvalonCommon::*;

`define cacheSize 10

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
    BRAM2Port#(Bit#(`cacheSize), CacheLine#(address_width)) instLines <- mkBRAM2Server(cfg);
    BRAM2Port#(Bit#(`cacheSize), CacheLine#(address_width)) dataLines <- mkBRAM2Server(cfg);
    
    Reg#(Bit#(TAdd#(`cacheSize,1))) resetCounter <- mkReg(0);
    Bool resetState = resetCounter[`cacheSize] == 1'b0;

    FIFO#(Bit#(address_width)) instLineReqs <- mkFIFO;
    FIFO#(Bit#(address_width)) dataLineReqs <- mkFIFO;

    FIFO#(Bit#(32)) instResps <- mkBypassFIFO;
    FIFO#(Bit#(32)) dataResps <- mkBypassFIFO;

    rule doReset(resetState);
        let req = BRAMRequest{write: True,
                              responseOnWrite: False,
                              address: resetCounter,
                              datain: CacheLine{addr: 0,
                                                data: tagged Invalid}};
        instLines.portA.request.put(req);
        dataLines.portA.request.put(req);
        req.address = req.address + 1;
        instLines.portB.request.put(req);
        dataLines.portB.request.put(req);
        resetCounter <= resetCounter + 2;
    endrule

    rule instCacheLineCheck(!resetState);
        let cacheLine <- instLines.portA.response.get;
        let requestedAddr = instLineReqs.first;
        instLineReqs.deq;
        if(cacheLine.addr == requestedAddr &&& cacheLine.data matches tagged Valid .data)
          begin
            instResps.enq(data);
          end
        else
          begin
            
          end
    endrule

    rule dataCacheLineCheck(!resetState);
        let cacheLine <- dataLines.portA.response.get;
        let requestedAddr = dataLineReqs.first;
        dataLineReqs.deq;
        if(cacheLine.addr == requestedAddr &&& cacheLine.data matches tagged Valid .data)
            dataResps.enq(data);
    endrule

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
            method Action put(AvalonRequest#(address_width,32) req) if (!resetState);
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
        interface Get response = toGet(instResps);
    endinterface

    interface dataCache;
        interface Put request;
            method Action put(AvalonRequest#(address_width,32) req) if (!resetState);
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
                                                                              data: tagged Valid req.data}});
                  end
            endmethod
        endinterface
        interface Get response = toGet(dataResps);
    endinterface
endmodule

