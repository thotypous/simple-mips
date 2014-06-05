import FShow::*;

typedef Bit#( 5) Ridx;  // Register index
typedef Bit#(16) Immd;  // Immediate
typedef Bit#( 5) Sham;  // Shift ammount
typedef Bit#(16) Joff;  // Jump offset
typedef Bit#(26) Jtgt;  // Jump target
typedef Bit#(16) Moff;  // Memory offset
typedef Bit#(20) Sysc;  // Syscall code

typedef union tagged {
    // Arithmetic Operations
    struct { Ridx rs; Ridx rt; Ridx rd; } ADD;
    struct { Ridx rs; Ridx rt; Immd im; } ADDI;
    struct { Ridx rs; Ridx rt; Immd im; } ADDIU;
    struct { Ridx rs; Ridx rt; Ridx rd; } ADDU;
    struct {          Ridx rt; Immd im; } LUI;
    struct { Ridx rs; Ridx rt; Ridx rd; } SUB;
    struct { Ridx rs; Ridx rt; Ridx rd; } SUBU;
    
    // Shift and Rotate Operations
    struct { Ridx rt; Ridx rd; Sham sa; } SLL;
    struct { Ridx rs; Ridx rt; Ridx rd; } SLLV;
    struct { Ridx rt; Ridx rd; Sham sa; } SRA;
    struct { Ridx rs; Ridx rt; Ridx rd; } SRAV;
    struct { Ridx rt; Ridx rd; Sham sa; } SRL;
    struct { Ridx rs; Ridx rt; Ridx rd; } SRLV;

    // Logical and Bit-Field Operations
    struct { Ridx rs; Ridx rt; Ridx rd; } AND;
    struct { Ridx rs; Ridx rt; Immd im; } ANDI;
    struct { Ridx rs; Ridx rt; Ridx rd; } NOR;
    struct { Ridx rs; Ridx rt; Ridx rd; } OR;
    struct { Ridx rs; Ridx rt; Immd im; } ORI;
    struct { Ridx rs; Ridx rt; Ridx rd; } XOR;
    struct { Ridx rs; Ridx rt; Immd im; } XORI;

    // Condition Testing and Conditional Move Operations
    struct { Ridx rd; Ridx rs; Ridx rt; } SLT;
    struct { Ridx rs; Ridx rt; Immd im; } SLTI;
    struct { Ridx rs; Ridx rt; Immd im; } SLTIU;
    struct { Ridx rs; Ridx rt; Ridx rd; } SLTU;

    // Multiply and divide operations
    struct { Ridx rs; Ridx rt;          } DIV;
    struct { Ridx rs; Ridx rt;          } DIVU;
    struct { Ridx rs; Ridx rt;          } MULT;
    struct { Ridx rs; Ridx rt;          } MULTU;
    
    // Accumulator Access Operations
    struct {                   Ridx rd; } MFHI;
    struct {                   Ridx rd; } MFLO;

    // Jumps and Branches
    struct { Ridx rs; Ridx rt; Joff of; } BEQ;
    struct { Ridx rs;          Joff of; } BGEZ;
    struct { Ridx rs;          Joff of; } BGTZ;
    struct { Ridx rs;          Joff of; } BLEZ;
    struct { Ridx rs;          Joff of; } BLTZ;
    struct { Ridx rs; Ridx rt; Joff of; } BNE;
    struct {                   Jtgt tg; } J;
    struct {                   Jtgt tg; } JAL;
    struct { Ridx rs;          Ridx rd; } JALR;
    struct { Ridx rs;                   } JR;

    // Load and Store Operations
    struct { Ridx rb; Ridx rt; Moff of; } LB;
    struct { Ridx rb; Ridx rt; Moff of; } LBU;
    struct { Ridx rb; Ridx rt; Moff of; } LH;
    struct { Ridx rb; Ridx rt; Moff of; } LHU;
    struct { Ridx rb; Ridx rt; Moff of; } LW;
    struct { Ridx rb; Ridx rt; Moff of; } SB;
    struct { Ridx rb; Ridx rt; Moff of; } SH;
    struct { Ridx rb; Ridx rt; Moff of; } SW;

    // Instructions that deviate from the standard behaviour
    struct { Sysc sc;                   } SYSC;

    void ILLEGAL;
} Instr deriving(Eq);

