#!/bin/bash

percentage="${1:-50}"

for file in *.jpg *.JPG *.jpeg *.JPEG *.png *.PNG; do
  if [ -f "$file" ]; then
    convert "$file" -resize "${percentage}%" "resized_$file"
  fi
done
