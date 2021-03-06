import ClientServer::*;
import GetPut::*;
import BRAM::*;
import FIFO::*;
import Connectable::*;
import AvalonCommon::*;
import AvalonMaster::*;

module mkAvalonMasterEmu(AvalonMaster#(address_width,data_width));
  BRAM_Configure cfg = defaultValue;
  cfg.loadFormat = tagged Hex "program.mem";
  BRAM1Port#(Bit#(address_width), Bit#(data_width)) bram <- mkBRAM1Server(cfg);
  FIFO#(Bit#(data_width)) delay_stage01 <- mkFIFO;
  FIFO#(Bit#(data_width)) delay_stage02 <- mkFIFO;

  Reg#(Bit#(12)) irqEmuCycle <- mkReg(0);

  mkConnection(bram.portA.response,  toPut(delay_stage01));
  mkConnection(toGet(delay_stage01), toPut(delay_stage02));

  rule incCycle;
      let irqEmu <- $test$plusargs("irqemu");
      if(irqEmu)
          irqEmuCycle <= irqEmuCycle + 1;
  endrule

  interface AvalonMasterWires masterWires;
    method Bit#(1) read() = 0;
    method Bit#(1) write() = 0;
    method Bit#(TAdd#(address_width,TSub#(TLog#(data_width),3))) address() = 0;
    method Bit#(data_width) writedata() = 0;
    method Action readdata(Bit#(data_width) readdataNew) = noAction;
    method Action waitrequest(Bit#(1) waitrequestNew) = noAction;
    method Action readdatavalid(Bit#(1) readdatavalidNew) = noAction;
    method Action irq(Bit#(32) irqNew) = noAction;
  endinterface

  interface Server busServer;
    interface Put request;
      method Action put(AvalonRequest#(address_width,data_width) req);
        bram.portA.request.put(BRAMRequest{write: req.command==Write,
                                           responseOnWrite: False,
                                           address: req.addr,
                                           datain: req.data});
      endmethod
    endinterface
    interface Get response = toGet(delay_stage02);
  endinterface
  
  interface Get irqGet;
    method ActionValue#(Bit#(32)) get() if (irqEmuCycle == 4095);
      $display("[Emu] Simulating IRQ");
      return 32'h01010101;
    endmethod
  endinterface
endmodule

