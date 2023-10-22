#!/bin/bash

emails_file=emails.txt
swords_file=sword.txt
output_file=matrix.txt

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

analyze_emails() {
   while true; do
      # Prompt for the first file
      read -rp "Introduzca el nombre del fichero contenedor de los correos electrónicos: " emails_file

      # Check if the first file exists
      if [ ! -f "$emails_file" ]; then
         read -rp "El fichero no existe. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
         case "$reenter" in
         [Ss]*)
            continue
            ;;
         [Nn]*)
            exit 1
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      elif [ ! -s "$emails_file" ]; then
         read -rp "El fichero está vacio. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
         case "$reenter" in
         [Ss]*)
            continue
            ;;
         [Nn]*)
            exit 1
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      else
         # Check if the first file follows the specified structure
         if grep -qvE '^[0-9]+\|.+$' "$emails_file"; then
            echo "El contenido del fichero no sigue la estructura requerida (ID|Contenido del correo electrónico)."
            read -rp "¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
            case "$reenter" in
            [Ss]*)
               continue
               ;;
            [Nn]*)
               exit 1
               ;;
            *)
               echo "Por favor introduzca 's' para SI o 'n' para NO."
               ;;
            esac
         fi
         break
      fi
   done

   while true; do
      # Prompt for the second file
      read -rp "Introduzca el nombre del fichero contenedor de las expresiones sospechosas: " expressions_file

      # Check if the second file exists
      if [ ! -f "$expressions_file" ]; then
         read -rp "El fichero no existe. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
         case "$reenter" in
         [Ss]*)
            continue
            ;;
         [Nn]*)
            exit 1
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      elif [ ! -s "$expressions_file" ]; then
         read -rp "El fichero está vacio. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
         case "$reenter" in
         [Ss]*)
            continue
            ;;
         [Nn]*)
            exit 1
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      elif [ "$expressions_file" = "$emails_file" ]; then
         echo "El fichero contenedor de las expresiones sospechosas no puede ser el mismo que el fichero contenedor de los correos electrónicos."
         read -rp "¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
         case "$reenter" in
         [Ss]*)
            continue
            ;;
         [Nn]*)
            exit 1
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      else
         break
      fi
   done

   # Prompt for the third file
   while true; do
      read -rp "Introduzca el nombre del fichero donde se escribirá el análisis de los correos electrónicos. (.freq): " analysis_file

      if [[ "$analysis_file" != *".freq" ]]; then
         echo "El fichero debe tener la extesion '.freq' ."
         read -rp "¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
         case "$reenter" in
         [Ss]*)
            continue
            ;;
         [Nn]*)
            exit 1
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      elif [ -e "$analysis_file" ]; then
         read -rp "El fichero ya existe. ¿Desea sobreescribirlo? (s/n): " overwrite
         case "$overwrite" in
         [Ss]*)
            break
            ;;
         [Nn]*)
            continue
            ;;
         *)
            echo "Por favor introduzca 's' para SI o 'n' para NO."
            ;;
         esac
      else
         break
      fi
   done

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
   done <"$emails_file"

   rows=$i
   cols=$j

   # Imprimir la nueva matriz
   for ((i = 0; i < rows; i++)); do
      for ((j = 0; j < cols; j++)); do
         echo -n "${analysis_matrix["$i,$j"]}:" >>"$analysis_file"
      done
      echo >>"$analysis_file"
   done

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

#analyze_emails "emails.txt" "sword.txt" "analisis.freq"
create_prediction_matrix_from_file "analisis.freq"
#create_prediction_matrix_from_anylisis
predict_email_intent
