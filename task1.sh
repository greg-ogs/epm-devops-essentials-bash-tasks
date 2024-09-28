#!/bin/bash

# Check if the CSV file path is provided as an argument
if [ -z "$1" ]; then
    echo "Error: Please provide the path to the CSV file as an argument."
    exit 1
fi

# Input CSV file path
input_csv="$1"

# Output CSV file path
output_csv="accounts_new.csv"

# change comas for ;
comas(){
  # Input and output file names
  input_file="$1"
  output_file="accounts_rewrited.csv"

  # Use sed to perform the pattern replacement, capturing the unknown value
  sed 's/,\"\([^,]*\),\s*\([^,]*\)\",/,\"\1- \2\",/g' "$input_file" > "$output_file"
}

# Function to standardize names
standardize_name() {
    local name="$1"
    local standardized_name=$(echo "$name" | sed -r 's/\b(\w)(\w*)/\u\1\L\2/g')
    echo "$standardized_name"
}

# Function to generate email
generate_email() {
    local name="$1"
    local first_name=$(echo "$name" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
    local last_name=$(echo "$name" | cut -d' ' -f2 | tr '[:upper:]' '[:lower:]')
    local email="${first_name:0:1}${last_name}@abc.com"
    echo "$email"
}

# Function to handle duplicate emails
duplicated_list(){
  declare -A emails_seen
  declare -a duplicate_emails

  while IFS=',' read -r -a fields; do
    email="${fields[4]}" # Column 5 (0-indexed)

    if [[ -n "${emails_seen[$email]}" ]]; then
      duplicate_emails+=("$email")
    else
      emails_seen[$email]=1
    fi
  done < accounts_new.csv

  echo "Duplicate emails:"
  printf '%s\n' "${duplicate_emails[@]}" > duplicate_emails.txt

  # Read duplicate emails from the text file into an array
  mapfile -t duplicate_emails < duplicate_emails.txt

  # Process each duplicate email
  for email in "${duplicate_emails[@]}"; do
    # Use awk to modify the CSV file in-place
    awk -F ',' -v email="$email" '
      BEGIN { OFS = FS }
        $5 == email {
        split($5, parts, "@")
        $5 = parts[1] $2 "@" parts[2]
      }
      { print }
    ' accounts_new.csv > temp.csv && mv temp.csv accounts_new.csv
  done
}
comas "$input_csv"

input_csv="accounts_rewrited.csv"

header=$(head -n 1 "$input_csv")

echo "$header" > "$output_csv"

# Main loop
tail -n +2 "$input_csv" | while IFS=, read -r id location_id name title email department; do
    # Standardize the name
    standardized_name=$(standardize_name "$name")

    # Generate the email
    generated_email=$(generate_email "$standardized_name")

    # Output the processed row to the new CSV file
    echo "$id,$location_id,$standardized_name,$title,$generated_email,$department" >> "$output_csv"
done
#
duplicated_list

echo "Processing complete. New CSV file created: $output_csv"

rm accounts_rewrited.csv duplicate_emails.txt