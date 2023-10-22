# Function to validate a file's existence
validate_file() {
  local file_prompt="$1"
  local file_variable="$2"

  while true; do
    read -rp "$file_prompt" "$file_variable"

    if [ ! -f "${!file_variable}" ]; then
      read -rp "The file does not exist. Do you want to re-enter the file name? (y/n): " reenter
    elif [ ! -s "${!file_variable}" ]; then
      read -rp "The file is empty. Do you want to re-enter the file name? (y/n): " reenter
    else
      return 0  # File is valid
    fi

    case "$reenter" in
      [Nn]*) exit 1 ;;
      *)     echo "Please enter 'y' for yes or 'n' for no." ;;
    esac
  done
}

# Function to validate the third file
validate_third_file() {
  local file_prompt="$1"
  local file_variable="$2"

  while true; do
    read -rp "$file_prompt" "$file_variable"

    if [[ "${!file_variable}" != *".freq" ]]; then
      echo "The file must end with .freq."
      read -rp "Do you want to re-enter the file name? (y/n): " reenter
    elif [ -e "${!file_variable}" ]; then
      read -rp "The file already exists. Do you want to overwrite it? (y/n): " overwrite
      case "$overwrite" in
        [Yy]*) break ;;
        [Nn]*) continue ;;
        *)     echo "Please enter 'y' for yes or 'n' for no." ;;
      esac
    else
      return 0  # File is valid
    fi

    case "$reenter" in
      [Nn]*) exit 1 ;;
      *)     echo "Please enter 'y' for yes or 'n' for no." ;;
    esac
  done
}

# Main script
analyze_emails() {
  validate_file "Enter the name of the first file: " "emails_file"
  validate_file "Enter the name of the second file: " "expressions_file"

  if [ "$emails_file" = "$expressions_file" ]; then
    echo "The second file cannot be the same as the first file."
    exit 1
  fi

  validate_third_file "Enter the name of the third file (must end with .freq and should not exist): " "analysis_file"

  i=0
  while IFS="|" read -r email_id email_content; do
    cleaned_email_content=$(clean_text "$email_content")
    echo "$cleaned_email_content"
    analysis_matrix["$i,0"]=$email_id
    analysis_matrix["$i,1"]=$(echo "$cleaned_email_content" | wc -w | tr -d '[:space:]')
    analysis_matrix["$i,2"]="x"
    j=3
    while read -r expression; do
      cleaned_expression=$(clean_text "$expression")
      count=$(echo "$cleaned_email_content" | grep -o "$cleaned_expression" | wc -l | tr -d '[:space:]')
      analysis_matrix["$i,$j"]=$count
      ((j++))
    done <"$expressions_file"
    ((i++))
  done <"$emails_file

  rows=$i
  cols=$j

  # Print the new matrix to the analysis file
  for ((i = 0; i < rows; i++)); do
    for ((j = 0; j < cols; j++)); do
      echo -n ${analysis_matrix["$i,$j"]}:" >> "$analysis_file"
    done
    echo >> "$analysis_file"
  done

  analysis_done="true"
}

# Run the main script
analyze_emails