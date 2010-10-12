import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import BRAM::*;
import Connectable::*;
import AvalonCommon::*;

export Cache(..);
export mkCache;

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

module mkSingleCache#(function Bool ignoreCache(Bit#(address_width) addr)) (SingleCache#(address_width,cache_width))
                    provisos (Add#(a__, cache_width, address_width),
                              Add#(b__, cache_width, TAdd#(cache_width, 1)));
    BRAM_Configure cfg = defaultValue;
    BRAM2Port#(Bit#(cache_width), CacheLine#(address_width)) cacheLines <- mkBRAM2Server(cfg);
    RWire#(Bit#(cache_width)) portAaddr <- mkRWire;

    Reg#(Bit#(TAdd#(cache_width,1))) resetCounter <- mkReg(0);
    Integer resetLastBit = valueof(cache_width);
    Bool resetState = resetCounter[resetLastBit] == 1'b0;

    FIFO#(AvalonRequest#(address_width,32)) pendingReq <- mkPipelineFIFO;

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
            if(!ignoreCache(req.addr) && cacheLine.addr == req.addr &&& cacheLine.data matches tagged Valid .data)
              begin
                dataResponse.enq(data);
                pendingReq.deq;
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
                let req = pendingReq.first;
                Bit#(cache_width) address = truncate(req.addr);
                Bool willConflict = False;
                if(portAaddr.wget matches tagged Valid .x)
                    willConflict = x == address;
                if(!willConflict)
                  begin
                    let cacheLine = CacheLine{addr: req.addr, data: tagged Valid data};
                    let bramReq = BRAMRequest{write: True,
                                              responseOnWrite: False,
                                              address: address,
                                              datain: cacheLine};
                    cacheLines.portB.request.put(bramReq);
                  end
                dataResponse.enq(data);
                pendingReq.deq;
            endmethod
        endinterface
    endinterface

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

    interface Server thisCache;
        interface Put request;
            method Action put(AvalonRequest#(address_width,32) req) if (!resetState);
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

typedef enum {
  Instruction,
  Data,
  InstructionPrefetch
} CacheReqType deriving (Bits,Eq);

module mkCache#(function Bool ignoreCache(Bit#(address_width) addr)) (Cache#(address_width,inst_width,data_width))
              provisos (Add#(a__, data_width, address_width),
                        Add#(b__, data_width, TAdd#(data_width, 1)),
                        Add#(c__, inst_width, address_width),
                        Add#(d__, inst_width, TAdd#(inst_width, 1)));
    function ignoreNever(Bit#(address_width) addr) = False;
    SingleCache#(address_width,inst_width) instSCache <- mkSingleCache(ignoreNever);
    SingleCache#(address_width,data_width) dataSCache <- mkSingleCache(ignoreCache);

    FIFOF#(AvalonRequest#(address_width,32)) instReq <- mkBypassFIFOF;
    FIFOF#(AvalonRequest#(address_width,32)) dataReq <- mkBypassFIFOF;

    Reg#(Bit#(1)) arbitration <- mkReg(0);

    FIFO#(AvalonRequest#(address_width,32)) outReq <- mkBypassFIFO;
    FIFO#(CacheReqType) pendingReq <- mkFIFO;
    FIFO#(Bit#(32)) inResp <- mkBypassFIFO;

    Reg#(Bit#(address_width)) nextPrefetch <- mkReg('h100);
    FIFOF#(Bit#(address_width)) pendingPrefetch <- mkFIFOF1;

    mkConnection(instSCache.busClient.request, toPut(instReq));
    mkConnection(dataSCache.busClient.request, toPut(dataReq));

    (* mutually_exclusive = "peekInstReq, peekDataReq, doInstPrefetch" *)

    rule peekInstReq(instReq.notEmpty && (arbitration == 0 || !dataReq.notEmpty));
        arbitration <= ~arbitration;
        nextPrefetch <= instReq.first.addr + 3;
        outReq.enq(instReq.first);
        if(instReq.first.command != Read)
          begin
            $display("Cache error: Trying to write to the instruction cache");
            $finish();
          end
        pendingReq.enq(Instruction);
        instReq.deq;
    endrule

    rule peekDataReq(dataReq.notEmpty && (arbitration == 1 || !instReq.notEmpty));
        arbitration <= ~arbitration;
        outReq.enq(dataReq.first);
        if(dataReq.first.command == Read)
            pendingReq.enq(Data);
        dataReq.deq;
    endrule

    rule doInstPrefetch(!instReq.notEmpty && !dataReq.notEmpty);
        outReq.enq(AvalonRequest{command: Read, addr: nextPrefetch, data: ?});
        pendingReq.enq(InstructionPrefetch);
        pendingPrefetch.enq(nextPrefetch);
        nextPrefetch <= nextPrefetch + 1;
    endrule

    (* mutually_exclusive = "peekInstResp, peekDataResp, peekInstPrefetchResp" *)

    rule peekInstResp(pendingReq.first == Instruction);
        instSCache.busClient.response.put(inResp.first);
        inResp.deq;
        pendingReq.deq;
    endrule

    rule peekDataResp(pendingReq.first == Data);
        dataSCache.busClient.response.put(inResp.first);
        inResp.deq;
        pendingReq.deq;
    endrule

    rule peekInstPrefetchResp(pendingReq.first == InstructionPrefetch);
        let cacheLine = CacheLine{addr: pendingPrefetch.first,
                                  data: tagged Valid inResp.first};
        instSCache.prefetch.put(cacheLine);
        inResp.deq;
        pendingPrefetch.deq;
        pendingReq.deq;
    endrule

    method Action clear();
        instSCache.clear;
        dataSCache.clear;
    endmethod

    interface Client busClient;
        interface Get request = toGet(outReq);
        interface Put response = toPut(inResp);
    endinterface

    interface Server instCache = instSCache.thisCache;
    interface Server dataCache = dataSCache.thisCache;
endmodule

