#!/usr/bin/env bash

# Default to 1 page if no argument is provided
pages=${1:-1}

# Check if the argument (if provided) is a positive integer
if ! [[ $pages =~ ^[1-9][0-9]*$ ]]; then
	echo "Error: Please provide a positive integer as an argument, or no argument to default to 1 page."
	exit 1
fi

for file in *.pdf; do
	if [ -f "$file" ]; then
		# Get the total number of pages in the PDF
		total_pages=$(pdftk "$file" dump_data | grep NumberOfPages | awk '{print $2}')

		# Determine how many pages to extract (minimum of requested pages and total pages)
		pages_to_extract=$((pages < total_pages ? pages : total_pages))
		if pdftk "$file" cat 1-$pages_to_extract output "${file%.pdf}-page1-$pages_to_extract.pdf"; then
			echo "Successfully processed $file (extracted $pages_to_extract pages)"
			rm "$file"
		else
			echo "Failed to process $file. Original file not deleted."
		fi
	fi
done
