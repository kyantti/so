#!/bin/bash

# Obtener la fecha y la hora actual
current_date=$(date +"%Y-%m-%d")
current_date2=$(date +"%d/%m/%y")
current_date3=$(date +"%A %d de %B de %Y")
current_time=$(date +"%H:%M:%S")
current_time2=$(date +"%H:%M")

# Mostrar los resultados
echo "a. $current_date"
echo "b. $current_date2"
echo "c. $current_date3"
echo "d. $current_time"
echo "e. $current_time2"
