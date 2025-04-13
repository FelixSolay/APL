#!/bin/bash

##---------------------------------------FUNCIONES---------------------------------------
function ayuda() {
    echo "Esta es la ayuda del script del ejercicio 1 de la APL 1."
}

#Valida el JSON sin imprimirlo en pantalla
function validarJSON()
{
    if jq empty $1 > /dev/null 2>&1; then
        echo "El JSON es válido"
    else
        echo "El JSON es inválido"
        exit 1
fi

}

function validaciones()
{
    #$1 = directorio
    #$2 = archivo
    #$3 = pantalla
    if [[ "$2" = "" &&  "$3" = "" ]]; then
    echo "No se cargó un archivo de salida o salida por pantalla"
    exit 1
fi

if [[ ! -s "$1" ]]; then
    echo "El directorio no existe o tiene un tamaño de 0 bytes"
    exit 2
fi

if [[ ! "$1" == *.csv ]]; 
then
    echo "El directorio no es del tipo CSV (Valores separados por comas)"
    exit 3
fi

if [[ "$1" == *.*.* ]]; 
then
    echo "El directorio contiene doble extension"
    exit 4
fi

if [[ "$2" != "" &&  "$3" != "" ]]; then
    echo "Solo se puede mostrar la salida por archivo o por pantalla"
    exit 5
fi

#validacionDeRutaDeSalida=`ls "$archivo"`
#Falta hacer una validacion de si el pathing de salida que ingresa el usuario existe, sea relativo, absoluto o tenga espacios

}

##---------------------------------------"GETOPT"---------------------------------------

options=$(getopt -o d:a:hp --l help,pantalla,directorio:,archivo: -- "$@" 2> /dev/null)
if [ "$?" != "0" ] 
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

            echo "El parámetro -d o --directorio tiene el valor $directorio"
            ;;
        -a | --archivo)
            archivo="$2"
            shift 2
            
            echo "El parámetro -a o --archivo tiene el valor $archivo"
            ;;
        -p | --pantalla)
            pantalla="true"
            shift 
            
            echo "Se selecciono el parámetro -p o --pantalla"
            ;;            
        -h | --help)
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *) 
            echo "error"
            exit 1
            ;;
    esac
done

#Realizamos todas las validaciones de los datos
validaciones $directorio $archivo $pantalla

##---------------------------------------RESOLUCION---------------------------------------



echo "Salida exitosa, yendo al awk"

#aca iria una funcion que me diga si va el pathing a un archivo o se muestra por pantalla

awk -F, -v ruta="$archivo" -f script.awk "$directorio"



validarJSON $archivo



exit 0

