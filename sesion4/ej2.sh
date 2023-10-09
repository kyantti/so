#!/bin/bash

# shell script que reciba como argumento de entrada el nombre de un fichero
# llama a una función que compruebe si ha recibido el numero de parámetros correctos y el primer
# parametro es un fichero.
# Si los parámetros son correctos y el parámetro 1 es un fichero se devuelve 0, en caso contrario
# se devuelve 1.

file_name=$1

function verify_file() {
    # Verificar la cantidad de parámetros
    if [ $# -ne 1 ]; then
        echo "Número incorrecto de parámetros."
        return 1
    fi

    # Verificar si el primer parámetro es un fichero
    if [ ! -f $file_name ]; then
        echo "El primer parámetro no es un fichero."
        return 1
    fi

    return 0
}

verify_file $file_name
echo "Devuelve: $?"
