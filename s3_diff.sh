#!/bin/bash
# s3_diff.sh
#
# This script compares the JSON contents of two AWS S3 buckets.
# It lists files (using aws s3 ls), computes the differences between the two lists,
# and writes the output (files unique to each bucket) into a result text file.
#
# Usage: ./s3_diff.sh [-m max_files] [-o output_file] s3://bucket1 s3://bucket2
#   -m max_files: (optional) Maximum number of common files to process (default: 100)
#   -o output_file: (optional) File to save the result (default: s3_diff_output.txt)

# Default values
max_files=100
result_file="s3_diff_output.txt"

# Parse options
while getopts "m:o:" opt; do
  case $opt in
    m)
      max_files="$OPTARG"
      ;;
    o)
      result_file="$OPTARG"
      ;;
    *)
      echo "Usage: $0 [-m max_files] [-o output_file] s3://bucket1 s3://bucket2"
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))

# Ensure two positional arguments remain
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 [-m max_files] [-o output_file] s3://bucket1 s3://bucket2"
  exit 1
fi

bucket1="$1"
bucket2="$2"

# Clear the result file if it already exists
> "$result_file"

# Create temporary files to hold file lists
bucket1_list=$(mktemp)
bucket2_list=$(mktemp)
common_list=$(mktemp)
bucket1_exclusive=$(mktemp)
bucket2_exclusive=$(mktemp)

# Function to list files from an S3 bucket and sort the output.
list_bucket() {
  local bucket=$1
  aws s3 ls "$bucket" --recursive | awk '{print $NF}' | sort
}

echo "Step: listing $bucket1..."
list_bucket "$bucket1" > "$bucket1_list"

echo "Step: listing $bucket2..."
list_bucket "$bucket2" > "$bucket2_list"

echo "Step: sorting file lists..."
# (The file lists are already sorted by the list_bucket function)

echo "Step: comparing file lists..."
# Compute differences using comm (files must be sorted)
# Files only in bucket1:
comm -23 "$bucket1_list" "$bucket2_list" > "$bucket1_exclusive"
# Files only in bucket2:
comm -13 "$bucket1_list" "$bucket2_list" > "$bucket2_exclusive"
# Files common to both (not printed):
comm -12 "$bucket1_list" "$bucket2_list" > "$common_list"

# Write the final results to the result file (do not print these to the console)
{
  echo ""
  echo "Files only in $bucket1:"
  cat "$bucket1_exclusive"
  echo ""
  echo "Files only in $bucket2:"
  cat "$bucket2_exclusive"
  echo ""
} >> "$result_file"

echo "Step: saving output to $result_file"

# Optional JSON diffing section (commented out):
: <<'EOF'
echo "Step: processing common files (limited to max_files = $max_files)..."
common_count=$(wc -l < "$common_list")
if [ "$common_count" -gt "$max_files" ]; then
  tail -n "$max_files" "$common_list" > common_tmp
  mv common_tmp "$common_list"
fi

while IFS= read -r file; do
  echo "Step: downloading and diffing file: $file..."
  aws s3 cp "$bucket1/$file" tmp1.json
  aws s3 cp "$bucket2/$file" tmp2.json
  
  diff_output=$(jd -set -color tmp1.json tmp2.json)
  if [ -n "$diff_output" ]; then
    echo "Differences in $file:" >> "$result_file"
    echo "$diff_output" >> "$result_file"
  else
    echo "No differences in $file" >> "$result_file"
  fi
done < "$common_list"

rm -f tmp1.json tmp2.json
EOF

# Remove temporary files
rm -f "$bucket1_list" "$bucket2_list" "$common_list" "$bucket1_exclusive" "$bucket2_exclusive"
