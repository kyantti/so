#!/bin/bash

#Numero de parametros correcto
#Parametro es fichero
#Cargue en cada fila de la matriz una de las lineas de ese fichero

declare -A matrix;

# Verificar si se proporcionó un argumento
if [ $# -eq 0 ]; then
    echo "Proporciona un argumento que sea el nombre de un archivo (.txt) existente."
    exit 1
fi

# Verificar si el argumento es un archivo .txt existente
if [ -f "$1" ] && [[ "$1" == *.txt ]]; then
    echo "$1 es un archivo .txt existente."
else
    echo "$1 no es un archivo .txt existente."
fi


