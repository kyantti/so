#!/bin/bash

declare -A matrix

nRows=10;
nColumns=10;

for (( i = 0; i < nRows; i++ )); do
 	for (( j = 0; j < nColumns; j++ )); do
 		matrix[$i,$j]="$RANDOM"
 	done
done

for (( i = 0; i < nRows; i++ )); do
 	for (( j = 0; j < nColumns; j++ )); do
 		echo -n "${matrix[$i,$j]}"":">>"matrix.freq"
 	done
 	echo>>"matrix.freq"
done


