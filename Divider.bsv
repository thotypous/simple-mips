import ClientServer::*;
import GetPut::*;

export Divider(..);
export DividerReq(..);
export DividerResp(..);
export mkDivider;

typedef Tuple3#(Bit#(32),Bit#(32),Bool) DividerReq;
typedef Tuple2#(Bit#(32),Bit#(32)) DividerResp;
typedef Server#(DividerReq, DividerResp) Divider;

typedef Tuple5#(Bit#(32),Bit#(32),Bit#(63),Bit#(63),Bool) PassTuple;

function PassTuple divisionSteps(Integer steps, Bit#(32) oldq, Bit#(32) oldt, Bit#(63) oldr, Bit#(63) oldp);
    if(steps == 0)
      begin
        return tuple5(oldq,oldt,oldr,oldp,False);
      end
    else
      begin
        match{.q,.t,.r,.p,.done} = divisionSteps(steps - 1, oldq,oldt,oldr,oldp);
        if(done)
          begin
            return tuple5(q,t,r,p,done);
          end
        else
          begin
            p = p >> 1;
            t = t >> 1;
            if(p <= r)
              begin
                q = q + t;
                r = r - p;
              end
            done = t[0] == 1'b1;
            return tuple5(q,t,r,p,done);
          end
      end
endfunction

module mkDivider(Divider);
    Reg#(Bool) done <- mkReg(True);
    Reg#(Bool) canGet <- mkReg(False);
    
    Reg#(Bool) qneg <- mkRegU;
    Reg#(Bool) rneg <- mkRegU;

    Reg#(Bit#(32)) q <- mkRegU;
    Reg#(Bit#(32)) t <- mkRegU;
    Reg#(Bit#(63)) r <- mkRegU;
    Reg#(Bit#(63)) p <- mkRegU;

    rule divisionCycle(!done);
        match {.newq,.newt,.newr,.newp,.newdone} = divisionSteps(4, q,t,r,p);
        q <= newq;
        t <= newt;
        r <= newr;
        p <= newp;
        done <= newdone;
    endrule

    interface Put request;
        method Action put(DividerReq req) if(done);
            match {.a,.b,.signedDiv} = req;
            if(signedDiv)
              begin
                Int#(32) aint = unpack(a), bint = unpack(b);
                qneg <= (pack(aint<0) ^ pack(bint<0)) == 1'b1;
                rneg <= aint<0;
                a = aint < 0 ? pack(-aint) : a;
                b = bint < 0 ? pack(-bint) : b;
              end
            else
              begin
                qneg <= False;
                rneg <= False;
              end
            t <= 1<<31;
            p <= {b, 31'b0};
            q <= 0;
            r <= {31'b0, a};
            if(b == 0)
                $display("Divider error: Division by zero!");
            done <= b == 0; // Avoid freeze on division by zero
            canGet <= True;
        endmethod
    endinterface

    interface Get response;
        method ActionValue#(DividerResp) get() if(done && canGet);
            Bit#(32) qresp = q;
            Bit#(32) rresp = truncate(r);
            canGet <= False;
            if(qneg)
              begin
                Int#(32) qint = -unpack({1'b0, q[30:0]});
                qresp = pack(qint);
              end
            if(rneg)
              begin
                Int#(32) rint = -unpack({1'b0, r[30:0]});
                rresp = pack(rint);
              end
            return tuple2(rresp, qresp);
        endmethod
    endinterface
endmodule

