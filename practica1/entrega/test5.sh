#!/bin/bash

emails_file=""
expressions_file=""
analysis_file=""

# Function to validate file input
validate_file() {
    local file="$1"
    local extension="$2"
    local prompt="$3"

    for((i=0;i<3;i++)); do
        read -rp "$prompt" file
        if [ -z "$file" ]; then
            continue
        elif [ ! -f "$file" ]; then
            while true; do
                read -rp "El fichero no existe. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
                if [ "$reenter" == "s" ]; then
                    break
                elif [ "$reenter" == "n" ]; then
                    exit 1
                fi
            done
        elif [ ! -s "$file" ]; then
            while true; do
                read -rp "El fichero está vacío. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
                if [ "$reenter" == "s" ]; then
                    break
                elif [ "$reenter" == "n" ]; then
                    exit 1
                fi
            done
        else
            # Set the global variable
            eval "$file_variable='$file'"
            break
        fi
    done
}

# Validate email file
file_variable="emails_file"
validate_file "$emails_file" "txt" "Introduzca el nombre del fichero que contiene los correos electrónicos: "
while grep -qvE '^[0-9]+\|.+$' "$emails_file"; do
    echo "El contenido del fichero no sigue la estructura requerida (Identificador|Contenido del correo electrónico)."
    read -rp "¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
    if [ "$reenter" == "s" ]; then
        validate_file "$emails_file" "txt" "Introduzca el nombre del fichero que contiene los correos electrónicos: "
    elif [ "$reenter" == "n" ]; then
        exit 1
    fi
done

# Validate expressions file
file_variable="expressions_file"
validate_file "$expressions_file" "txt" "Introduzca el nombre del fichero que contiene las expresiones sospechosas: "
while [ "$emails_file" == "$expressions_file" ]; do
    echo "El nombre del fichero no puede ser el mismo que el que contiene los correos electrónicos."
    read -rp "¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
    if [ "$reenter" == "s" ]; then
        validate_file "$expressions_file" "txt" "Introduzca el nombre del fichero que contiene las expresiones sospechosas: "
    elif [ "$reenter" == "n" ]; then
        exit 1
    fi
done

# Function to validate the analysis file
validate_analysis_file() {
    local file="$1"
    while true; do
        read -rp "Introduzca el nombre del fichero donde se escribirá el análisis de los correos electrónicos (.freq): " file
        if [ -z "$file" ]; then
            continue
        elif [[ "$file" != *".freq" ]]; then
            while true; do
                read -rp "La extensión del fichero no es .freq. ¿Desea volver a introducir el nombre del fichero? (s/n): " reenter
                if [ "$reenter" == "s" ]; then
                    break
                elif [ "$reenter" == "n" ]; then
                    exit 1
                fi
            done
        elif [ -e "$file" ]; then
            while true; do
                read -rp "El fichero ya existe. ¿Desea sobreescribirlo? (s/n): " overwrite
                if [ "$overwrite" == "s" ]; then
                    # Set the global variable
                    eval "$file_variable='$file'"
                    return
                elif [ "$overwrite" == "n" ]; then
                    break
                fi
            done
        else
            # Set the global variable
            eval "$file_variable='$file'"
            break
        fi
    done
}
file_variable="analysis_file"
validate_analysis_file "$analysis_file"

echo "$emails_file"
echo "$expressions_file"
echo "$analysis_file"
