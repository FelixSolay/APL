#!/bin/bash
hola
options=$(getopt -o d:a:p:h --l directorio,pantalla:,archivo:,help -- "$@" 2> /dev/null)
if [ "$?" != "0" ] # equivale a:  if test "$?" != "0"
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"

while true
do
    case "$1" in 
        -d | --directorio) 
            directorio="$2"
            shift 2

            echo "El parámetro -d tiene el valor $directorio"
            ;;
        -a | --archivo)
            archivo="$2"
            shift 2
            
            echo "El parámetro -a o --archivo tiene el valor $archivo"
            ;;

        -p | --pantalla)
            pantalla="$2"
            shift 2
            
            echo "El parámetro -p o --pantalla tiene el valor $pantalla"
            ;;

        -h | --help)
            echo 'Aca vamos a poner el mensaje de ayuda del ejercicio 1'
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

