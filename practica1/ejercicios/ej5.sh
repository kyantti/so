#!/bin/bash

# Verificar si se proporcionaron dos argumentos
if [ "$#" -ne 2 ]; then
    echo "Error: Debes proporcionar exactamente 2 números como argumentos."
    exit 1
fi

# Obtener los números de los argumentos
num1="$1"
num2="$2"

# Realizar operaciones
suma=$((num1 + num2))
resta=$((num1 - num2))
multiplicacion=$((num1 * num2))

# Manejar la división por cero
if [ "$num2" -eq 0 ]; then
    division="Error: No se puede dividir por cero."
else
    division=$(bc -l <<< "scale=2; $num1 / $num2")
fi

# Mostrar resultados
echo "Operaciones con $num1 y $num2:"
echo "Suma: $num1 + $num2 = $suma"
echo "Resta: $num1 - $num2 = $resta"
echo "Multiplicación: $num1 * $num2 = $multiplicacion"
echo "División: $num1 / $num2 = $division"
