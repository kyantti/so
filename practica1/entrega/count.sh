#!/bin/bash

count_occurrences() {
  local text="$1"
  local expression="$2"

  # Use grep with the -o option to match and output each occurrence
  # Then use wc -l to count the lines (i.e., occurrences)
  local count=$(echo "$text" | grep -o "$expression" | wc -l)

  echo "$count"
}

# Example usage:
text="This is a sample text. This text contains the word 'text' multiple times."
expression="sample text"
result=$(count_occurrences "$text" "$expression")
echo "The expression '$expression' appears $result times in the text."

