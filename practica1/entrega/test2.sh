#!/bin/bash

declare -A analysis_matrix
declare -A prediction_matrix
declare -a column_counts
rows=0
cols=0
analysis_done="false"


clean_text() {
    input="$1"
    cleaned_text=$(echo "$input" | awk '{print tolower($0)}' | awk '{ gsub(/[^[:alnum:] ]/, " "); gsub(/  +/, " "); gsub(/\<[0-9]+\>/, ""); gsub(/[0-9]+[^[:alnum:]]|[0-9]+$/, ""); print }' | tr -s ' ')
    echo "$cleaned_text"
}

# Usage: progressBar "message" currentStep totalSteps
function progressBar() {
    local   bar='████████████████████'
    local space='....................'
    local wheel=('\' '|' '/' '-')

    local msg="${1}"
    local current=${2}
    local total=${3}
    local wheelIndex=$((current % 4))
    local position=$((100 * current / total))
    local barPosition=$((position / 5))

    echo -ne "\r|${bar:0:$barPosition}$(tput dim)${space:$barPosition:20}$(tput sgr0)| ${wheel[wheelIndex]} ${position}% [ ${msg} ] "
}


function analyze_emails() {

    declare -A term_count

    while true; do
        # Prompt for the first file
        read -rp "Enter the name of the first file: " emails_file

        # Check if the first file exists
        if [ ! -f "$emails_file" ]; then
            read -rp "The first file does not exist. Do you want to re-enter the file name? (y/n): " reenter
            case "$reenter" in
            [Yy]*)
                continue
                ;;
            [Nn]*)
                return 1
                ;;
            *)
                echo "Please enter 'y' for yes or 'n' for no."
                ;;
            esac
        else
            break
        fi
    done

    while true; do
        # Prompt for the second file
        read -rp "Enter the name of the second file: " words_file

        # Check if the second file exists
        if [ ! -f "$words_file" ]; then
            read -rp "The second file does not exist. Do you want to re-enter the file name? (y/n): " reenter
            case "$reenter" in
            [Yy]*)
                continue
                ;;
            [Nn]*)
                return 1
                ;;
            *)
                echo "Please enter 'y' for yes or 'n' for no."
                ;;
            esac
        else
            break
        fi
    done

    # Prompt for the third file
    while true; do
        read -rp "Enter the name of the third file (must end with .freq and should not exist): " analysis_file

        if [[ "$analysis_file" != *".freq" ]]; then
            echo "The third file must end with .freq."
        elif [ -e "$analysis_file" ]; then
            read -rp "The file already exists. Do you want to overwrite it? (y/n): " overwrite
            case "$overwrite" in
            [Yy]*)
                break
                ;;
            [Nn]*)
                continue
                ;;
            *)
                echo "Please enter 'y' for yes or 'n' for no."
                ;;
            esac
        else
            break
        fi
    done
    
    total_emails=$(wc -l < "$emails_file")

    while IFS="|" read -r email_id email_content; do
        cleaned_email_content=$(clean_text "$email_content")
        total_terms=$(echo "$cleaned_email_content" | wc -w | tr -d '[:space:]')
        analysis_matrix["$email_id,ID"]=$email_id
        analysis_matrix["$email_id,total_terms"]="$total_terms"
        analysis_matrix["$email_id,ham_or_spam"]="x"
        line="$email_id:$total_terms:x"
        progressBar "Analizando E-Mail $email_id" "$i" "$total_emails"
        while read -r expression; do
            cleaned_expression=$(clean_text "$expression")
            count=$(echo "$cleaned_email_content" | grep -o "$cleaned_expression" | wc -l | tr -d '[:space:]')
            analysis_matrix["$email_id,$cleaned_expression"]=$count
            term_count["$cleaned_expression"]=$((term_count["$cleaned_expression"] + count))
            line="${line}:${count}"

        done <"$words_file"
        
        echo "$line" >> "$analysis_file"

    done <"$emails_file"

    progressBar "Análisis completado" "$total_emails" "$total_emails"
    echo

    # Generar el informe fila/columna
report_file="term_report.txt"
echo "Término|Apariciones" > "$report_file"
for term in "${!term_count[@]}"; do
    echo "$term|${term_count[$term]}" >> "$report_file"
done

echo "Informe generado en $report_file"
    
    analysis_done="true"

}

