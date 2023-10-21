#!/bin/bash

# Función para pasar texto a minúsculas
to_lower() {
    awk '{print tolower($0)}'
}

# Función para quitar espacios en blanco
remove_spaces() {
    awk '{ gsub(/ /,""); print }'
}

# Función para eliminar símbolos especiales y dígitos
remove_special_chars() {
    sed 's/[^a-zA-Z ]//g'
}

# Función para realizar el análisis de datos
verify_input() {
    echo "Introduce el nombre del fichero que contiene las palabras fraudulentas (.txt):"
    read -r words_file

    # Verificar la existencia de los ficheros
    if [ ! -f "$words_file" ]; then
        echo "No existe ningun fichero con ese nombre."
        return
    fi

    echo "Introduce el nombre del fichero que contiene los correos electrónicos (.txt):"
    read -r emails_file

    # Verificar la existencia de los ficheros
    if [ ! -f "$emails_file" ]; then
        echo "No existe ningun fichero con ese nombre."
        return
    fi

    echo "Introduce el nombre del fichero para guardar el resultado del análisis (.freq):"
    read -r result_file


    # Verificar si el archivo de resultado ya existe
    if [ -f "$result_file" ]; then
        echo "El archivo de resultado ya existe. Por favor, elige un nombre diferente."
        return
    fi

}

# Función para realizar la predicción
predict() {
    echo "Función de predicción no implementada todavía."
}

# Función para generar informes de resultados
generate_reports() {
    echo "Función de informes de resultados no implementada todavía."
}

# Función para mostrar ayuda
show_help() {
    echo "Ayuda:"
}

while true; do
    echo "Menú:"
    echo "Seleccione una opción:"
    echo "1. Análisis de datos"
    echo "2. Predicción"
    echo "3. Informes de resultados"
    echo "4. Ayuda"
    echo "5. Salir"
    read choice

    case $choice in
    1)
        verify_input
        ;;
    2)
        predict
        ;;
    3)
        generate_reports
        ;;
    4)
        show_help
        ;;
    5)
        echo "Saliendo de la aplicación."
        exit 0
        ;;
    *)
        echo "Opción no válida. Por favor, seleccione una opción válida del menú."
        ;;
    esac
done
