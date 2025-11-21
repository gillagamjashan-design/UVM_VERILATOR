#!/bin/bash
# Script to convert TYPE::type_id::create() to TYPE::create_object() for Verilator

# Process all SystemVerilog files in tb directory
find tb -name "*.sv" -o -name "*.svh" | while read file; do
  echo "Processing $file..."
  # Convert type_id::create to create_object
  sed -i 's/::type_id::create/::create_object/g' "$file"
done

echo "Conversion complete!"
