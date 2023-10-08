#!/bin/bash

# Función para generar números aleatorios sin repetición
generate_unique_random() {
    local n="$1"
    local max="$2"

    if [ "$n" -le "$max" ]; then
        jot -r "$n" 1 "$max" | tr '\n' ' '
    else
        echo "Error: El número de aleatorios a generar no puede ser mayor que $max."
    fi
}

# Función para generar números aleatorios con repetición
generate_random_with_repetition() {
    local n="$1"
    local max="$2"

    jot -r "$n" 1 "$max" | tr '\n' ' '
}

# Pedir al usuario el número de aleatorios a generar
echo "Introduce el número de aleatorios a generar (N): "
read n

# Validar que N sea un número positivo
if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt 0 ]; then
    echo "a. Números aleatorios con repetición:"
    generate_random_with_repetition "$n" 100  # Cambia 100 al valor máximo deseado

    echo -e "\nb. Números aleatorios sin repetición:"
    generate_unique_random "$n" 100  # Cambia 100 al valor máximo deseado
else
    echo "Error: Ingresa un número positivo válido para N."
fi
