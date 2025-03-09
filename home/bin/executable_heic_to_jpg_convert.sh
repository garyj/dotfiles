#!/usr/bin/env bash

# This script converts HEIC files to JPG using ImageMagick.
# It checks for the presence of ImageMagick, finds all HEIC files in the current directory,
# and converts them to JPG, optionally resizing them based on a provided scale factor.
# The converted files are placed in a directory named "converted".

# TODO: add replace option that will convert in place or delete the HEIC afterwords
# TODO: maybe good to expland to other image types for quick resizing.

if ! command -v convert &>/dev/null; then
  echo "ImageMagick is not installed. Please install it first."
  exit 1
fi

# Check if there are HEIC files in the current directory
shopt -s nullglob nocaseglob
heic_files=(*.heic)
shopt -u nullglob nocaseglob

# Check if there are any HEIC files
if [ ${#heic_files[@]} -eq 0 ]; then
  echo "No HEIC files found in the current directory."
  exit 0
fi

# Determine the scaling factor if provided as an argument
scale_factor=""

if [ -n "$1" ]; then
  scale_factor="-resize $1%"
fi

# Convert HEIC files to JPG
mkdir -p converted
for file in "${heic_files[@]}"; do
  base_name="${file%.*}"
  jpg_file="converted/${base_name}.jpg"
  convert convert "$file" $scale_factor "$jpg_file"
  echo "Converted $file to $jpg_file"
done

echo "Conversion complete."
