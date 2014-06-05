Simple MIPS µC
==============

This is a simple MIPS 32-bit microcontroller made as a demonstration during the Teaching Assistance at the 2010 class of Computer Architecture II at IFSC-USP (under supervision of Professor Carlos Antonio Ruggiero). It was uploaded at GitHub for archival purposes. This is a brief description of the contents of the repository.

* The `Avalon` directory contains Bluespec code for dealing with Altera Avalon bus, heavily based on code from MIT.
* The `board/bootrom` directory contains code for booting the system from a SD card on a DE2-70 board.
* The `board/bcsd` directory contains a very hackish port of the GNU bc calculator which runs bare bones on a DE2-70 board with our µC. It uses a PS/2 keyboard and the LCD display on the board for input/output. The included keyboard map is for Brazilian ABNT2. The binary is meant to be written to a SD card after compiled. This directory is licensed under GPL, contrary to the rest of the code, which is MIT licensed.
* The `tools` directory contains the following scripts --- `genverilog.sh` compiles the processor using Bluespec, generating a Verilog file; `programbuild.sh` compiles `program.c` to a `program.mem` meant to be ran in the emulator.
* The root directory contains the Bluespec code of the processor. The bluesim-based emulator can be built using the `MIPS.bspec` project.
