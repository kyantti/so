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
    awk '{ gsub(/[^[:alnum:] ]/, " "); gsub(/  +/, " "); gsub(/\<[0-9]+\>/, ""); gsub(/[0-9]+[^[:alnum:]]|[0-9]+$/, ""); print }'
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
       echo $cleaned_email_content
       analysis_matrix[$i,0]=$email_id
       analysis_matrix[$i,1]=$(calc_total_terms "$cleaned_email_content")

       j=2
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
          echo -n ${analysis_matrix[$i,$j]}":" >> "$freq_file"
 	   done
 	   echo >> "$freq_file"
    done

    analysis_done="true"
}

function calc_term_frequency(){
    occurrences=$1
    total_terms=$2

    if [ "$total_terms" -ne 0 ]; then
        frequency=$(echo "scale=2; $occurrences / $total_terms" | bc)
        echo "$frequency"
        return 0
    else
        echo "Error: No se pueden calcular frecuencias con denominador igual a cero."
        return 1
    fi

}

calc_docs_cotaining_term(){
    row_rep_of_term=$1
    count=0

    for ((i = 0; i < analysis_matrix_rows; i++)); do
        if [ "${matrix[$i,$row_rep_of_term]}" -gt 0 ]; then
            ((count++))
        fi
    done

    echo "$count"
}

function calc_inv_doc_frequency() {
    total_docs=$1
    docs_containing_term=$2
    
    if [ "$docs_containing_term" -eq 0 ]; then
        echo "Error: Division por cero. El termino no se encuentra en ningun documento."
        return 1
    else
       idf=$(echo "scale=2; l($total_docs/$docs_containing_term)/l(10)" | bc -l)
       echo "$idf"
       return 0
    fi
}

calc_tfidf() {
    term_freq=$1
    inv_doc_freq=$2
    tfidf=$(echo "$term_freq * $inv_doc_freq" | bc -l)
    echo $tfidf
}

function create_prediction_matrix_from_file(){
    file=$1
    i=0
    if [ -e "$file" ]; then
       while IFS= read -r line; do
          elements=($line)
          num_of_elements=${#elements[@]}

          prediction_matrix[$i,0]=${elements[0]}
          prediction_matrix[$i,1]=${elements[1]}
          prediction_matrix[$i,2]='x'
          for ((j = 3; j <= num_of_elements; j++)); do
             prediction_matrix[$i,$j]=${elements[j-1]}
          done
          
          ((i++))
       done < "$file"

       prediction_matrix_rows=$i
       prediction_matrix_cols=$j

       for ((i = 0; i < prediction_matrix_rows; i++)); do
        for ((j = 0; j <= prediction_matrix_cols; j++)); do
            echo -n ${prediction_matrix[$i,$j]} " "
        done
        echo
    done

       return 0
    else
       echo "El archivo $file no existe."
       return 1
    fi

}

function create_prediction_matrix_from_anylisis(){
    if [ ${#analysis_matrix[@]} -eq 0 ]; then
        echo "Error: La matriz analysis_matrix está vacía."
        return 1
    else
        for ((i = 0; i < analysis_matrix_rows; i++)); do
            prediction_matrix[$i,0]=${analysis_matrix[$i,0]}
            prediction_matrix[$i,1]='x'
            for ((j = 2; j <= analysis_matrix_cols; j++)); do
               prediction_matrix[$i,$j]=${analysis_matrix[$i,$((j-1))]}
            done
        done
        echo "Valores copiados de analysis_matrix a prediction_matrix."

        prediction_matrix_rows=$i
        prediction_matrix_cols=$j

        for ((i = 0; i < prediction_matrix_rows; i++)); do
            for ((j = 0; j <= prediction_matrix_cols; j++)); do
               echo -n ${prediction_matrix[$i,$j]} " "
            done
            echo
        done

        return 0
    fi
}

predict_email_intent(){
    for ((i = 0; i < prediction_matrix_rows; i++)); do
        email_id=${prediction_matrix[$i,0]}
        for ((j = 2; j <= prediction_matrix_cols; j++)); do
           occurrences=${prediction_matrix[$i,$j]}
           total_terms=${email_terms_count[$email_id]}
           term_frequency=$(calc_term_frequency $occurrences $total_terms)
           prediction_matrix[$i,$j]=$term_frequency
        done
    done

    for ((i = 0; i < prediction_matrix_rows; i++)); do
        for ((j = 0; j <= prediction_matrix_cols; j++)); do
            echo -n ${prediction_matrix[$i,$j]} " "
        done
        echo
    done
}

analyze_emails "emails.txt" "sword.txt" "analysis_matrix.freq"
#create_prediction_matrix_from_file "analysis_matrix.freq"