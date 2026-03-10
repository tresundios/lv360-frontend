#!/bin/bash
# Simple format script that works around the prettier module issue

echo "Formatting code..."

# Check if files provided
if [ $# -eq 0 ]; then
  echo "Usage: ./scripts/format.sh <file1> [file2] ..."
  exit 1
fi

# Use node directly with prettier
for file in "$@"; do
  if [ -f "$file" ]; then
    echo "Formatting: $file"
    node -e "
    const prettier = require('prettier');
    const fs = require('fs');
    
    const content = fs.readFileSync('$file', 'utf8');
    try {
      const formatted = prettier.format(content, {
        filepath: '$file',
        parser: 'typescript'
      });
      fs.writeFileSync('$file', formatted);
      console.log('✅ Formatted successfully');
    } catch (error) {
      console.error('❌ Error formatting:', error.message);
      process.exit(1);
    }
    "
  else
    echo "❌ File not found: $file"
  fi
done

echo "Format complete!"
