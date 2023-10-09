#!/bin/bash

# Leer los correos, formatearlos y almacenar el resultado en una variable
emails=$(awk '{
    # Convertir todo a minúsculas
    line = tolower($0)

    # Extraer el ID (número seguido de una barra)
    match(line, /^[0-9]+\|/)
    id = substr(line, RSTART, RLENGTH)

    # Eliminar el ID del correo
    line = substr(line, RSTART + RLENGTH)

    # Eliminar símbolos especiales y dígitos
    gsub(/[^[:alnum:][:space:]]/, "", line)

    # Reemplazar múltiples espacios en blanco por un solo espacio
    gsub(/[[:space:]]+/, " ", line)

    # Imprimir el ID y la línea procesada
    print id line
}' "emails.txt")

# Contar el número de correos
num_of_emails=$(echo "$emails" | grep -c '^[0-9]\|')

# Procesar el archivo de palabras fradulentas y almacenar el resultado en una variable
swords=$(awk '{
    # Convertir la línea a minúsculas
    line = tolower($0)

    # Eliminar símbolos especiales y dígitos
    gsub(/[^[:alnum:][:space:]]/, "", line)

    # Reemplazar múltiples espacios en blanco por un solo espacio
    gsub(/[[:space:]]+/, " ", line)

    # Imprimir la línea procesada
    print line
}' "sword.txt")

# Contar el numero de expresiones fraudulentas
num_of_expressions=$(echo "$swords" | grep -c '^[[:alnum:][:space:]]')

echo $num_of_emails
echo $num_of_expressions

declare -A matrix

# Inicializar la matriz con ceros
for (( i = 1; i <= num_of_emails; i++ )); do
    matrix[$i,0]=$i
    matrix[$i,1]='x'
 	for (( j = 2; j <= num_of_expressions+1; j++ )); do
 		matrix[$i,$j]=0
 	done
done


# Función para imprimir la matriz actualizada
function print_matrix {
    for ((i = 1; i <= num_of_emails; i++)); do
        for ((j = 0; j <= num_of_expressions; j++)); do
            echo -n "${matrix["$i,$j"]} "
        done
        echo
    done
}

# Function to count occurrences of an expression in a given text
count_occurrences() {
  local text="$1"
  local expression="$2"
  local count=$(echo "$text" | grep -o "$expression" | wc -l)
  echo "$count"
}

exec > result.txt

# Read the text with emails line by line
while IFS= read -r email_line; do
  # Check if the line starts with a number followed by '|'
  if [[ "$email_line" =~ ^([0-9]+)\| ]]; then
    # Extract the email ID using 'head'
    email_id=$(echo "$email_line" | head -n1 | cut -d'|' -f1)

    # Extract the email text (excluding the number and '|')
    email_text="${email_line#*[0-9]|}"
    
    j=2;
    # Read the text with expressions line by line
    while IFS= read -r expression_line; do
      # Count how many times the expression appears in the email text
      count=$(count_occurrences "$email_text" "$expression_line")
      
      # Store the count in the matrix
      matrix["$email_id,$j"]=$count

      # Output the count for this expression in this email along with the ID
      echo "Expression '$expression_line' appears $count times in email $email_id:"
      echo "$email_text"
      echo

      # Update j
      j=$((j + 1))
    done <<< "$swords"
  fi
done <<< "$emails"

print_matrix>"matrix.txt"