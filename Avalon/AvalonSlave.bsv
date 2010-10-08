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
 * Author: Kermin Fleming
 */

import FIFO::*;
import FIFOF::*;
import ClientServer::*;
import GetPut::*;
import AvalonCommon::*;

interface AvalonSlaveWires#(numeric type address_width, numeric type data_width);
  (* always_ready, always_enabled, prefix="", result="read" *) 
  method Action read(Bit#(1) read);
  
  (* always_ready, always_enabled, prefix="", result="write" *) 
  method Action write(Bit#(1) write);

  (* always_ready, always_enabled, prefix="", result="address" *) 
  method Action address(Bit#(address_width) address);

  (* always_ready, always_enabled, prefix="", result="writedata" *) 
  method Action writedata(Bit#(data_width) writedata);  

  (* always_ready, always_enabled, prefix="", result="readdata" *) 
  method Bit#(data_width) readdata();

  (* always_ready, always_enabled, prefix="", result="waitrequest" *) 
  method Bit#(1) waitrequest();

  (* always_ready, always_enabled, prefix="", result="readdatavalid" *) 
  method Bit#(1) readdatavalid();
endinterface
  
interface AvalonSlave#(numeric type address_width, numeric type data_width);
  interface AvalonSlaveWires#(address_width,data_width) slaveWires;
  interface Client#(AvalonRequest#(address_width,data_width), Bit#(data_width)) busClient;
endinterface

module mkAvalonSlave(AvalonSlave#(address_width,data_width));
  RWire#(Bit#(1)) readInValue <- mkRWire;
  RWire#(Bit#(1)) writeInValue <- mkRWire;
  RWire#(Bit#(address_width)) addressInValue <- mkRWire;
  RWire#(Bit#(data_width)) readdataOutValue <- mkRWire;
  RWire#(Bit#(data_width)) writedataInValue <- mkRWire;
  PulseWire putResponseCalled <- mkPulseWire;

  // In avalon read/write asserted for a single cycle unless 
  // waitreq also asserted.
  
  FIFOF#(AvalonRequest#(address_width,data_width)) reqFIFO <- mkFIFOF;

  rule produceRequest;
    // Reads and writes are assumed not to occur simultaneously.  
    if(fromMaybe(0, readInValue.wget) == 1) 
       reqFIFO.enq(AvalonRequest{addr: fromMaybe(0, addressInValue.wget()),
                                 data: ?, 
                                 command: Read});
    else if(fromMaybe(0, writeInValue.wget) == 1) 
       reqFIFO.enq(AvalonRequest{addr: fromMaybe(0, addressInValue.wget()),
                                 data: fromMaybe(0, writedataInValue.wget()), 
                                 command: Write});
  endrule

  interface AvalonSlaveWires slaveWires;
    method Action read(Bit#(1) readIn);
      readInValue.wset(readIn);  
    endmethod

    method Action write(Bit#(1) writeIn);
      writeInValue.wset(writeIn);  
    endmethod

    method Action address(Bit#(address_width) addressIn);
      addressInValue.wset(addressIn);  
    endmethod

    method Bit#(data_width) readdata();  
      return fromMaybe(0, readdataOutValue.wget);
    endmethod

    method Action writedata(Bit#(data_width) writedataValue);
      writedataInValue.wset(writedataValue);
    endmethod

    method Bit#(1) waitrequest();
      return (reqFIFO.notFull)?0:1;
    endmethod

    method Bit#(1) readdatavalid();
      return (putResponseCalled)?1:0;
    endmethod
  endinterface

  interface Client busClient;
    interface Get request;
      method ActionValue#(AvalonRequest#(address_width,data_width)) get();
        reqFIFO.deq;
        return reqFIFO.first;
      endmethod
    endinterface 

    interface Put response;
      method Action put(Bit#(data_width) data);
        readdataOutValue.wset(data);
        putResponseCalled.send;
      endmethod
    endinterface
  endinterface
endmodule

