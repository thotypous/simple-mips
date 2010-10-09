import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import BRAM::*;
import AvalonCommon::*;

//export Cache(..) mkCache;

interface Cache#(numeric type address_width, numeric type inst_width, numeric type data_width);
    method Action clear();
    interface Client#(AvalonRequest#(address_width,32), Bit#(32)) busClient;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) instCache;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) dataCache;
endinterface

interface SingleCache#(numeric type address_width, numeric type cache_width);
    method Action clear();
    interface Put#(CacheLine#(address_width)) prefetch;
    interface Client#(AvalonRequest#(address_width,32), Bit#(32)) busClient;
    interface Server#(AvalonRequest#(address_width,32), Bit#(32)) thisCache;
endinterface

typedef struct {
    Bit#(address_width) addr;
    Maybe#(Bit#(32)) data;
} CacheLine#(numeric type address_width) deriving (Bits, Eq);

module mkSingleCache(SingleCache#(address_width,cache_width))
                    provisos (Add#(a__, cache_width, address_width),
                              Add#(b__, cache_width, TAdd#(cache_width, 1)));
    BRAM_Configure cfg = defaultValue;
    BRAM2Port#(Bit#(cache_width), CacheLine#(address_width)) cacheLines <- mkBRAM2Server(cfg);
    RWire#(Bit#(cache_width)) portAaddr <- mkRWire;

    Reg#(Bit#(TAdd#(cache_width,1))) resetCounter <- mkReg(0);
    Integer resetLastBit = valueof(cache_width);
    Bool resetState = resetCounter[resetLastBit] == 1'b0;

    FIFOF#(AvalonRequest#(address_width,32)) pendingReq <- mkFIFOF1;
    Bool hasPending = pendingReq.notEmpty;

    FIFO#(Bit#(0)) mainMemReq <- mkBypassFIFO;
    FIFO#(Bit#(32)) dataResponse <- mkBypassFIFO;

    rule doReset(resetState);
        let cacheLine = CacheLine{addr: 0, data: tagged Invalid};
        Bit#(cache_width) address = truncate(resetCounter);
        let req = BRAMRequest{write: True,
                              responseOnWrite: False,
                              address: address,
                              datain: cacheLine};
        cacheLines.portA.request.put(req);
        req.address = address + 1;
        cacheLines.portB.request.put(req);
        resetCounter <= resetCounter + 2;
    endrule

    rule getResponseFromBRAM(!resetState);
        let cacheLine <- cacheLines.portA.response.get;
        let req = pendingReq.first;
        if(req.command == Read)
          begin
            if(cacheLine.addr == req.addr &&& cacheLine.data matches tagged Valid .data)
              begin
                pendingReq.deq;
                dataResponse.enq(data);
              end
            else
              begin
                mainMemReq.enq(?);
              end
          end
        else  // req.command == Write
          begin
            mainMemReq.enq(?);
          end
    endrule

    method Action clear() if (!resetState);
        resetCounter <= 0;
    endmethod

    interface Put prefetch;
        method Action put(CacheLine#(address_width) cacheLine) if (!resetState);
            Bit#(cache_width) address = truncate(cacheLine.addr);
            Bool willConflict = False;
            if(portAaddr.wget matches tagged Valid .x)
                willConflict = x == address;
            if(!willConflict)
              begin
                let bramReq = BRAMRequest{write: True,
                                          responseOnWrite: False,
                                          address: address,
                                          datain: cacheLine};
                cacheLines.portB.request.put(bramReq);
              end
        endmethod
    endinterface

    interface Client busClient;
        interface Get request;
            method ActionValue#(AvalonRequest#(address_width,32)) get();
                let req = pendingReq.first;
                mainMemReq.deq;
                if(req.command == Write)
                    pendingReq.deq;
                return req;
            endmethod
        endinterface
        interface Put response;
            method Action put(Bit#(32) data);
                dataResponse.enq(data);
                pendingReq.deq;
            endmethod
        endinterface
    endinterface

    interface Server thisCache;
        interface Put request;
            method Action put(AvalonRequest#(address_width,32) req) if (!resetState && !hasPending);
                Bit#(cache_width) address = truncate(req.addr);
                portAaddr.wset(address);
                let bramReq = BRAMRequest{write: req.command == Write,
                                          responseOnWrite: True,
                                          address: address,
                                          datain: ?};
                if(req.command == Write)
                    bramReq.datain = CacheLine{addr: req.addr, data: tagged Valid req.data};
                cacheLines.portA.request.put(bramReq);
                pendingReq.enq(req);
            endmethod
        endinterface
        interface Get response = toGet(dataResponse);
    endinterface
endmodule

/*
module mkCache(Cache#(address_width,inst_width,data_width));
    SingleCache#(address_width,inst_width) instSCache <- mkSingleCache;
    SingleCache#(address_width,data_width) dataSCache <- mkSingleCache;

    method Action clear();
        instSCache.clear;
        dataSCache.clear;
    endmethod

    interface Client busClient;
    endinterface

    interface Server instCache = instSCache.thisCache;
    interface Server dataCache = dataSCache.thisCache;
endmodule
*/

