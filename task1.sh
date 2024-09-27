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

# Function to standardize names
standardize_name() {
    local name="$1"
    local standardized_name=$(echo "$name" | sed -r 's/\b(\w)(\w*)/\u\1\L\2/g')
    echo "$standardized_name"
}

# Function to generate email
generate_email() {
    local name="$1"
    local location_id="$2"
    local first_name=$(echo "$name" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
    local last_name=$(echo "$name" | cut -d' ' -f2 | tr '[:upper:]' '[:lower:]')
    local email="${first_name:0:1}${last_name}@abc.com"
    # Add location_id to email if it is a duplicate
    if grep -q "$email" "$output_csv"; then
        email="${first_name:0:1}${last_name}${location_id}@abc.com"
    fi
    echo "$email"
}
header=$(head -n 1 "$input_csv")

echo "$header" > "$output_csv"

# Process the CSV file and generate the new CSV file
tail -n +2 "$input_csv" | while IFS=, read -r id location_id name title email department; do
    # Standardize the name
    standardized_name=$(standardize_name "$name")

    # Generate the email
    generated_email=$(generate_email "$standardized_name" "$location_id")

    # Output the processed row to the new CSV file
    echo "$id,$location_id,$standardized_name,$title,$generated_email,$department" >> "$output_csv"
done

echo "Processing complete. New CSV file created: $output_csv"

