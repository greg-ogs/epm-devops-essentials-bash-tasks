#!/bin/bash
input_file="$1"

original_text=$(head -n 1 "$input_file")

n_of_tests=$(echo "$original_text" | awk -F "1.." '{print $2}')
n_test=$((${n_of_tests:0:1}))

# Extract the test name using regular expressions
test_name=$(echo "$original_text" | grep -oP '\[ \K[^\]]+')

# Calculate the ending line for test results based on n_test
end_line=$((2 + n_test))

# Process test results (lines 3 to end_line)
test_results=$(sed -n "3,${end_line}p" "$input_file")

# Initialize the "tests" array (no initial comma)
tests_array=""

#Line for summary
# summary vars
success=0
failed=0

last_line=$(tail -n 1 "$input_file")

# Adjust the delimiter (' ') if your fields are separated by something else
fields=$(echo "$last_line" | awk -F' ' '{for (i=1; i<=NF; i++) print $i}')

for field in $fields; do
    if [[ "$field" == *"%"* ]]; then
      rat="$echo "$field""
      rating=${rat:1:10}
      f_rating=$(echo "$rating" | tr -d '%,' )
    fi
done

for field in $fields; do
    if [[ "$field" == *"ms"* ]]; then
      echo "$field"
      f_dur="$echo "$field""
      f_duration=${f_dur:1:10}
    fi
done

# Loop through each line of test results
while read -r line; do
  name=$(echo "$line" | awk -F'[, ]+' '{
                                    if ($1 == "ok") {
                                        for (i = 3; i <= NF - 1; i++) {
                                                    printf "%s ", $i
                                                }
                                    } else if ($1 == "not" && $2 == "ok") {
                                        for (i = 4; i <= NF - 1; i++) {
                                                    printf "%s ", $i
                                                }
                                    }
                                }')
  status=$(echo "$line" | awk -F'[, ]+' '{
                                    if ($1 == "ok") {
                                        print "true"
                                    } else if ($1 == "not" && $2 == "ok") {
                                        print "false"
                                    }
                                 }')
  if [ "$status" == "true" ]; then
    ((success++))
  fi
  if [ "$status" == "false" ]; then
    ((failed++))
  fi
  dur=$(echo "$line" | awk -F'[, ]+' '{
                                             print $NF
                                  }'| tr -d '\n')

  duration="${dur:0:3}"

  # Append test details to the array
  # Add a comma only if there are already entries in the array
  if [ -n "$tests_array" ]; then
    tests_array="$tests_array,"
  fi
  tests_array="$tests_array
    {
      \"name\": \"$name\",
      \"status\": \"$status\",
      \"duration\": \"$duration\"
    }"
done <<< "$test_results"

# Construct the final JSON output
json_output="{
  \"testName\": \"$test_name\",
  \"tests\": [$tests_array],
  \"summary\": {
    \"success\": $success,
    \"failed\": $failed,
    \"rating\": $f_rating,
    \"duration\": \"$f_duration\"
  }
}"

# Print the JSON output
echo "$json_output" > output.json
echo "json file created successfully"