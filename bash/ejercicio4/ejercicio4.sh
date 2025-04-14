#!/bin/bash

#./ejercicio4.sh -d ./descargas -s ./backup -c 4 -k
function ayuda() {
    echo "Esta es la ayuda del script del ejercicio 4 de la APL 1."
}

function validaciones(){
    #$1 = directorio
    #$2 = salida
    #$3 = cantidad
    #$4 = kill

    if [[ ! -d $1 ]];then
        echo "El directorio especificado no existe. Revisa haber escrito bien la ruta"
        #exit 1
    fi

    if [[ ! -d $2 ]];then
        echo "El directorio de salida especificado no existe. Revisa haber escrito bien la ruta"
       # exit 1
    fi

    if [[ ! $3 =~ ^[0-9]+$ ]];then
        echo "El parametro cantidad solo puede ser un numero entero positivo"
       # exit 2
    fi

    if [[ $4 == "" ]];then
        echo "El parametro kill debe ir acompañado del parametro directorio"
        #exit 3
    fi
}

options=$(getopt -o d:s:khc: --long help,directorio:,salida:,cantidad:,kill -- "$@" 2> /dev/null)
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
        -s | --salida)
            salida="$2"
            shift 2
            
            echo "El parámetro -s o --salida tiene el valor $salida"
            ;;
        
        -c | --cantidad)
            cantidad="$2"
            shift 2
            
            echo "El parámetro -c o --archivos tiene el valor $cantidad"
            ;;         
        -h | --help)
            ayuda
            exit 0
            ;;
        -k | --kill)
            kill="true"
            echo "El parametro kill fue seleccionado"
            shift
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

validaciones $directorio $salida $cantidad $kill

# archivo=`ls $directorio`
# echo $archivo

IFS='.' read -r -a archivos <<< "$archivo"



echo "pruebas en 0 "${archivos[0]}
echo "pruebas en 1 "${archivos[1]}
num=0
while [[ num -lt ${#archivos[@]} ]]
do
    numAux=$(( num + 1 ))
    prueba=$(find $directorio -name "${archivos[numAux]}" -type d)
     echo $prueba
    if [[ "$prueba" == "" ]];then
        `mkdir -p "$directorio"\/"${archivos[numAux]}"`
    fi
    `mv "$directorio"\/"${archivos[num]}"."${archivos[numAux]}" -t "$directorio"\/"${archivos[numAux]}"`
    echo "mv "$directorio"\/"${archivos[num]}"."${archivos[numAux]}" -t "$directorio"\/"${archivos[numAux]}""
    echo $prueba
    (( num += 2 ))
done