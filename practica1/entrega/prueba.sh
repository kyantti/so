#!/usr/bin/bash
declare -A prediction_matrix
# Leer el archivo línea por línea
k=0
while IFS= read -r line; do
    # Verificar si la línea está vacía
    if [ -n "$line" ]; then
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
    fi

done <"analisis.freq"

prediction_matrix_rows="$k"
cols=${#elements[@]}

echo "$cols"

echo "Filas PM: $prediction_matrix_rows"

# Imprimir la nueva matriz
for ((i = 0; i < prediction_matrix_rows; i++)); do
    for ((j = 0; j < ${#elements[@]}; j++)); do
        echo -n "${prediction_matrix["$i,$j"]}:"
    done
    echo
done
