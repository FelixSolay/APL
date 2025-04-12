#!/bin/bash

function ayuda() {
    echo "Esta es la ayuda del script."
}

options=$(getopt -o d:a:h:p --l help,pantalla,directorio:,archivo: -- "$@" 2> /dev/null)
if [ "$?" != "0" ] # equivale a:  if test "$?" != "0"
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"
while true
do
    case "$1" in # switch ($1) { 
        -d | --directorio) # case "-e":
            directorio="$2"
            shift 2

            echo "El parámetro -d o --directorio tiene el valor $directorio"
            ;;
        -a | --archivo)
            archivo="$2"
            shift 2
            
            echo "El parámetro -a o --archivo tiene el valor $archivo"
            ;;
        -p | --archivo)
            archivo="$2"
            shift 2
            
            echo "Se selecciono el parámetro -p o --pantalla"
            ;;            
        -h | --help)
            ayuda
            exit 0
            ;;
        --) # case "--":
            shift
            break
            ;;
        *) # default: 
            echo "error"
            exit 1
            ;;
    esac
done