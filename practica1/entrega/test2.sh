#!/bin/bash

# Nombre del archivo que contiene la matriz
archivo="analysis_matrix.freq"

# Inicializar una matriz vacía
declare -A matriz

fila=0

# Leer el archivo línea por línea y dividir en elementos utilizando IFS
while IFS=":" read -ra elementos; do
  for ((col = 0; col < ${#elementos[@]}; col++)); do
    matriz["$fila,$col"]="${elementos[$col]}"
  done
  ((fila++))
done < "$archivo"

# Imprimir la nueva matriz
for (( i = 0; i < fila; i++ )); do
 	for (( j = 0; j < col; j++ )); do
 		echo -n ${matriz[$i,$j]}":"
 	done
 	echo
done 


calc_docs_cotaining_term(){
    row_rep_of_term=$1
    count=0

    for ((i = 0; i < analysis_matrix_rows; i++)); do
        if [ "${matrix[$i,$row_rep_of_term]}" -gt 0 ]; then
            ((count++))
        fi
    done

    echo "$count"
}

function calc_total_terms() {
    text="$1"
    if [ -z "$text" ]; then
        echo "Error: Texto vacio, no se pueden contar los terminos."
        return 1
    else
        total_terms=$(echo "$text" | wc -w)
        echo "$total_terms"
        return 0
    fi
}

echo $(calc_total_terms "     ")

function calc_term_freq(){
    occurrences=$1
    total_terms=$2

    if [ "$total_terms" -gt 0 ]; then
        frequency=$(echo "scale=2; $occurrences / $total_terms" | bc)
        echo "$frequency"
        return 0
    else
        echo "Error: Division por cero. El E-Mail esta vacio."
        return 1
    fi

}