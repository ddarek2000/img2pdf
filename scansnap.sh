#!/bin/sh
#set -e

export TMP_DIR=/mnt/temp/SCANNER/scan_$(date "+%Y-%m-%d_%H%M%S")
mkdir -p $TMP_DIR

#`mktemp -p /mnt/temp/SCANNER/ -d`
#scanimage --all-options >> /mnt/temp/SCANNER/scanimage.log

echo 'scanning..'
scanimage --source "ADF Duplex" --resolution 300 --batch="$TMP_DIR/scan_%03d.pnm" --format=pnm --mode Gray --page-width 215.9 --page-height 355.6 -y 355.6 -x 215.9 --swcrop=yes --swskip=1 --buffermode on --sleeptimer 5 --offtimer 30 --ald=yes

############################
# OLD
############################
#scanimage --source "ADF Duplex" --resolution 300 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --page-width 215.9 --page-height 355.6 -y 355.6 -x 215.9 --swcrop=yes --swskip=1 --buffermode on --sleeptimer 5 --offtimer 30 --ald=yes
#scanimage --source "ADF Duplex" --resolution 300 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --page-width 215.9 --page -height 355.6 -y 355.6 -x 215.9 --swcrop=yes --swskip=1 --buffermode on
#scanimage --source "ADF Duplex" --resolution 300 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --page-width 215.9 --page -height 355.6 -y 355.6 -x 215.9 --swcrop=yes --swskip=1
#scanimage --source "ADF Duplex" --resolution 600 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --page-width 215.9 --page -height 355.6 -y 355.6 -x 215.9 --swcrop=yes --swskip=1
#scanimage --source "ADF Duplex" --resolution 600 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --page-width 215.9 --page -height 355.6 -y 355.6 -x 215.9 --swcrop=yes
#scanimage --source "ADF Duplex" --resolution 600 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --page-width 215.9 --page -height 355.6 -y 355.6 -x 215.9 --buffermode On
#scanimage --source "ADF Duplex" --resolution 600 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray -y 558.728
#scanimage --resolution 600 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray original-size=Auto --source "ADF Duplex"
#scanimage --resolution 600 --batch="$TMP_DIR/scan_%03d.tiff" --format=tiff --mode Gray --source "ADF Duplex"
#scanimage --resolution 600 --batch="$TMP_DIR/scan_%03d.pnm" --format=pnm --mode Gray --source "ADF Duplex"
#scanimage --resolution 600 --batch="scan_%03d.pnm"> /mnt/temp/SCANNER/foo.pnm
#scanimage --resolution 600 --batch="/mnt/temp/SCANNER/scan_%03d.pnm" --batch-double --format=pnm

echo 'check if anything got scanned'
if [ `find $TMP_DIR -name "*.pnm" | wc -l` = 0 ]; then
        rmdir $TMP_DIR
        # try to import pictures from camera
        /etc/scanbd/scripts/pictures.sh > /dev/null 2>&1
        exit 0
fi
echo 'packaging and uploading in subshell'
find $TMP_DIR -name "*.pnm" -exec basename {} \; | sort > $TMP_DIR/scanimage.txt


#echo 'convert to pdf'
#/usr/bin/img2pdf -o $TMP_DIR/out.pdf `cat $TMP_DIR/scanimage.txt`
#mv $TMP_DIR/out.pdf $TMP_DIR.PDF

#(tarname=scan_$(date "+%Y-%m-%d_%H%M%S").tar
#cd $TMP_DIR
#tar -cf $tarname *.pnm
#echo 'uploading..'
#mv $TMP_DIR/$tarname /mnt/temp/SCANNER/
#rm -rf $TMP_DIR
#echo 'done') &
