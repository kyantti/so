#!/usr/bin/bash

# Function to get a valid file name with optional extension and structure checks
validate_matrix_file() {
    local file="$1"
    local structure_regex="$2"
    while IFS= read -r linea; do
        # Verifica si la línea no está vacía
        if [[ -n $linea ]]; then
            # Verifica si el fichero tiene el formato correcto
            if [[ ! $linea =~ $structure_regex ]]; then
                return 0
            fi
        fi
    done <$file

    return 1
}


validate_matrix_file "b.tfidf" '^(-?[0-9]+(\.[0-9]*)?(:-?[0-9]*(\.-?[0-9]*)*)*):$'
valid=$?

rm "b.freq"

echo "$valid"

