#!/usr/bin/bash


file="analisis.freq"  # Reemplaza con el nombre de tu archivo

pattern="^(-?[0-9]+(:-?[0-9]+)*):$"

while IFS= read -r linea; do
    if [[ -n $linea ]]; then
        if [[ $linea =~ $pattern ]]; then
            echo "Valid line: $linea"
        else
            echo "Invalid line: $linea"
        fi
    fi
done < "$file"
