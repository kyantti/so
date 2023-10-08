#!/bin/bash

declare -A matrix

nRows=3;
nColumns=2;

for (( i = 0; i < nRows; i++ )); do
 	for (( j = 0; j < nColumns; j++ )); do
 		matrix[$i,$j]=$RANDOM
 	done
done

for (( i = 0; i < nRows; i++ )); do
 	for (( j = 0; j < nColumns; j++ )); do
 		echo -n ${matrix[$i,$j]} " "
 	done
 	echo
done 