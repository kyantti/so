#!/bin/bash
while true; do
    read -rp "Introduzca el nombre del fichero contenedor de los correos electrónicos: " file
    if [ -z "$file" ]; then
        continue
    elif [ "${file##*.}" != "txt" ]; then
        while true; do
            read -rp "La extensión del fichero no es .txt. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
            if [ "$reenter" == "s" ]; then
                break # Exit the inner loop if the user enters "s"
            elif [ "$reenter" == "n" ]; then
                exit 1 # Exit the script if the user enters "n"
            fi
        done
    elif [ ! -f "$file" ]; then
        while true; do
            read -rp "El fichero no existe. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
            if [ "$reenter" == "s" ]; then
                break # Exit the inner loop if the user enters "s"
            elif [ "$reenter" == "n" ]; then
                exit 1 # Exit the script if the user enters "n"
            fi
        done
    elif [ ! -s "$file" ]; then
        while true; do
            read -rp "El fichero está vacio. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
            if [ "$reenter" == "s" ]; then
                break # Exit the inner loop if the user enters "s"
            elif [ "$reenter" == "n" ]; then
                exit 1 # Exit the script if the user enters "n"
            fi
        done
    else
        if grep -qvE '^[0-9]+\|.+$' "$file"; then
            echo "El contenido del fichero no sigue la estructura requerida (Identificador|Contenido del correo electrónico)."
            while true; do
                read -rp "¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
                if [ "$reenter" == "s" ]; then
                    break # Exit the inner loop if the user enters "s"
                elif [ "$reenter" == "n" ]; then
                    exit 1 # Exit the script if the user enters "n"
                fi
            done
        else
            break
        fi
    fi
done
