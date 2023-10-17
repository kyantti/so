#!/bin/bash

emails_file=emails.txt
swords_file=sword.txt
output_file=matrix.txt
declare -A analysis_matrix
analysis_matrix_rows=0
analysis_matrix_cols=0
analysis_done="false"
declare -A prediction_matrix
prediction_matrix_rows=0
prediction_matrix_cols=0

to_lower() {
    awk '{print tolower($0)}'
}

remove_special_chars() {
    awk '{ gsub(/[^[:alnum:] ]/, " "); gsub(/  +/, " "); print }'
}

reduce_spaces() {
    tr -s ' '
}

clean_text() {
    input="$1"
    cleaned_text=$(echo "$input" | to_lower | remove_special_chars | reduce_spaces)
    echo "$cleaned_text"
}

function calc_total_terms() {
    text="$1"
    if [ -z "$text" ]; then
        echo "Error: Texto vacio, no se pueden contar los terminos."
        return 1
    else
        total_terms=$(echo "$text" | wc -w)
        echo "$total_terms"
        return 0
    fi
}

count_occurrences() {
    text="$1"          
    expression="$2"
    count=$(echo "$text" | grep -o "$expression" | wc -l)
    echo "$count"
}

analyze_emails(){
    emails_file=$1
    swords_file=$2
    freq_file=$3

    i=0;
    
    while IFS="|" read -r email_id email_content; do
       cleaned_email_content=$(clean_text "$email_content")
       analysis_matrix[$i,0]=$email_id

       j=1
       while read -r expression; do
          cleaned_expression=$(clean_text "$expression")
          count=$(count_occurrences "$cleaned_email_content" "$cleaned_expression")
          analysis_matrix[$i,$j]=$count
          ((j++))
       done < "$swords_file"

    ((i++))
    done < "$emails_file"

    analysis_matrix_rows=$i;
    analysis_matrix_cols=$j

    for (( i = 0; i < analysis_matrix_rows; i++ )); do
       for (( j = 0; j < analysis_matrix_cols; j++ )); do
          echo -n ${analysis_matrix[$i,$j]} "" >> "$freq_file"
 	   done
 	   echo >> "$freq_file"
    done

    analysis_done="true"
}

analyze_emails "emails.txt" "sword.txt" "analysis_matrix.freq"