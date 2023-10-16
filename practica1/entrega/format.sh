#!/bin/bash


to_lower() {
    awk '{print tolower($0)}'
}


remove_special_chars() {
    awk '{ gsub(/[^[:alnum:] ]/, " "); gsub(/  +/, " "); print }'
}

reduce_spaces() {
    tr -s ' '
}

# Texto de ejemplo (reemplázalo con tu propio texto)
texto="1|Este es un ejemplo de texto con varias palabras."

# Usa el comando 'echo' para imprimir el texto y luego utiliza 'wc' para contar las palabras
echo "$texto" | wc -w