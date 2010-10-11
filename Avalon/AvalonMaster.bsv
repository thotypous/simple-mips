/*
 * Copyright (c) 2008 MIT
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Authors: Kermin Fleming
 *          Paulo Matias
 */

import FIFO::*;
import SpecialFIFOs::*;
import ClientServer::*;
import GetPut::*;
import AvalonCommon::*;

interface AvalonMasterWires#(numeric type address_width, numeric type data_width);
  (* always_ready, always_enabled, prefix="", result="read" *) 
  method Bit#(1) read();
  
  (* always_ready, always_enabled, prefix="", result="write" *) 
  method Bit#(1) write();

  (* always_ready, always_enabled, prefix="", result="address" *) 
  method Bit#(TAdd#(address_width,TSub#(TLog#(data_width),3))) address();

  (* always_ready, always_enabled, prefix="", result="writedata" *) 
  method Bit#(data_width) writedata();  

  (* always_ready, always_enabled, prefix="", result="readdata" *) 
  method Action readdata(Bit#(data_width) readdata);

  (* always_ready, always_enabled, prefix="", result="waitrequest" *) 
  method Action waitrequest(Bit#(1) waitrequest);

  (* always_ready, always_enabled, prefix="", result="readdatavalid" *) 
  method Action readdatavalid(Bit#(1) readdatavalid);
endinterface
  
interface AvalonMaster#(numeric type address_width, numeric type data_width);
  interface AvalonMasterWires#(address_width,data_width) masterWires;
  interface Server#(AvalonRequest#(address_width,data_width), Bit#(data_width)) busServer;
endinterface

module mkAvalonMaster(AvalonMaster#(address_width,data_width)) provisos (Add#(a__, address_width, TAdd#(address_width, TSub#(TLog#(data_width), 3))));
  FIFO#(AvalonRequest#(address_width,data_width)) reqFIFO <- mkBypassFIFO;
  FIFO#(Bit#(data_width)) respFIFO <- mkBypassFIFO;

  RWire#(Bit#(data_width)) readdataIn <- mkRWire;
  PulseWire readdatavalidIn <- mkPulseWire;
  PulseWire waitrequestIn <- mkPulseWire;

  RWire#(Bit#(1)) readOut <- mkRWire;
  RWire#(Bit#(1)) writeOut <- mkRWire;
  RWire#(Bit#(address_width)) addrOut <- mkRWire;
  RWire#(Bit#(data_width)) dataOut <- mkRWire;

  rule ackReq(!waitrequestIn);
    reqFIFO.deq;
  endrule

  rule handleReq;
    let req = reqFIFO.first;
    readOut.wset(pack(req.command == Read));
    writeOut.wset(pack(req.command == Write));
    addrOut.wset(req.addr);
    dataOut.wset(req.data);
  endrule

  rule handleResp(readdatavalidIn);
    respFIFO.enq(fromMaybe(0, readdataIn.wget));
  endrule

  interface AvalonMasterWires masterWires;
    method Bit#(1) read() = fromMaybe(0, readOut.wget);
  
    method Bit#(1) write() = fromMaybe(0, writeOut.wget);

    method Bit#(TAdd#(address_width,TSub#(TLog#(data_width),3))) address() = zeroExtend(fromMaybe(0, addrOut.wget)) << valueof(TSub#(TLog#(data_width),3));

    method Bit#(data_width) writedata() = fromMaybe(0, dataOut.wget);

    method Action readdata(Bit#(data_width) readdataNew);
      readdataIn.wset(readdataNew);
    endmethod

    method Action waitrequest(Bit#(1) waitrequestNew);
      if(waitrequestNew == 1)
        waitrequestIn.send;
    endmethod

    method Action readdatavalid(Bit#(1) readdatavalidNew);
      if(readdatavalidNew == 1)
        readdatavalidIn.send;
    endmethod
  endinterface

  interface Server busServer;
    interface Put request = toPut(reqFIFO);
    interface Get response = toGet(respFIFO);
  endinterface
endmodule

