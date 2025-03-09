#!/bin/bash

INPUT_FILE="input.csv"
OUTPUT_FILE="output.csv"

# Write CSV header
echo "Domain,Readme Domain,Plugin Version" > "$OUTPUT_FILE"

# Function to process each line
process_line() {
  local domain="$1"
  local location="$2"
  local line_number="$3"

  echo "Processing line: $line_number, Domain: $domain, Location: $location"

  # Use "Domain" column first, fallback to "Location on Site" if not a valid domain
  base_url="${domain:-$location}"

  # Ensure the URL has a proper scheme
  if [[ ! "$base_url" =~ ^https?:// ]]; then
    base_url="https://$base_url"
  fi

  url="$base_url/wp-content/plugins/embedpress/readme.txt"

  # Fetch the readme.txt content
  response=$(curl -s "$url")

  if [[ -n "$response" ]]; then
    # Extract the stable tag version
    version=$(echo "$response" | grep -i "Stable tag:" | awk -F': ' '{print $2}' | tr -d '\r')

    # Get domain from response URL in case of redirects
    readme_domain=$(curl -s -o /dev/null -w "%{url_effective}" "$url" 2>/dev/null | awk -F/ '{print $3}')

    # Write to output CSV only if readme.txt is fetched
    echo "$base_url,$readme_domain,$version" >> "$OUTPUT_FILE"
    echo "  Successfully processed line: $line_number"
  else
    echo "  Failed to fetch readme.txt for line: $line_number"
  fi
}

# Read the input CSV line by line, skipping the header
line_number=1
sed 1d "$INPUT_FILE" | while IFS=',' read -r domain location _; do
  process_line "$domain" "$location" "$line_number"
  line_number=$((line_number + 1))
done

echo "Finished processing all lines."