typedef Bit#(6) Opcode;

Opcode opSPECIAL = 6'b000000;

typedef Bit#(6) SpecOp;

SpecOp soADD     = 6'b100000;
SpecOp soADDU    = 6'b100001;
SpecOp soSUB     = 6'b100010;
SpecOp soSUBU    = 6'b100011;
SpecOp soSLL     = 6'b000000;
SpecOp soSLLV    = 6'b000100;
SpecOp soSRA     = 6'b000011;
SpecOp soSRAV    = 6'b000111;
SpecOp soSRL     = 6'b000010;
SpecOp soSRLV    = 6'b000110;
SpecOp soAND     = 6'b100100;
SpecOp soNOR     = 6'b100111;
SpecOp soOR      = 6'b100101;
SpecOp soXOR     = 6'b100110;
SpecOp soSLT     = 6'b101010;
SpecOp soSLTU    = 6'b101011;
SpecOp soDIV     = 6'b011010;
SpecOp soDIVU    = 6'b011011;
SpecOp soMULT    = 6'b011000;
SpecOp soMULTU   = 6'b011001;
SpecOp soMFHI    = 6'b010000;
SpecOp soMFLO    = 6'b010010;
SpecOp soJALR    = 6'b001001;
SpecOp soJR      = 6'b001000;
SpecOp soSYSC    = 6'b001100;

Opcode opADDI    = 6'b001000;
Opcode opADDIU   = 6'b001001;
Opcode opLUI     = 6'b001111;
Opcode opANDI    = 6'b001100;
Opcode opORI     = 6'b001101;
Opcode opXORI    = 6'b001110;
Opcode opSLTI    = 6'b001010;
Opcode opSLTIU   = 6'b001011;
Opcode opBEQ     = 6'b000100;

Opcode opREGIMM  = 6'b000001;

typedef Bit#(5) RImmOp;

RImmOp roBGEZ    = 5'b00001;
RImmOp roBLTZ    = 5'b00000;

Opcode opBGTZ    = 6'b000111;
Opcode opBLEZ    = 6'b000110;
Opcode opBNE     = 6'b000101;
Opcode opJ       = 6'b000010;
Opcode opJAL     = 6'b000011;
Opcode opLB      = 6'b100000;
Opcode opLBU     = 6'b100100;
Opcode opLH      = 6'b100001;
Opcode opLHU     = 6'b100101;
Opcode opLW      = 6'b100011;
Opcode opSB      = 6'b101000;
Opcode opSH      = 6'b101001;
Opcode opSW      = 6'b101011;

