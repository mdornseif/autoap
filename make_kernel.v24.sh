#!/bin/sh

#cat ../src/linux/linux/arch/mips/brcm-boards/bcm947xx/compressed/piggy | ./loader-0.02/lzma e -si -so > ../src/router/mipsel-uclibc/vmlinuz
#cat ../src/linux/linux/arch/mips/brcm-boards/bcm947xx/compressed/piggy | 
#./loader-0.02/lzma e ../src/linux/linux/arch/mips/bcm947xx/compressed/piggy ../src/router/mipsel-uclibc/vmlinuz
./loader-0.02/lzma e ../src/linux/brcm/linux.v24/arch/mips/bcm947xx/compressed/piggy vmlinuz
./loader-0.02/lzma e ../src/linux/brcm/linux.v24/arch/mips/bcm947xx/compressed/piggy vmlinuzmicro
cp vmlinuz ../src/router/mipsel-uclibc/vmlinuz
cp vmlinuzmicro ../src/router/mipsel-uclibc/vmlinuzmicro
#./loader-0.02/lzma e piggymicro vmlinuzmicro
