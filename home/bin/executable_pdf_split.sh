#!/usr/bin/env bash

# pdf_split - Split a PDF document into chunks of specified page count
# Usage: pdf_split <input.pdf> [pages_per_chunk]

set -euo pipefail

chunk_size=${2:-1}

if [ $# -lt 1 ]; then
	echo "Usage: $(basename "$0") <input.pdf> [pages_per_chunk]"
	echo "  pages_per_chunk defaults to 1 if not specified"
	exit 1
fi

input_file="$1"

if [ ! -f "$input_file" ]; then
	echo "Error: File '$input_file' not found."
	exit 1
fi

if [[ ! "$input_file" =~ \.pdf$ ]]; then
	echo "Error: '$input_file' does not appear to be a PDF file."
	exit 1
fi

if ! [[ $chunk_size =~ ^[1-9][0-9]*$ ]]; then
	echo "Error: Please provide a positive integer for pages_per_chunk."
	exit 1
fi

if ! command -v pdftk &> /dev/null; then
	echo "Error: pdftk is not installed. Please install it first."
	exit 1
fi

total_pages=$(pdftk "$input_file" dump_data | grep NumberOfPages | awk '{print $2}')

if [ -z "$total_pages" ] || [ "$total_pages" -eq 0 ]; then
	echo "Error: Could not determine page count for '$input_file'."
	exit 1
fi

base_name="${input_file%.pdf}"

num_chunks=$(( (total_pages + chunk_size - 1) / chunk_size ))

echo "Splitting '$input_file' ($total_pages pages) into chunks of $chunk_size page(s)..."

chunk_num=1
start_page=1

while [ $start_page -le $total_pages ]; do
	end_page=$((start_page + chunk_size - 1))

	if [ $end_page -gt $total_pages ]; then
		end_page=$total_pages
	fi

	padded_num=$(printf "%0${#num_chunks}d" $chunk_num)
	output_file="${base_name}-part${padded_num}.pdf"

	if pdftk "$input_file" cat ${start_page}-${end_page} output "$output_file"; then
		echo "Created: $output_file (pages $start_page-$end_page)"
	else
		echo "Error: Failed to create $output_file"
		exit 1
	fi

	start_page=$((end_page + 1))
	chunk_num=$((chunk_num + 1))
done

echo "Successfully split into $((chunk_num - 1)) file(s)."