create_prediction_matrix_from_file() {
    local input_file="$1" # Nombre del archivo que contiene la matriz
    local k=0             # Variable auxiliar para contar el número de filas

    # Verificar si el archivo existe
    if [ ! -f "$input_file" ]; then
        echo "Error: El archivo $input_file no existe."
        return 1
    fi

    # Leer el archivo línea por línea
    while IFS= read -r line; do
        # Split de la línea en un array utilizando ":" como delimitador
        IFS=":" read -ra elements <<<"$line"

        email_id="${elements[0]}"
        num_of_terms_in_email="${elements[1]}"

        if [ "$num_of_terms_in_email" -gt 0 ]; then
            for ((j = 0; j < ${#elements[@]}; j++)); do
                prediction_matrix["$k,$j"]="${elements[j]}"
            done
            ((k++))
        else
            echo "Error. El E-Mail $email_id está vacío, no se tendrá en cuenta en el cálculo del TF-IDF."
        fi
    done <"$input_file"

    prediction_matrix_rows="$k"
    cols=${#elements[@]}

    echo "Filas PM: $prediction_matrix_rows"

    # Imprimir la nueva matriz
    for ((i = 0; i < prediction_matrix_rows; i++)); do
        for ((j = 0; j < ${#elements[@]}; j++)); do
            echo -n "${prediction_matrix["$i,$j"]}:"
        done
        echo
    done

    # Inicializar el array column_counts con 0 para todas las columnas
    for ((j = 3; j < ${#elements[@]}; j++)); do
        column_counts[j]=0
    done

    # Recorrer la matriz y contar los valores mayores que 0 en cada columna
    for ((j = 3; j < ${#elements[@]}; j++)); do
        for ((i = 0; i < prediction_matrix_rows; i++)); do
            if [ "${prediction_matrix["$i,$j"]}" -gt 0 ]; then
                ((column_counts[j]++))
            fi
        done
    done

    # Mostrar los resultados de los conteos por columna
    for ((j = 3; j < ${#elements[@]}; j++)); do
        echo "Columna $j: ${column_counts[j]} elementos mayores que 0"
    done
}

create_prediction_matrix_from_anylisis() {
    #Variable auxliar para contar el numero de filas que tendra la nueva matriz prediccion
    k=0
    #Recorre la matriz de analisis y la copia a una nueva matriz prediccion
    for ((i = 0; i < rows; i++)); do
        email_id=${analysis_matrix["$i,0"]}
        num_of_terms_in_email=${analysis_matrix["$i,1"]}

        if [[ num_of_terms_in_email -gt 0 ]]; then
            for ((j = 0; j < cols; j++)); do
                prediction_matrix["$k,$j"]=${analysis_matrix["$i,$j"]}
            done
            ((k++))
        else
            echo "Error. El E-Mail $email_id esta vacio, no se tendra en cuenta en cuenta para el calculo del TF-IDF."
        fi
    done

    prediction_matrix_rows="$k"

    echo "Filas PM: $prediction_matrix_rows"

    #Imprimir la nueva matriz
    for ((i = 0; i < prediction_matrix_rows; i++)); do
        for ((j = 0; j < cols; j++)); do
            echo -n "${prediction_matrix["$i,$j"]}:"
        done
        echo
    done

    # Inicializa el array column_counts con 0 para todas las columnas
    for ((j = 3; j < cols; j++)); do
        column_counts[j]=0
    done

    # Recorre la matriz y cuenta los valores mayores que 0 en cada columna
    for ((j = 3; j < cols; j++)); do
        for ((i = 0; i < prediction_matrix_rows; i++)); do
            if [[ "${prediction_matrix["$i,$j"]}" -gt 0 ]]; then
                ((column_counts[j]++))
            fi
        done
    done

    # Mostrar los resultados de los conteos por columna
    for ((j = 3; j < cols; j++)); do
        echo "Columna $j: ${column_counts[j]} elementos mayores que 0"
    done
}

predict_email_intent() {
    for ((i = 0; i < prediction_matrix_rows; i++)); do
        row_tf_idf_sum=0
        for ((j = 3; j < cols; j++)); do
            occurrences=${prediction_matrix["$i,$j"]}
            total_terms_in_email=${prediction_matrix["$i,1"]}
            total_docs=$rows
            docs_containing_term=${column_counts[j]}
            if [ "$docs_containing_term" -eq 0 ]; then
                docs_containing_term=1
            fi
            tf=$(echo "scale=2; $occurrences / $total_terms_in_email" | bc)
            idf=$(echo "scale=2; l($total_docs/$docs_containing_term)/l(10)" | bc -l)
            tf_idf=$(echo "$tf * $idf" | bc -l)
            row_tf_idf_sum=$(echo "scale=2; $row_tf_idf_sum + $tf_idf" | bc)
            prediction_matrix["$i,$j"]="$tf_idf"
        done
        average_tf_idf=$(echo "scale=2; $row_tf_idf_sum / (cols - 3)" | bc)

        if (($(echo "$average_tf_idf > 0.3" | bc -l))); then
            prediction_matrix["$i,2"]="1"
        else
            prediction_matrix["$i,2"]="0"
        fi
    done

    echo "$prediction_matrix_rows" "$cols"

    echo "TF-IDF Matrix"

    for ((i = 0; i < prediction_matrix_rows; i++)); do
        for ((j = 0; j < cols; j++)); do
            echo -n "${prediction_matrix["$i,$j"]}:"
        done
        echo
    done

}



analyze_emails

