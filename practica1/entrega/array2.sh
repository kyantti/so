#!/bin/bash

emails_file=emails.txt
swords_file=sword.txt
output_file=matrix.txt
declare -A matrix
num_of_emails=0
num_of_expressions=0

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

# Function to set a cell value in the matrix
set_cell() {
    local key1=$1
    local key2=$2
    local value=$3
    matrix["$key1,$key2"]=$value
}

# Function to get a cell value from the matrix
get_cell() {
    local key1=$1
    local key2=$2
    echo "${matrix["$key1,$key2"]}"
}

analyze_emails() {
    emails_file=$1
    swords_file=$2
    freq_file=$3

    while IFS="|" read -r email_id email_content; do
        cleaned_email_content=$(clean_text "$email_content")
        ((num_of_emails++))

        num_of_expressions=0;
        while read -r expression; do
            cleaned_expression=$(clean_text "$expression")
            count=$(count_occurrences "$cleaned_email_content" "$cleaned_expression")
            set_cell $email_id $cleaned_expression $count

            ((num_of_expressions++))
        done < "$swords_file"
    done < "$emails_file"

    echo $num_of_emails "" $num_of_expressions
}

function calc_term_frequency(){
    text=$1
    term=$2
    total_terms=$(echo "$text" | wc -w) 
    occurrences=$(count_occurrences "$text" "$term")

    if [ "$total_terms" -ne 0 ]; then
        frequency=$(echo "scale=2; $occurrences / $total_terms" | bc)
        echo "$frequency"
        return 0
    else
        echo "No se pueden calcular frecuencias con denominador igual a cero."
        return 1
    fi

}

calc_docs_containing_term() {
    term=$1
    count=0

    for ((i = 1; i <= num_of_emails; i++)); do
        cell_value=$(get_cell $i $term)
        if [ "$cell_value" -ge 1 ]; then
           ((count++))
        fi
    done

    echo "Count for term '$term': $count"
}

function calc_inv_doc_frequency() {
    total_docs=$1
    docs_containing_term=$2
    
    if [ "$docs_containing_term" -eq 0 ]; then
        echo "Error: Division by zero. The term is not found in any document."
        return 1
    fi
    idf=$(echo "scale=2; l($total_docs/$docs_containing_term)/l(10)" | bc -l)
    echo "IDF for term: $idf"
    return 0
}

calc_tfidf() {
    term_freq=$1
    inv_doc_freq=$2
    tfidf=$(echo "$term_freq * $inv_doc_freq" | bc -l)
    echo $tfidf
}

is_spam() {
    email_tf=$1
    email_idf=$2

    tfidf=$(calc_tfidf $email_tf $email_idf)

    if (( $(echo "$tfidf > 0.3" | bc -l) )); then
        echo "This email is considered spam (TF-IDF = $tfidf)"
    else
        echo "This email is not spam (TF-IDF = $tfidf)"
    fi
}

# Call the analyze_emails function with your input files
analyze_emails "$emails_file" "$swords_file" "$output_file"

# Llama a la función con el término deseado
calc_docs_containing_term "4u"

# Llama a la función con los valores de ejemplo
calc_inv_doc_frequency 10000 100
