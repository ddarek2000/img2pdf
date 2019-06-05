#!/bin/bash
set -x

SCANNER_BASE=/mnt/cache/temp/SCANNER
SCANNER_NEXTCLOUD=/mnt/cache/nextcloud/data/DOCUMENTS/files/SCANNER
LOCK_FILE=/tmp/scanner_watcher.pid
LOG_FILE=/tmp/scanner_watcher.log

### Exit if /tmp/scanner_watcher.pid exists
process_name="$(basename "$0")";
running=$(ps h -C "$process_name" | grep -wv "^$$" | wc -l);
if [ -f $LOCK_FILE ]; then
  if [ $running -gt 1 ]; then

#echo process_name: $process_name >> $LOG_FILE
#echo running: $running >> $LOG_FILE
#echo process_number $$ >> $LOG_FILE
#process_id=$$
#echo process_id $process_id >> $LOG_FILE

        exit 0
  else
        rm $LOCK_FILE
  fi
  exit 0

else
  echo $$ > /tmp/scanner_watcher.pid
fi

# Close STDOUT file descriptor
#exec 1<&-
# Close STDERR FD
#exec 2<&-
# Open STDOUT as $LOG_FILE file for read and write.
#exec 1<>$SCAN_DIR/pdf.lock
# Redirect STDERR to STDOUT
#exec 2>&1

###################################################################################
## find files
###################################################################################
for i in $( find $SCANNER_BASE -name scanimage.txt -type f -mmin -60 );do
#for i in $( find $SCANNER_BASE -name scanimage.txt -type f );do
###################################################################################

SCAN_DIR=$(basename $(dirname "$i"))
if [ ! -e "$SCANNER_BASE/$SCAN_DIR/pdf.lock" ]; then
        echo "Lock File does not exist"
        touch $SCANNER_BASE/$SCAN_DIR/pdf.lock
        chown -R 99:98 $SCANNER_BASE/$SCAN_DIR
else
    exit 0
fi

###################################################################################
### postprocess the images -- done in hardware now
for j in $(find $SCANNER_BASE/$SCAN_DIR \( -name "*.tiff" -o -name "*.pnm" \) -printf "%f\n");do

/usr/bin/docker run --rm -v "$SCANNER_BASE:/home/docker" ddarek/img2pdf magick convert -flatten -fuzz 5% -fill "#ffffff" -opaque "#f2f2f2" -trim +repage -density 300 -depth 8 -st
rip -background white -alpha off $SCAN_DIR/$j $SCAN_DIR/$j

done
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

###################################################################################
### remove blank pages
#for j in $( find $SCANNER_BASE/$SCAN_DIR \( -name "*.tiff" -o -name "*.pnm" \) -type f -printf "%f\n" );do

#       is_blank=$(/usr/bin/docker run --rm -v "$SCANNER_BASE:/home/docker" ddarek/img2pdf magick convert "$SCAN_DIR/$j" -format "%[fx:mean>0.99?1:0]" info:)
#       if [ $is_blank -ne 0 ];then
#               echo "$SCAN_DIR/$j is blank"
#               rm $SCANNER_BASE/$SCAN_DIR/$j
#       fi
#done
#ret_code=$?
#if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi


###################################################################################

### non blank list
find $SCANNER_BASE/$SCAN_DIR \( -name "*.tiff" -o -name "*.pnm" \) -printf "$SCAN_DIR/%f\n"| sort > $SCANNER_BASE/$SCAN_DIR/pdf_nonblank.txt
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

### convert to a single pdf
docker run --rm -v "$SCANNER_BASE:/home/docker" ddarek/img2pdf img2pdf -o $SCAN_DIR/pdf.pdf `cat $SCANNER_BASE/$SCAN_DIR/pdf_nonblank.txt`
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

### ocr the pdf file
docker run --rm -v "$SCANNER_BASE:/home/docker" ddarek/img2pdf ocrmypdf --deskew --rotate-pages --rotate-pages-threshold 3 $SCAN_DIR/pdf.pdf $SCAN_DIR/pdf_output.pdf
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

### move to file to output name
cp -a $SCANNER_BASE/$SCAN_DIR/pdf_output.pdf $SCANNER_BASE/$SCAN_DIR.pdf
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

### move to file to nextcloud
mv $SCANNER_BASE/$SCAN_DIR.pdf $SCANNER_NEXTCLOUD
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

### indicate processing complete
mv $SCANNER_BASE/$SCAN_DIR/scanimage.txt $SCANNER_BASE/$SCAN_DIR/scanimage_pdf_generated.txt
ret_code=$?
if [ $ret_code -ne 0 ]; then rm $SCANNER_BASE/$SCAN_DIR/pdf*.pdf ; exit 1; fi

### fix permissions
chown -R nobody:users $SCANNER_NEXTCLOUD
chmod -R 777 $SCANNER_NEXTCLOUD


###################################################################################
### update file index and text search index
/usr/bin/docker exec nextcloud sudo -u abc php /config/www/nextcloud/occ files:scan --path="DOCUMENTS/files/SCANNER" > /dev/null 2>&1
/usr/bin/docker exec nextcloud sudo -u abc php /config/www/nextcloud/occ fulltextsearch:stop > /dev/null 2>&1
/usr/bin/docker exec nextcloud sudo -u abc php -d memory_limit=4096M /config/www/nextcloud/occ fulltextsearch:index "{\"user\":\"DOCUMENTS\", \"providers\":\"files\", \"path\":\"
SCANNER\"}"  > /dev/null 2>&1

done




###################################################################################
### Cleanup dirs older than 24 hrs
#for i in $( find $SCANNER_BASE/ -name scanimage_pdf_generated.txt -type f -mtime +1 );do
#       rm -rf $(dirname "$i")
#done

#cleanup lock file
rm /tmp/scanner_watcher.pid
exit 0
