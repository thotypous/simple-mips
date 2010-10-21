#!/bin/sh
cp bootrom.hex ..
cd ..
quartus_cdb --update_mif MIPSboard
quartus_asm MIPSboard
