#!/bin/bash

# Declare the associative array
declare -A matrix

# Function to set a cell value in the matrix
set_cell() {
    local key1=$1
    local key2=$2
    local value=$3
    matrix["$key1,$key2"]=$value
}

# Function to get a cell value from the matrix
get_cell() {
    local key1=$1
    local key2=$2
    echo "${matrix["$key1,$key2"]}"
}

# Example usage
set_cell "row1" "papa" 10
set_cell "row1" "hola" 20
set_cell "row2" "nigerian" 30
set_cell "row2" "fruta" 40

# Retrieve cell values
value=$(get_cell "row1" "papa")
echo "Value at (row1, papa): $value"

value=$(get_cell "row2" "nigerian")
echo "Value at (row2, col2): $value"
