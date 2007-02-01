cd ../src/router
cp .config_std.v24 .config
rm -rf mipsel-uclibc/install
rm -rf mipsel-uclibc/target
#make shared-clean
#make rc-clean
#make httpd-clean
#make clean
#make services-clean
#rm busybox/busybox
#rm busybox/applets/busybox.o

#Build DD-WRT sources
cd ..
make

#Perform strips
cd ../opt
mkdir ../src/router/mipsel-uclibc/target/etc/config
mkdir ../src/router/mipsel-uclibc/target/dev
mkdir ../src/router/mipsel-uclibc/target/jffs
mkdir ../src/router/mipsel-uclibc/target/mmc
mkdir ../src/router/mipsel-uclibc/target/opt
mkdir ../src/router/mipsel-uclibc/target/proc
mkdir ../src/router/mipsel-uclibc/target/sys
mkdir ../src/router/mipsel-uclibc/target/tmp
#mkdir ../src/router/mipsel-uclibc/target/etc/langpack
./sstrip/sstrip ../src/router/mipsel-uclibc/target/bin/*
./sstrip/sstrip ../src/router/mipsel-uclibc/target/sbin/*
./sstrip/sstrip ../src/router/mipsel-uclibc/target/usr/sbin/*

#Copy existing files to rootfs
cp ./bin/ipkg ../src/router/mipsel-uclibc/target/bin
cp ./libgcc/* ../src/router/mipsel-uclibc/target/lib

cd ../src/router/mipsel-uclibc/target/lib
ln -s libgcc_s.so.1 libgcc_s.so

cd ../../../../../opt
cp ./etc/preinit ../src/router/mipsel-uclibc/target/etc
cp ./etc/postinit ../src/router/mipsel-uclibc/target/etc
cp ./etc/ipkg.conf ../src/router/mipsel-uclibc/target/etc
cp ./etc/config/* ../src/router/mipsel-uclibc/target/etc/config
cp ./usr/lib/smb.conf ../src/router/mipsel-uclibc/target/usr/lib

#AutoAP
mkdir -p ../src/router/mipsel-uclibc/target/www/cgi-bin
cp -a ~/autoap/autoap.cgi ../src/router/mipsel-uclibc/target/www/cgi-bin
cp -a ~/autoap/autoap ../src/router/mipsel-uclibc/target/bin
chmod 777 ../src/router/mipsel-uclibc/target/bin/autoap

#Link SMB to Webroot
cd ../src/router/mipsel-uclibc/target/www
ln -s ../tmp/smbshare smb
cd ../../../../../opt

#Link var to tmp
cd ../src/router/mipsel-uclibc/target
ln -sf tmp/var var
cd ../../../../opt

./strip_libs.sh

# make language packs
#diff -r -a -w ./lang/spanish/www ../src/router/www > lang/langpacks/spanish.diff
#gzip -9 lang/langpacks/spanish.diff
#copy language packs to destination
#cp ./lang/langpacks/* ../src/router/mipsel-uclibc/target/langpacks
#cp ./lang/* ../src/router/mipsel-uclibc/target/etc/langpack

../src/linux/brcm/linux.v24/scripts/squashfs/mksquashfs-lzma ../src/router/mipsel-uclibc/target target.squashfs -noappend -root-owned -le

./make_kernel.v24.sh

cp ./vmlinuz ../src/router/mipsel-uclibc/vmlinuz

../tools/trx -o dd-wrt.v24_AAP.trx ./loader-0.02/loader.gz ../src/router/mipsel-uclibc/vmlinuz target.squashfs
../tools/trx_gs -o dd-wrt.v24_AAP_gs.trx ./loader-0.02/loader.gz ../src/router/mipsel-uclibc/vmlinuz target.squashfs

./asus/asustrx -p WL500gx -v 1.9.2.7 -o dd-wrt.v24_AAP_asus.trx ./loader-0.02/loader.gz ../src/router/mipsel-uclibc/vmlinuz target.squashfs

#add pattern
./tools/addpattern -4 -p W54U -v v4.20.6 -i dd-wrt.v24_AAP.trx -o dd-wrt.v24_AAP_wrtsl54gs.bin -g
./tools/addpattern -4 -p W54G -v v4.20.6 -i dd-wrt.v24_AAP.trx -o dd-wrt.v24_AAP_wrt54g.bin -g
./tools/addpattern -4 -p W54S -v v4.70.6 -i dd-wrt.v24_AAP.trx -o dd-wrt.v24_AAP_wrt54gs.bin -g
./tools/addpattern -4 -p W54s -v v1.05.0 -i dd-wrt.v24_AAP.trx -o dd-wrt.v24_AAP_wrt54gsv4.bin -g

cp dd-wrt.v24_AAP_asus.trx /GruppenLW/
cp dd-wrt.v24_AAP_wrt54g.bin /GruppenLW/
cp dd-wrt.v24_AAP_wrt54gs.bin /GruppenLW/
cp dd-wrt.v24_AAP_wrtsl54gs.bin /GruppenLW/
cp dd-wrt.v24_AAP_wrt54gsv4.bin /GruppenLW/
mv dd-wrt.v24_AAP.trx dd-wrt.v24_AAP_generic.bin
cp dd-wrt.v24_AAP_generic.bin /GruppenLW/