instance Bits#(Instr, 32);
    
    function Bit#(32) pack(Instr instr);
        case (instr) matches
            tagged ADD   .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soADD   };
            tagged ADDI  .s: return { opADDI,    s.rs, s.rt, s.im                };
            tagged ADDIU .s: return { opADDIU,   s.rs, s.rt, s.im                };
            tagged ADDU  .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soADDU  };
            tagged LUI   .s: return { opLUI,     5'b0, s.rt, s.im                };
            tagged SUB   .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSUB   };
            tagged SUBU  .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSUBU  };
            tagged SLL   .s: return { opSPECIAL, 5'b0, s.rt, s.rd, s.sa, soSLL   };
            tagged SLLV  .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSLLV  };
            tagged SRA   .s: return { opSPECIAL, 5'b0, s.rt, s.rd, s.sa, soSRA   };
            tagged SRAV  .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSRAV  };
            tagged SRL   .s: return { opSPECIAL, 5'b0, s.rt, s.rd, s.sa, soSRL   };
            tagged SRLV  .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSRLV  };
            tagged AND   .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soAND   };
            tagged ANDI  .s: return { opANDI,    s.rs, s.rt, s.im                };
            tagged NOR   .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soNOR   };
            tagged OR    .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soOR    };
            tagged ORI   .s: return { opORI,     s.rs, s.rt, s.im                };
            tagged XOR   .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soXOR   };
            tagged XORI  .s: return { opXORI,    s.rs, s.rt, s.im                };
            tagged SLT   .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSLT   };
            tagged SLTI  .s: return { opSLTI,    s.rs, s.rt, s.im                };
            tagged SLTIU .s: return { opSLTIU,   s.rs, s.rt, s.im                };
            tagged SLTU  .s: return { opSPECIAL, s.rs, s.rt, s.rd, 5'b0, soSLTU  };
            tagged DIV   .s: return { opSPECIAL, s.rs, s.rt,      10'b0, soDIV   };
            tagged DIVU  .s: return { opSPECIAL, s.rs, s.rt,      10'b0, soDIVU  };
            tagged MULT  .s: return { opSPECIAL, s.rs, s.rt,      10'b0, soMULT  };
            tagged MULTU .s: return { opSPECIAL, s.rs, s.rt,      10'b0, soMULTU };
            tagged MFHI  .s: return { opSPECIAL,10'b0, s.rd,       5'b0, soMFHI  };
            tagged MFLO  .s: return { opSPECIAL,10'b0, s.rd,       5'b0, soMFLO  };
            tagged BEQ   .s: return { opBEQ,     s.rs, s.rt,       s.of          };
            tagged BGEZ  .s: return { opREGIMM,  s.rs, roBGEZ,     s.of          };
            tagged BGTZ  .s: return { opBGTZ,    s.rs, 5'b0,       s.of          };
            tagged BLEZ  .s: return { opBLEZ,    s.rs, 5'b0,       s.of          };
            tagged BLTZ  .s: return { opREGIMM,  s.rs, roBLTZ,     s.of          };
            tagged BNE   .s: return { opBNE,     s.rs, s.rt,       s.of          };
            tagged J     .s: return { opJ,       s.tg                            };
            tagged JAL   .s: return { opJAL,     s.tg                            };
            tagged JALR  .s: return { opSPECIAL, s.rs, 5'b0, s.rd, 5'b0, soJALR  };
            tagged JR    .s: return { opSPECIAL, s.rs,            15'b0, soJR    };
            tagged LB    .s: return { opLB,      s.rb, s.rt, s.of                };
            tagged LBU   .s: return { opLBU,     s.rb, s.rt, s.of                };
            tagged LH    .s: return { opLH,      s.rb, s.rt, s.of                };
            tagged LHU   .s: return { opLHU,     s.rb, s.rt, s.of                };
            tagged LW    .s: return { opLW,      s.rb, s.rt, s.of                };
            tagged SB    .s: return { opSB,      s.rb, s.rt, s.of                };
            tagged SH    .s: return { opSB,      s.rb, s.rt, s.of                };
            tagged SW    .s: return { opSW,      s.rb, s.rt, s.of                };
            tagged SYSC  .s: return { opSPECIAL, s.sc,                   soSYSC  };
            tagged ILLEGAL : return 0;
        endcase
    endfunction

    function Instr unpack(Bit#(32) instr);
        let op = instr[31:26];
        let rs = instr[25:21];
        let rt = instr[20:16];
        let rd = instr[15:11];
        let sa = instr[10: 6];
        let so = instr[ 5: 0];
        let im = instr[15: 0];
        let tg = instr[25: 0];
        let ro = instr[20:16];
        let of = instr[15: 0];
        let rb = instr[25:21];
        let sc = instr[25: 6];

        case(op)
            opSPECIAL:
                case(so)
                    soADD:   return ADD   {rs:rs, rt:rt, rd:rd};
                    soADDU:  return ADDU  {rs:rs, rt:rt, rd:rd};
                    soSUB:   return SUB   {rs:rs, rt:rt, rd:rd};
                    soSUBU:  return SUBU  {rs:rs, rt:rt, rd:rd};
                    soSLL:   return SLL   {rt:rt, rd:rd, sa:sa};
                    soSLLV:  return SLLV  {rs:rs, rt:rt, rd:rd};
                    soSRA:   return SRA   {rt:rt, rd:rd, sa:sa};
                    soSRAV:  return SRAV  {rs:rs, rt:rt, rd:rd};
                    soSRL:   return SRL   {rt:rt, rd:rd, sa:sa};
                    soSRLV:  return SRLV  {rs:rs, rt:rt, rd:rd};
                    soAND:   return AND   {rs:rs, rt:rt, rd:rd};
                    soNOR:   return NOR   {rs:rs, rt:rt, rd:rd};
                    soOR:    return OR    {rs:rs, rt:rt, rd:rd};
                    soXOR:   return XOR   {rs:rs, rt:rt, rd:rd};
                    soSLT:   return SLT   {rs:rs, rt:rt, rd:rd};
                    soSLTU:  return SLTU  {rs:rs, rt:rt, rd:rd};
                    soDIV:   return DIV   {rs:rs, rt:rt       };
                    soDIVU:  return DIVU  {rs:rs, rt:rt       };
                    soMULT:  return MULT  {rs:rs, rt:rt       };
                    soMULTU: return MULTU {rs:rs, rt:rt       };
                    soMFHI:  return MFHI  {rd:rd              };
                    soMFLO:  return MFLO  {rd:rd              };
                    soJALR:  return JALR  {rs:rs, rd:rd       };
                    soJR:    return JR    {rs:rs              };
                    soSYSC:  return SYSC  {sc:sc              };
                endcase
            opADDI:  return ADDI  { rs:rs, rt:rt, im:im };
            opADDIU: return ADDIU { rs:rs, rt:rt, im:im };
            opLUI:   return LUI   { rt:rt, im:im        };
            opANDI:  return ANDI  { rs:rs, rt:rt, im:im };
            opORI:   return ORI   { rs:rs, rt:rt, im:im };
            opXORI:  return XORI  { rs:rs, rt:rt, im:im };
            opSLTI:  return SLTI  { rs:rs, rt:rt, im:im };
            opSLTIU: return SLTIU { rs:rs, rt:rt, im:im };
            opBEQ:   return BEQ   { rs:rs, rt:rt, of:of };
            opREGIMM:
                case(ro)
                    roBGEZ: return BGEZ { rs:rs, of:of  };
                    roBLTZ: return BLTZ { rs:rs, of:of  };
                endcase
            opBGTZ:  return BGTZ  { rs:rs, of:of        };
            opBLEZ:  return BLEZ  { rs:rs, of:of        };
            opBNE:   return BNE   { rs:rs, rt:rt, of:of };
            opJ:     return J     { tg:tg               };
            opJAL:   return JAL   { tg:tg               };
            opLB:    return LB    { rb:rb, rt:rt, of:of };
            opLBU:   return LBU   { rb:rb, rt:rt, of:of };
            opLH:    return LH    { rb:rb, rt:rt, of:of };
            opLHU:   return LHU   { rb:rb, rt:rt, of:of };
            opLW:    return LW    { rb:rb, rt:rt, of:of };
            opSB:    return SB    { rb:rb, rt:rt, of:of };
            opSH:    return SH    { rb:rb, rt:rt, of:of };
            opSW:    return SW    { rb:rb, rt:rt, of:of };
            default: return ILLEGAL;
        endcase
    endfunction

endinstance

instance FShow#(Instr);
    function Fmt fshow(Instr instr);
        case (instr) matches
            tagged ADD   .s: return $format("add r%0d, r%0d, r%0d",   s.rd, s.rs, s.rt);
            tagged ADDI  .s: return $format("addi r%0d, r%0d, 0x%x",  s.rt, s.rs, s.im);
            tagged ADDIU .s: return $format("addiu r%0d, r%0d, 0x%x", s.rt, s.rs, s.im);
            tagged ADDU  .s: return $format("addu r%0d, r%0d, r%0d",  s.rd, s.rs, s.rt);
            tagged LUI   .s: return $format("lui r%0d, 0x%x",         s.rt, s.im      );
            tagged SUB   .s: return $format("sub r%0d, r%0d, r%0d",   s.rd, s.rs, s.rt);
            tagged SUBU  .s: return $format("subu r%0d, r%0d, r%0d",  s.rd, s.rs, s.rt);
            tagged SLL   .s: return $format("sll r%0d, r%0d, %0d",    s.rd, s.rt, s.sa);
            tagged SLLV  .s: return $format("sllv r%0d, r%0d, r%0d",  s.rd, s.rt, s.rs);
            tagged SRA   .s: return $format("sra r%0d, r%0d, %0d",    s.rd, s.rt, s.sa);
            tagged SRAV  .s: return $format("srav r%0d, r%0d, r%0d",  s.rd, s.rt, s.rs);
            tagged SRL   .s: return $format("srl r%0d, r%0d, %0d",    s.rd, s.rt, s.sa);
            tagged SRLV  .s: return $format("srlv r%0d, r%0d, r%0d",  s.rd, s.rt, s.rs);
            tagged AND   .s: return $format("and r%0d, r%0d, r%0d",   s.rd, s.rs, s.rt);
            tagged ANDI  .s: return $format("andi r%0d, r%0d, 0x%x",  s.rt, s.rs, s.im);
            tagged NOR   .s: return $format("nor r%0d, r%0d, r%0d",   s.rd, s.rs, s.rt);
            tagged OR    .s: return $format("or r%0d, r%0d, r%0d",    s.rd, s.rs, s.rt);
            tagged ORI   .s: return $format("ori r%0d, r%0d, 0x%x",   s.rt, s.rs, s.im);
            tagged XOR   .s: return $format("xor r%0d, r%0d, r%0d",   s.rd, s.rs, s.rt);
            tagged XORI  .s: return $format("xori r%0d, r%0d, 0x%x",  s.rt, s.rs, s.im);
            tagged SLT   .s: return $format("slt r%0d, r%0d, r%0d",   s.rd, s.rs, s.rt);
            tagged SLTI  .s: return $format("slti r%0d, r%0d, 0x%x",  s.rt, s.rs, s.im);
            tagged SLTIU .s: return $format("sltiu r%0d, r%0d, 0x%x", s.rt, s.rs, s.im);
            tagged SLTU  .s: return $format("sltu r%0d, r%0d, r%0d",  s.rd, s.rs, s.rt);
            tagged DIV   .s: return $format("div r%0d, r%0d",         s.rs, s.rt      );
            tagged DIVU  .s: return $format("divu r%0d, r%0d",        s.rs, s.rt      );
            tagged MULT  .s: return $format("mult r%0d, r%0d",        s.rs, s.rt      );
            tagged MULTU .s: return $format("multu r%0d, r%0d",       s.rs, s.rt      );
            tagged MFHI  .s: return $format("mfhi r%0d",              s.rd            );
            tagged MFLO  .s: return $format("mflo r%0d",              s.rd            );
            tagged BEQ   .s: return $format("beq r%0d, r%0d, 0x%x",   s.rs, s.rt, s.of);
            tagged BGEZ  .s: return $format("bgez r%0d, 0x%x",        s.rs, s.of      );
            tagged BGTZ  .s: return $format("bgtz r%0d, 0x%x",        s.rs, s.of      );
            tagged BLEZ  .s: return $format("blez r%0d, 0x%x",        s.rs, s.of      );
            tagged BLTZ  .s: return $format("bltz r%0d, 0x%x",        s.rs, s.of      );
            tagged BNE   .s: return $format("bne r%0d, r%0d, 0x%x",   s.rs, s.rt, s.of);
            tagged J     .s: return $format("j 0x%x",                 s.tg            );
            tagged JAL   .s: return $format("jal 0x%x",               s.tg            );
            tagged JALR  .s: return $format("jalr r%0d, r%0d",        s.rd, s.rs      );
            tagged JR    .s: return $format("jr r%0d",                s.rs            );
            tagged LB    .s: return $format("lb r%0d, 0x%x(r%0d)",    s.rt, s.of, s.rb);
            tagged LBU   .s: return $format("lbu r%0d, 0x%x(r%0d)",   s.rt, s.of, s.rb);
            tagged LH    .s: return $format("lh r%0d, 0x%x(r%0d)",    s.rt, s.of, s.rb);
            tagged LHU   .s: return $format("lhu r%0d, 0x%x(r%0d)",   s.rt, s.of, s.rb);
            tagged LW    .s: return $format("lw r%0d, 0x%x(r%0d)",    s.rt, s.of, s.rb);
            tagged SB    .s: return $format("sb r%0d, 0x%x(r%0d)",    s.rt, s.of, s.rb);
            tagged SH    .s: return $format("sh r%0d, 0x%x(r%0d)",    s.rt, s.of, s.rb);
            tagged SW    .s: return $format("sw r%0d, 0x%x(r%0d)",    s.rt, s.of, s.rb);
            tagged SYSC  .s: return $format("syscall 0x%h",           s.sc            );
            tagged ILLEGAL : return $format("illegal instruction");
        endcase
    endfunction
endinstance

