#!/bin/bash
for file in *.jpg *.JPG *.jpeg *.JPEG; do
  if [ -f "$file" ]; then
    convert "$file" -resize 50% "resized_$file"
  fi
done
