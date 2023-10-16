#!/bin/bash

emails_file=emails.txt
swords_file=sword.txt
output_file=matrix.txt
declare -A matrix
num_of_rows=0
num_of_=0

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
       matrix[$i,0]=$email_id
       matrix[$i,1]='x'
       j=2
       while read -r expression; do
          cleaned_expression=$(clean_text "$expression")
          count=$(count_occurrences "$cleaned_email_content" "$cleaned_expression")
          matrix[$i,$j]=$count
          ((j++))
       done < "$swords_file"
    ((i++))
    done < "$emails_file"

    num_of_rows=$i;
    num_of_cols=$j

    for (( i = 0; i < num_of_rows; i++ )); do
       for (( j = 0; j < num_of_cols; j++ )); do
          echo -n ${matrix[$i,$j]} "" >> "$freq_file"
 	   done
 	   echo >> "$freq_file"
    done  
}

calc_term_frequency(){
    text=$1
    term=$2
    total_terms=$(echo "$text" | wc -w) 
    occurrences=$(count_occurrences "$text" "$term")

    if [ "$total_terms" -ne 0 ]; then
        frequency=$(echo "scale=2; $occurrences / $total_terms" | bc)
        echo "$frequency"
    else
        echo "No se pueden calcular frecuencias con denominador igual a cero."
    fi

}

calc_docs_cotaining_term(){

}

calc_inv_doc_frequency(){
    docs=$1
    docs_containing_term=$1

}

# Texto de ejemplo (reemplázalo con tu propio texto)
texto="1|Este es es es es es es es es es es es es es esun ejemplo de texto con varias palabras."

calc_term_frequency "$texto" "es"