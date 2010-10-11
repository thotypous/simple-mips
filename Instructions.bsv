import FShow::*;

typedef  Bit#( 5) Ridx;  // Register index
typedef UInt#(16) Uimm;  // Unsigned immediate
typedef  Int#(16) Simm;  // Signed immediate
typedef  Bit#( 5) Sham;  // Shift ammount
typedef  Bit#(16) Joff;  // Jump offset
typedef  Bit#(26) Jtgt;  // Jump target
typedef  Bit#(16) Moff;  // Memory offset

typedef union tagged {
    // Arithmetic Operations
    struct { Ridx rs; Ridx rt; Ridx rd; } ADD;
    struct { Ridx rs; Ridx rt; Simm im; } ADDI;
    struct { Ridx rs; Ridx rt; Simm im; } ADDIU;
    struct { Ridx rs; Ridx rt; Ridx rd; } ADDU;
    struct {          Ridx rt; Uimm im; } LUI;
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
    struct { Ridx rs; Ridx rt; Uimm im; } ANDI;
    struct { Ridx rs; Ridx rt; Ridx rd; } NOR;
    struct { Ridx rs; Ridx rt; Ridx rd; } OR;
    struct { Ridx rs; Ridx rt; Uimm im; } ORI;
    struct { Ridx rs; Ridx rt; Ridx rd; } XOR;
    struct { Ridx rs; Ridx rt; Uimm im; } XORI;

    // Condition Testing and Conditional Move Operations
    struct { Ridx rd; Ridx rs; Ridx rt; } SLT;
    struct { Ridx rs; Ridx rt; Simm im; } SLTI;
    struct { Ridx rd; Ridx rs; Ridx rt; } SLTIU;
    struct { Ridx rd; Ridx rt; Uimm im; } SLTU;

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

    void ILLEGAL;
} Instr deriving(Eq);

typedef Bit#(6) Opcode;


