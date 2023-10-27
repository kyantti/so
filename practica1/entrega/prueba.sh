#!/usr/bin/bash

# Function to get a valid file name with optional extension and structure checks
validate_file() {
    file_var="$1"
    local prompt="$2"
    local check_exists="$3"
    local extension="$4"      # Optional extension check
    local structure_regex="$5" # Optional structure regex

    local i=3
    while [ "$i" -gt 0 ]; do
        read -rp "$prompt: " file_value

        if [ -z "$file_value" ]; then
            ((i--))
            echo "🚩 Entrada inválida. Le quedan $i intentos."
        elif [ -n "$extension" ] && [[ "$file_value" != *$extension ]]; then
            ((i--))
            echo "🚩 El fichero no tiene la extensión $extension. Le quedan $i intentos."
        elif [ "$check_exists" = "true" ] && [ ! -f "$file_value" ]; then
            ((i--))
            echo "🚩 El fichero no existe. Le quedan $i intentos."
        elif [ "$check_exists" = "false" ] && [ -f "$file_value" ]; then
            ((i--))
            echo "🚩 El fichero ya existe. Le quedan $i intentos."
        elif [ -n "$structure_regex" ] &&  grep -qvE "$structure_regex" "$file_value"; then
            ((i--))
            echo "🚫 El contenido del fichero no sigue la estructura requerida. Le quedan $i intentos."
        else
            eval "$file_var=\"$file_value\""
            return 0
        fi

        if [ "$i" -eq 0 ]; then
            return 1
        fi
    done
}

structure_regex='^[0-9]+\|.+$'
emails_file=""

# Optional extension and structure checks
validate_file "emails_file" "Introduzca el nombre del fichero que contiene los correos electrónicos" "true" ".txt" "$structure_regex"

echo "$emails_file"



