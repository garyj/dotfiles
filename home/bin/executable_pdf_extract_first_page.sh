#!/bin/bash
for file in *.pdf ; do 
	pdftk "$file" cat 1 output "${file%.pdf}-page1.pdf" ; 
	rm "$file"
done