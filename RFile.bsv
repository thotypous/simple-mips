import RegFile::*;
import Instructions::*;
import Trace::*;

interface RFile;
    method Action wr(Ridx ridx, Bit#(32) data);
    method Bit#(32) rd1(Ridx ridx);
    method Bit#(32) rd2(Ridx ridx);
endinterface

module mkRFile(RFile);
    RegFile#(Ridx,Bit#(32)) rf <- mkRegFileWCF(0,31);
    RWire#(Tuple2#(Ridx,Bit#(32))) rwout <- mkRWire;
    method Action wr(Ridx ridx, Bit#(32) data);
        trace($format("[RFile] r%0d <= 0x%h", ridx, data));
        rf.upd(ridx, data);
        rwout.wset(tuple2(ridx, data));
    endmethod
    method Bit#(32) rd1(Ridx ridx);
        case (rwout.wget) matches
            tagged Valid {.wr,.d}: return (ridx == 0) ? 0 : (wr==ridx) ? d : rf.sub(ridx);
            tagged Invalid: return (ridx == 0) ? 0 : rf.sub(ridx);
        endcase
    endmethod
    method Bit#(32) rd2(Ridx ridx);
        case (rwout.wget) matches
            tagged Valid {.wr,.d}: return (ridx == 0) ? 0 : (wr==ridx) ? d : rf.sub(ridx);
            tagged Invalid: return (ridx == 0) ? 0 : rf.sub(ridx);
        endcase
    endmethod
endmodule

