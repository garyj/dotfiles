#!/usr/bin/env bash

# This script converts HEIC files to JPG using ImageMagick.
# The converted files are placed in a directory named "converted".

# TODO: add replace option that will convert in place or delete the HEIC afterwords
# TODO: maybe good to expland to other image types for quick resizing.

if ! command -v convert &>/dev/null; then
  echo "ImageMagick is not installed. Please install it first."
  exit 1
fi

shopt -s nullglob nocaseglob
heic_files=(*.heic)
shopt -u nullglob nocaseglob

if [ ${#heic_files[@]} -eq 0 ]; then
  echo "No HEIC files found in the current directory."
  exit 0
fi

scale_factor=""

if [ -n "$1" ]; then
  scale_factor="-resize $1%"
fi

mkdir -p converted
for file in "${heic_files[@]}"; do
  base_name="${file%.*}"
  jpg_file="converted/${base_name}.jpg"
  convert "$file" $scale_factor "$jpg_file"
  echo "Converted $file to $jpg_file"
done

echo "Conversion complete."
