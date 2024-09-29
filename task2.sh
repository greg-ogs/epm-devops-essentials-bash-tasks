#!/bin/bash


if [[ $1 ]]
then
  input_file=$1
else
  echo "Pass input file path!"
  exit 1
fi

output_file="output.json"

# -------------------------------------------------
#  Preparation
# -------------------------------------------------

exec < "$input_file"
read -r line
test_name=$(sed -n '/\[.*/s/\[ \(.*\) \].*/\1/p' <<< "$line")
tests_count=$(grep -o '\b1\.\.[0-9]\+' <<< "$line")
tests_count=${tests_count:3}
tests_json_arr=()
read -r line

for ((i=1; i <= tests_count; i++)); do

# -------------------------------------------------
#  Get tests info
# -------------------------------------------------

  read -r line

  if grep -q 'not ok' <<< "$line"
  then
    status=false
  else
    status=true
  fi

  duration=$(grep -o '[0-9]\+ms' <<< "$line")

  name=$(grep -o '[0-9] .\+)' <<< "$line")
  name=${name:3}

# -------------------------------------------------
#  Convert test info to json
# -------------------------------------------------

  test_json=$(./jq -n --arg name "$name" \
                   --argjson status "$status" \
                   --arg duration "$duration" \
                   '$ARGS.named'
  )

  tests_json_arr+=("$test_json")

done

# -------------------------------------------------
#  Get summary info
# -------------------------------------------------

read -r line
read -r line

success=$(grep -o '^[0-9]\+\s' <<< "$line")

failed=$((tests_count - success))

rating=$(grep -o '[0-9\.]\+%' <<< "$line")
if [[ -n $rating ]]; then
  rating="${rating:: -1}"
fi

duration=$(grep -o '[0-9]\+ms' <<< "$line")

# -------------------------------------------------
# Building finale json file
# -------------------------------------------------

tests_json=$(./jq -sr '.' <<< "${tests_json_arr[@]}")

summary_json=$(./jq -nr --argjson success "$success" \
                     --argjson failed "$failed" \
                     --argjson rating "$rating" \
                     --arg duration "$duration" \
                     '$ARGS.named'
)

final=$(./jq -nr --arg testName "$test_name" \
              --argjson tests "$tests_json" \
              --argjson summary "$summary_json" \
              '$ARGS.named'
)

echo "$final" | tr -d '\r' > "$output_file"

echo "Successfully created $output_file"
exit 0