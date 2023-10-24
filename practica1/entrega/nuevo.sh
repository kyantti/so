#!/usr/bin/bash


freq_file="analisis.freq"
new_extension="tfidf"

# Extraer el nombre del archivo (sin la extensión) de freq_file
file_name="${freq_file%.*}"

# Crear el nuevo nombre de archivo con la extensión "tfidf"
new_file="${file_name}.${new_extension}"

echo "$new_file"

# Renombrar el archivo
#mv "$freq_file" "$new_file"
