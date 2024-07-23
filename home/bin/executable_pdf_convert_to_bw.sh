#!/usr/bin/env bash
for file in *.pdf ; do
gs \
 -sOutputFile="${file%.pdf}-bw.pdf" \
 -sDEVICE=pdfwrite \
 -sColorConversionStrategy=Gray \
 -dProcessColorModel=/DeviceGray \
 -dCompatibilityLevel=1.4 \
 -dNOPAUSE \
 -dBATCH \
 "$file" ;
 rm "$file";
done
