#!/bin/bash

emails_file=""
expressions_file=""
freq_file=""
tfidf_file""
analysis_completed="false"
declare -A freq_matrix
declare -A tfidf_matrix
declare -a column_counts
freq_matrix_rows=0
tfidf_matrix_rows=0
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

# Usage: bannerColor "my title" "red" "*"
function bannerColor() {
    case ${2} in
    black)
        color=0
        ;;
    red)
        color=1
        ;;
    green)
        color=2
        ;;
    yellow)
        color=3
        ;;
    blue)
        color=4
        ;;
    magenta)
        color=5
        ;;
    cyan)
        color=6
        ;;
    white)
        color=7
        ;;
    *)
        echo "color is not set"
        exit 1
        ;;
    esac

    local msg="${3} ${1} ${3}"
    local edge
    edge=${msg//?/$3}
    tput setaf ${color}
    tput bold
    echo "${edge}"
    echo "${msg}"
    echo "${edge}"
    tput sgr 0
    echo
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
                echo "🚩 Entrada invalida. Le quedan $i intentos."
            elif [ ! -f "$emails_file" ]; then
                ((i--))
                echo "🚩 El fichero no existe. Le quedan $i intentos."
            elif grep -qvE '^[0-9]+\|.+$' "$emails_file"; then
                ((i--))
                echo "🚫 El contenido del fichero no sigue la estructura requerida (Identificador|Contenido del correo electrónico). Le quedan $i intentos."
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
                echo "🚩 Entrada invalida. Le quedan $i intentos."
            elif [ ! -f "$expressions_file" ]; then
                ((i--))
                echo "🚩 El fichero no existe. Le quedan $i intentos."
            elif [ "$expressions_file" == "$emails_file" ]; then
                ((i--))
                echo "🚫 El fichero no puede ser el mismo que el que contiene los correos electrónicos. Le quedan $i intentos."
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
                echo "🚩 Entrada invalida. Le quedan $i intentos."
            elif [ -e "$freq_file" ]; then
                ((i--))
                echo "🚩 El fichero ya existe. Le quedan $i intentos."
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
        while IFS="|" read -r email_id email_content spam_or_ham blank; do
            cleaned_email_content=$(clean_text "$email_content")
            total_expressions=$(echo "$cleaned_email_content" | wc -w | tr -d '[:space:]')
            freq_matrix["$i,0"]="$email_id"
            freq_matrix["$i,1"]="$total_expressions"
            freq_matrix["$i,2"]="$spam_or_ham"
            progressBar "Analizando E-Mail $email_id" "$i" "$total_emails"
            j=3
            while read -r expression; do
                cleaned_expression=$(clean_text "$expression")
                count=$(echo "$cleaned_email_content" | grep -o "$cleaned_expression" | wc -l | tr -d '[:space:]')
                freq_matrix["$i,$j"]="$count"
                ((j++))
            done <"$expressions_file"
            ((i++))
        done <"$emails_file"
        freq_matrix_rows=$i
        cols=$j
        analysis_completed="true"


        # Imprime la matriz freq en el fichero
        for((i=0;i<freq_matrix_rows;i++)); do
            for((j=0;j<cols;j++)); do
                echo -n "${freq_matrix["$i,$j"]}:" >> "$freq_file"
            done
            echo >> "$freq_file"
        done

        # Recorre la matriz y cuenta los valores mayores que 0 en cada columna
        for ((j = 3; j < cols; j++)); do
            column_counts[j]=0
            for ((i = 0; i < freq_matrix_rows; i++)); do
                if [[ "${freq_matrix["$i,$j"]}" -gt 0 ]]; then
                    ((column_counts[j]++))
                fi
            done
        done
        progressBar "✅ Análisis completado con éxito" "$total_emails" "$total_emails"
        echo
        bannerColor "📄 Matriz de análisis guardada en: $(pwd)/$freq_file" "black" "*"
        echo
        read -rp "Introduzca cualquier tecla para regresar al menú:" key
        ;;
    2)
        use_current_analysis=""
        return_to_menu="false"
        freq_matrix_built="false"
        if [ "$analysis_completed" == "true" ]; then
            input_ok="false"
            i=3
            while [ "$i" -gt 0 ] && [ "$input_ok" == "false" ]; do
                read -rp "Se ha encontrado un análisis en la ejecución. ¿Desea utilizarlo? (s/n):" use_current_analysis
                if [ "$use_current_analysis" == "s" ]; then
                    input_ok="true"
                    echo "Usando el análisis encontrado en la ejecución."
                elif [ "$use_current_analysis" == "n" ]; then
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

        if [ "$use_current_analysis" == "s" ]; then
            #Variable auxliar para contar el numero de filas que tendra la nueva matriz prediccion
            k=0
            #Recorre la matriz de analisis y la copia a una nueva matriz para la prediccion
            for ((i = 0; i < freq_matrix_rows; i++)); do
                email_id=${freq_matrix["$i,0"]}
                total_expressions=${freq_matrix["$i,1"]}

                if [[ total_expressions -gt 0 ]]; then
                    for ((j = 0; j < cols; j++)); do
                        tfidf_matrix["$k,$j"]=${freq_matrix["$i,$j"]}
                    done
                    ((k++))
                else
                    echo "🤓 👉 Advertencia: El E-Mail $email_id esta vacio, no se tendra en cuenta en cuenta para el calculo del TF-IDF."
                fi
            done
            tfidf_matrix_rows="$k"
            freq_matrix_built="true"
        fi

        if [ "$analysis_completed" == "false" ] || [ "$use_current_analysis" == "n" ]; then
            return_to_menu="false"
            file_ok="false"
            load_tfidf="false"
            tfidf_file=""
            i=3
            while [ "$i" -gt 0 ] && [ "$file_ok" == "false" ]; do
                read -rp "Introduzca el nombre del fichero (.freq) del que quiere cargar el análisis: " freq_file
                tfidf_file="${freq_file%.*}.tfidf"
                if [ -z "$freq_file" ]; then
                    ((i--))
                    echo "Entrada invalida. Le quedan $i intentos."
                elif [ ! -f "$freq_file" ]; then
                    ((i--))
                    echo "El fichero no existe. Le quedan $i intentos."
                elif [ -f "$tfidf_file" ] && [ -s "$tfidf_file" ]; then
                    j=3
                    input_valid="false"
                    tfidf_file_is_valid="true"
                    while IFS= read -r linea; do
                        # Verifica si la línea no está vacía
                        if [[ -n $linea ]]; then
                            # Verifica si el fichero tiene el formato correcto
                            if [[ ! $linea =~ ^(-?[0-9]+(\.[0-9]*)?(:-?[0-9]*(\.-?[0-9]*)*)*):$ ]]; then
                                tfidf_file_is_valid="false"
                            fi
                        fi
                    done <"$tfidf_file"

                    if [ "$tfidf_file_is_valid" == "false" ]; then
                        echo "🚩 Advertencia: Se ha encontrado un fichero .tfidf no valido para el fichero .freq introducido."
                        echo "                   Por favor, revise el fichero en en el caso de que quiera utilizarlo para una nueva predicción."
                        continue
                    fi

                    while [ "$j" -gt 0 ] && [ "$input_valid" == "false" ] && [ "$tfidf_file_is_valid" == "true" ]; do
                        echo "Se ha encontrado un fichero con extensión .tfidf para el fichero .freq introducido, ¿Desea cargarlo para una nueva predicción?"
                        echo "s 👉 El fichero con la matriz TF-IDF se utilizará para calcular una nueva predicción"
                        echo "n 👉 El fichero con la matriz TF-IDF se borrará y se volverá a realizar el calculo del TF-IDF y la predicción"
                        read -rp "Seleccione una opción (s/n): " input

                        if [ -z "$input" ]; then
                            ((j--))
                            echo "Entrada invalida. Le quedan $j intentos."
                        elif [ "$input" == "s" ]; then
                            load_tfidf="true"
                            input_valid="true"
                            file_ok="true"
                        elif [ "$input" == "n" ]; then
                            rm "$tfidf_file"
                            load_tfidf="false"
                            input_valid="true"
                            file_ok="true"
                        else
                            ((j--))
                            echo "Entrada invalida. Le quedan $j intentos."
                        fi

                    done

                elif [ -e "$freq_file" ]; then
                    # Compruebo si el fichero sigue le formato correcto
                    valid_format="true"
                    while IFS= read -r linea; do
                        if [[ -n $linea ]]; then
                            if [[ ! $linea =~ ^(-?[0-9]+(:-?[0-9]+)*):$ ]]; then
                               valid_format="false"
                            fi
                        fi
                    done <"$freq_file"
                    if [ "$valid_format" == "true" ]; then
                        file_ok="true"
                    else
                       ((i--))
                        echo "El fichero no sigue un formato valido. Le quedan $i intentos."
                    fi

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

            # Leer el archivo con la matriz .freq línea por línea
            i=0
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    # Split de la línea en un array utilizando ":" como delimitador
                    IFS=":" read -ra elements <<<"$line"

                    email_id="${elements[0]}"
                    num_of_terms_in_email="${elements[1]}"

                    if [ "$num_of_terms_in_email" -gt 0 ]; then
                        for ((j = 0; j < ${#elements[@]}; j++)); do
                            tfidf_matrix["$i,$j"]="${elements[j]}"
                        done
                        ((i++))
                    else
                        echo "🤓 👉 Advertencia: El E-Mail $email_id está vacío, no se tendrá en cuenta en el cálculo del TF-IDF."
                    fi
                fi

            done <"$freq_file"

            tfidf_matrix_rows="$i"
            cols=${#elements[@]}
            freq_matrix_built="true"
        fi

        if [ "$freq_matrix_built" == "true" ]; then
            # Crear el nuevo nombre de archivo con la extensión "tfidf"
            tfidf_file="${freq_file%.*}.tfidf"

            # Recorre la matriz y cuenta los valores mayores que 0 en cada columna
            for ((j = 3; j < cols; j++)); do
                column_counts[j]=0
                for ((i = 0; i < tfidf_matrix_rows; i++)); do
                    if [[ "${tfidf_matrix["$i,$j"]}" -gt 0 ]]; then
                        ((column_counts[j]++))
                    fi
                done
            done

            # Calcula TF-IDF
            if [ "$load_tfidf" == "false" ] || [ "$use_current_analysis" == "s" ]; then
                for ((i = 0; i < tfidf_matrix_rows; i++)); do
                    email_id="${tfidf_matrix["$i,0"]}"
                    progressBar "Calculando TF-IDF para el E-Mail $email_id" "$i" "$tfidf_matrix_rows"
                    for ((j = 3; j < cols; j++)); do
                        occurrences=${tfidf_matrix["$i,$j"]}
                        total_terms_in_email=${tfidf_matrix["$i,1"]}
                        total_docs="$freq_matrix_rows"
                        docs_containing_term=${column_counts[j]}
                        if [ "$docs_containing_term" -eq 0 ]; then
                            docs_containing_term=1
                        fi
                        tf=$(echo "scale=2; $occurrences / $total_terms_in_email" | bc)
                        idf=$(echo "scale=2; l($total_docs/$docs_containing_term)/l(10)" | bc -l)
                        tf_idf=$(echo "$tf * $idf" | bc -l)
                        tfidf_matrix["$i,$j"]="$tf_idf"
                    done
                done

                progressBar "✅ TF-IDF calculado con éxito" "$tfidf_matrix_rows" "$tfidf_matrix_rows"
                echo
                echo

            elif [ "$load_tfidf" == "true" ]; then
                # Leer el archivo línea por línea
                tfidf_matrix_rows="$(wc -l <"$tfidf_file")"
                i=0
                while IFS= read -r line; do
                    # Split de la línea en un array utilizando ":" como delimitador
                    IFS=":" read -ra elements <<<"$line"
                    email_id="${elements[0]}"
                    progressBar "Cargando TF-IDF para el E-Mail $email_id" "$i" "$tfidf_matrix_rows"
                    for ((j = 0; j < ${#elements[@]}; j++)); do
                        tfidf_matrix["$i,$j"]="${elements[j]}"
                    done
                    ((i++))
                done <"$tfidf_file"

                progressBar "✅ TF-IDF cargado con éxito" "$tfidf_matrix_rows" "$tfidf_matrix_rows"
                echo
                echo

            fi

            # Calcula la predicción. Resultado en nueva columna
            for ((i = 0; i < tfidf_matrix_rows; i++)); do
                row_tf_idf_sum=0
                email_id="${tfidf_matrix["$i,0"]}"
                progressBar "Calculando predicción para el E-Mail $email_id" "$i" "$tfidf_matrix_rows"
                for ((j = 3; j < cols; j++)); do
                    tf_idf="${tfidf_matrix["$i,$j"]}"
                    row_tf_idf_sum=$(echo "scale=2; $row_tf_idf_sum + $tf_idf" | bc)
                done
                average_tf_idf=$(echo "scale=2; $row_tf_idf_sum / (cols - 3)" | bc)
                if (($(echo "$average_tf_idf > 0.3" | bc -l))); then
                    tfidf_matrix["$i,$cols"]="1"
                else
                    tfidf_matrix["$i,$cols"]="0"
                fi
            done

            progressBar "✅ Predicción calculada con éxito" "$tfidf_matrix_rows" "$tfidf_matrix_rows"
            echo

            # Imprime la matriz final en el fichero .tfidf
            for ((i = 0; i < tfidf_matrix_rows; i++)); do
                for ((j = 0; j < cols + 1; j++)); do
                    echo -n "${tfidf_matrix["$i,$j"]}:" >>"$tfidf_file"
                done
                echo >>"$tfidf_file"
            done

            bannerColor "📄 Matriz TF-IDF guardada en: $(pwd))/$tfidf_file" "black" "*"
            echo
            read -rp "Introduzca cualquier tecla para regresar al menú:" key
        fi
        ;;
    3)
        if [ "$analysis_completed" == "false" ]; then
            #echo "Error: No se puede acceder a los informes sin realizar un análisis previo"
            bannerColor "Error: No se puede acceder a los informes sin realizar un análisis previo" "red" "x"

            read -rp "Introduzca cualquier tecla para regresar al menú:" key
            clear
            continue
        else
            while true; do
                clear
                echo "Informes:"
                echo
                echo "1. Informe en formato fila/columna donde por cada término muestre en cuantos correos electrónicos del conjunto de datos analizado aparece."
                echo "2. Informe donde para un término particular, solicitado al usuario, se muestren los correos electrónicos donde aparece. Del correo electrónico sólo se mostrarán los 50 primeros caracteres."
                echo "3. Dado un identificador de correo electrónico, mostrar cuantos términos de los analizados aparecen."
                echo "4. Regresar al menu principal"
                echo
                read -rp "Seleccione una opción (1-4): " choice

                case "${choice}" in
                1)
                    i=3
                    while IFS= read -r expression; do
                        echo "$expression ${column_counts[i]}"
                        ((i++))
                    done <"$expressions_file"
                    read -rp "Introduzca cualquier tecla para regresar al menú de informes:" key
                    ;;
                2)
                    return_to_reports_menu="false"
                    expression_found="false"
                    expression_appears="false"
                    i=3
                    while [ "$i" -gt 0 ] && [ "$expression_found" == "false" ]; do
                        read -rp "Introduzca una expresión: " input
                        if [ -z "$input" ]; then
                            ((i--))
                            echo "Entrada invalida. Le quedan $i intentos."
                        else
                            j=3
                            while IFS= read -r expression && [ "$expression_found" == "false" ]; do
                                if [ "$expression" == "$input" ]; then
                                    expression_found="true"
                                else
                                    ((j++))
                                fi
                            done <"$expressions_file"

                            if [ "$expression_found" == "false" ]; then
                                ((i--))
                                echo "Expresión no encontrada, le quedan $i intentos."
                            fi
                        fi

                        if [ "$i" -eq 0 ]; then
                            return_to_reports_menu="true"
                            break
                        fi

                    done

                    if [ "$return_to_reports_menu" == "true" ]; then
                        read -rp "Introduzca cualquier tecla para regresar al menú de informes:" key
                        clear
                        continue
                    fi

                    # Recorrer la matriz de analisis para buscar el correo que contenga el termino
                    for ((i = 0; i < freq_matrix_rows; i++)); do
                        if [ "${freq_matrix["$i,$j"]}" -gt 0 ]; then
                            expression_appears="true"
                            email_id="${freq_matrix["$i,0"]}"
                            while IFS= read -r line; do
                                # Verifica si la línea comienza con el id
                                if [[ "$line" =~ ^$email_id ]]; then
                                    # Muestra los primeros 50 caracteres de la línea
                                    echo "${line:0:50}"
                                fi
                            done <"${emails_file}"
                        fi
                    done

                    if [ "$expression_appears" == "false" ]; then
                        echo "La expresión $input no aparece en ningún correo eletrónico."
                        echo
                    fi
                    read -rp "Introduzca cualquier tecla para regresar al menú de informes:" key
                    ;;
                3)
                    return_to_reports_menu="false"
                    email_found="false"
                    email_id=0
                    num_of_expressions=0
                    i=3
                    while [ "$i" -gt 0 ] && [ "$email_found" == "false" ]; do
                        read -rp "Introduzca un identificador : " input
                        if [ -z "$input" ]; then
                            ((i--))
                            echo "Entrada invalida. Le quedan $i intentos."
                        elif [[ ! "$input" =~ ^[0-9]+$ ]]; then
                            ((i--))
                            echo "Entrada invalida. Le quedan $i intentos."
                        else
                            j=0
                            while [ "$email_found" == "false" ]; do
                                email_id="${freq_matrix["$j,0"]}"
                                if [ "$email_id" -eq "$input" ]; then
                                    email_found="true"
                                else
                                    ((j++))
                                fi
                            done

                            if [ "$email_found" == "false" ]; then
                                ((i--))
                                echo "Correo electrónico no encontrado, le quedan $i intentos."
                            fi

                        fi

                        if [ "$i" -eq 0 ]; then
                            return_to_reports_menu="true"
                            break
                        fi

                    done

                    if [ "$return_to_reports_menu" == "true" ]; then
                        read -rp "Introduzca cualquier tecla para regresar al menú de informes:" key
                        clear
                        continue
                    fi

                    for ((i = 3; i < cols; i++)); do
                        if [ "${freq_matrix["$j,$i"]}" -gt 0 ]; then
                            ((num_of_expressions++))
                        fi
                    done

                    echo "En el correo electrónico $email_id aparecen $num_of_expressions de un total de $((cols - 3)) expresiones sospechosas."
                    echo
                    read -rp "Introduzca cualquier tecla para regresar al menú de informes:" key
                    ;;
                4)

                    break
                    ;;
                *)
                    echo "default (none of above)"
                    ;;
                esac

            done
        fi

        ;;
    4)
        echo "=== Ayuda ==="
        echo "Esta aplicación realiza análisis de correos electrónicos para identificar spam."
        echo "Opciones disponibles:"
        echo "1. Análisis de datos: Realiza el análisis de frecuencia de palabras en los correos."
        echo "2. Predicción: Calcula la métrica TF-IDF y predice si un correo es spam o ham."
        echo "3. Informes de resultados: Genera informes basados en los datos analizados."
        echo "4. Ayuda: Muestra esta información de ayuda."
        echo "5. Salir: Finaliza la aplicación."
        echo "Recuerda controlar los errores y seguir las instrucciones en cada opción."
        read -rp "Introduzca cualquier tecla para regresar al menú principal: " key
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
