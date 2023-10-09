#!/bin/bash

# Comprobar que el shell script ha recibido los argumentos correctos
# 


function verify_file(){
    echo "0: " $0
    echo "1: " $1
    echo "?: " $?
    echo "$: " $$
    echo "*: " $*
    echo "#: " $#
}

verify_file

