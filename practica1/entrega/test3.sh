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