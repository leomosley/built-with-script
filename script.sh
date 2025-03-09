#!/bin/bash

INPUT_FILE="input.csv"
OUTPUT_FILE="output.csv"

# Write CSV header
echo "Domain,Readme Domain,Plugin Version" > "$OUTPUT_FILE"

# Read the input CSV line by line, skipping the header
sed 1d "$INPUT_FILE" | while IFS=',' read -r domain location _; do
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
  fi
done