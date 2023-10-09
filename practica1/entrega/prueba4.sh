#!/bin/bash


declare -A matrix

# Inicializar la matriz con ceros
for (( i = 1; i <= 100; i++ )); do
    matrix[$i,0]=$i
    matrix[$i,1]='x'
 	for (( j = 2; j <= 201; j++ )); do
 		matrix[$i,$j]=0
 	done
done

# Función para imprimir la matriz actualizada
function print_matrix {
    for ((i = 1; i <= 100; i++)); do
        for ((j = 0; j <= 201; j++)); do
            echo -n "${matrix["$i,$j"]} "
        done
        echo
    done
}

print_matrix>"matrix2.txt"