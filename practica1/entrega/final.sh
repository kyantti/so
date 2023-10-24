#!/bin/bash

emails_file=""
expressions_file=""
freq_file=""
analysis_completed="false"
prediction_completed="false"
declare -A analysis_matrix
declare -A prediction_matrix
declare -a column_counts
analysis_matrix_rows=0
prediction_matrix_rows=0
cols=0

# Usage: progressBar "message" currentStep totalSteps
function progressBar() {
    local bar='████████████████████'
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

clean_text() {
    input="$1"
    cleaned_text=$(echo "$input" | awk '{print tolower($0)}' | awk '{ gsub(/[^[:alnum:] ]/, " "); gsub(/  +/, " "); gsub(/\<[0-9]+\>/, ""); gsub(/[0-9]+[^[:alnum:]]|[0-9]+$/, ""); print }' | tr -s ' ')
    echo "$cleaned_text"
}

while true; do
    echo "Menú:"
    echo
    echo "1. Análisis de datos"
    echo "2. Predicción"
    echo "3. Informes de resultados"
    echo "4. Ayuda"
    echo "5. Salir"
    echo
    read -rp "Seleccione una opción (1-5): " choice

    case $choice in
    1)
        return_to_menu="false"
        file_ok="false"
        i=3
        while [ "$i" -gt 0 ] && [ "$file_ok" == "false" ]; do
            read -rp "Introduzca el nombre del fichero que contiene los correos electrónicos: " emails_file

            if [ -z "$emails_file" ]; then
                ((i--))
                echo "Entrada invalida. Le quedan $i intentos."
            elif [ ! -f "$emails_file" ]; then
                ((i--))
                echo "El fichero no existe. Le quedan $i intentos."
            elif grep -qvE '^[0-9]+\|.+$' "$emails_file"; then
                ((i--))
                echo "El contenido del fichero no sigue la estructura requerida (Identificador|Contenido del correo electrónico). Le quedan $i intentos."
            else
                file_ok="true"
            fi
            if [ "$i" -eq 0 ]; then
                return_to_menu="true"
                break
            fi
        done

        if [ "$return_to_menu" == "true" ]; then
            read -rp "Introduzca cualquier tecla para regresar al menú:" key
            clear
            continue
        fi

        return_to_menu="false"
        file_ok="false"
        i=3
        while [ "$i" -gt 0 ] && [ "$file_ok" == "false" ]; do
            read -rp "Introduzca el nombre del fichero que contiene las expresiones sospechosas: " expressions_file
            if [ -z "$expressions_file" ]; then
                ((i--))
                echo "Entrada invalida. Le quedan $i intentos."
            elif [ ! -f "$expressions_file" ]; then
                ((i--))
                echo "El fichero no existe. Le quedan $i intentos."
            elif [ "$expressions_file" == "$emails_file" ]; then
                ((i--))
                echo "El fichero no puede ser el mismo que el que contiene los correos electrónicos. Le quedan $i intentos."
            else
                file_ok="true"
            fi

            if [ "$i" -eq 0 ]; then
                return_to_menu="true"
                break
            fi

        done

        if [ "$return_to_menu" == "true" ]; then
            read -rp "Introduzca cualquier tecla para regresar al menú:" key
            clear
            continue
        fi

        return_to_menu="false"
        file_ok="false"
        i=3
        while [ "$i" -gt 0 ] && [ "$file_ok" == "false" ]; do
            read -rp "Introduzca el nombre del fichero donde se escribirá el análisis de los correos electrónicos. (.freq): " freq_file
            if [ -z "$freq_file" ]; then
                ((i--))
                echo "Entrada invalida. Le quedan $i intentos."
            elif [ -e "$freq_file" ]; then
                ((i--))
                echo "El fichero ya existe. Le quedan $i intentos."
            else
                file_ok="true"
            fi

            if [ "$i" -eq 0 ]; then
                return_to_menu="true"
                break
            fi

        done

        if [ "$return_to_menu" == "true" ]; then
            read -rp "Introduzca cualquier tecla para regresar al menú:" key
            clear
            continue
        fi

        total_emails=$(wc -l <"$emails_file")
        i=0
        while IFS="|" read -r email_id email_content; do
            cleaned_email_content=$(clean_text "$email_content")
            total_expressions=$(echo "$cleaned_email_content" | wc -w | tr -d '[:space:]')
            analysis_matrix["$i,0"]="$email_id"
            analysis_matrix["$i,1"]="$total_expressions"
            analysis_matrix["$i,2"]="x"
            line="$email_id:$total_expressions:x"
            progressBar "Analizando E-Mail $email_id" "$i" "$total_emails"
            j=3
            while read -r expression; do
                cleaned_expression=$(clean_text "$expression")
                count=$(echo "$cleaned_email_content" | grep -o "$cleaned_expression" | wc -l | tr -d '[:space:]')
                analysis_matrix["$i,$j"]="$count"
                line="${line}:${count}"
                ((j++))
            done <"$expressions_file"
            ((i++))
            echo "$line" >>"$freq_file"
        done <"$emails_file"
        analysis_matrix_rows=$i
        cols=$j
        analysis_completed="true"
        progressBar "Análisis completado" "$total_emails" "$total_emails"
        echo
        echo "Matriz de análisis guardada en: $(pwd)/freq_file.freq"
        echo
        read -rp "Introduzca cualquier tecla para regresar al menú:" key
        ;;
    2)
        use_analysis=""
        return_to_menu="false"
        matrix_built="false"
        if [ "$analysis_completed" == "true" ]; then
            input_ok="false"
            i=3
            while [ "$i" -gt 0 ] && [ "$input_ok" == "false" ]; do
                read -rp "Se ha encontrado un análisis en la ejecución. ¿Desea utilizarlo? (s/n):" use_analysis
                if [ "$use_analysis" == "s" ]; then
                    input_ok="true"
                    echo "Usando el análisis actual."
                elif [ "$use_analysis" == "n" ]; then
                    input_ok="true"
                else
                    ((i--))
                    echo "Respuesta no válida. Le quedan $i intentos."
                fi
                if [ "$i" -eq 0 ]; then
                    return_to_menu="true"
                    break
                fi
            done

            if [ "$return_to_menu" == "true" ]; then
                read -rp "Introduzca cualquier tecla para regresar al menú:" key
                clear
                continue
            fi
        fi

        if [ "$use_analysis" == "s" ]; then
            #Variable auxliar para contar el numero de filas que tendra la nueva matriz prediccion
            k=0
            #Recorre la matriz de analisis y la copia a una nueva matriz para la prediccion
            for ((i = 0; i < analysis_matrix_rows; i++)); do
                email_id=${analysis_matrix["$i,0"]}
                total_expressions=${analysis_matrix["$i,1"]}

                if [[ total_expressions -gt 0 ]]; then
                    for ((j = 0; j < cols; j++)); do
                        prediction_matrix["$k,$j"]=${analysis_matrix["$i,$j"]}
                    done
                    ((k++))
                else
                    echo "Error. El E-Mail $email_id esta vacio, no se tendra en cuenta en cuenta para el calculo del TF-IDF."
                fi
            done
            prediction_matrix_rows="$k"
            matrix_built="true"
        fi

        if [ "$analysis_completed" == "false" ] || [ "$use_analysis" == "n" ]; then
            return_to_menu="false"
            file_ok="false"
            i=3
            while [ "$i" -gt 0 ] && [ "$file_ok" == "false" ]; do
                read -rp "Introduzca el nombre del fichero (.freq) del que quiere cargar el análisis: " freq_file
                if [ -z "$freq_file" ]; then
                    ((i--))
                    echo "Entrada invalida. Le quedan $i intentos."
                elif [ ! -f "$freq_file" ]; then
                    ((i--))
                    echo "El fichero no existe. Le quedan $i intentos."
                else
                    file_ok="true"
                fi

                if [ "$i" -eq 0 ]; then
                    return_to_menu="true"
                    break
                fi
            done

            if [ "$return_to_menu" == "true" ]; then
                read -rp "Introduzca cualquier tecla para regresar al menú:" key
                clear
                continue
            fi

            # Leer el archivo línea por línea
            i=0
            while IFS= read -r line; do
                # Split de la línea en un array utilizando ":" como delimitador
                IFS=":" read -ra elements <<<"$line"

                email_id="${elements[0]}"
                num_of_terms_in_email="${elements[1]}"

                if [ "$num_of_terms_in_email" -gt 0 ]; then
                    for ((j = 0; j < ${#elements[@]}; j++)); do
                        prediction_matrix["$i,$j"]="${elements[j]}"
                    done
                    ((i++))
                else
                    echo "Avertencia: El E-Mail $email_id está vacío, no se tendrá en cuenta en el cálculo del TF-IDF."
                fi
            done <"$freq_file"

            prediction_matrix_rows="$i"
            cols=${#elements[@]}
            matrix_built="true"
        fi

        if [ "$matrix_built" == "true" ]; then
            # Crear el nuevo nombre de archivo con la extensión "tfidf"
            tfidf_file="${freq_file%.*}.tfidf"

            # Recorre la matriz y cuenta los valores mayores que 0 en cada columna
            for ((j = 3; j < cols; j++)); do
                column_counts[j]=0
                for ((i = 0; i < prediction_matrix_rows; i++)); do
                    if [[ "${prediction_matrix["$i,$j"]}" -gt 0 ]]; then
                        ((column_counts[j]++))
                    fi
                done
            done

            # Calcula TF-IDF
            for ((i = 0; i < prediction_matrix_rows; i++)); do
                row_tf_idf_sum=0
                email_id="${prediction_matrix["$i,0"]}"
                progressBar "Calculando TF-IDF para el E-Mail $email_id" "$i" "$prediction_matrix_rows"
                for ((j = 3; j < cols; j++)); do
                    occurrences=${prediction_matrix["$i,$j"]}
                    total_terms_in_email=${prediction_matrix["$i,1"]}
                    total_docs="$analysis_matrix_rows"
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
            progressBar "Calculo del TF-IDF completado" "$prediction_matrix_rows" "$prediction_matrix_rows"
            echo
            # Imprime el TF-IDF
            for ((i = 0; i < prediction_matrix_rows; i++)); do
                for ((j = 0; j < cols; j++)); do
                    echo -n "${prediction_matrix["$i,$j"]}:" >>"$tfidf_file"
                done
                echo >>"$tfidf_file"
            done
            echo
            echo "Matriz TF-IDF guardada en: $(pwd))/freq_file.freq"
            echo
            prediction_completed="true"
            read -rp "Introduzca cualquier tecla para regresar al menú:" key
        fi
        ;;
    3)
        generate_reports
        ;;
    4)
        echo "Ayuda"
        ;;
    5)
        echo "Saliendo de la aplicación..."
        exit 0
        ;;
    
    -z)
        continue
        ;;
    esac
    clear
done