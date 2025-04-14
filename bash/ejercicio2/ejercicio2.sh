#!/bin/bash

function ayuda() {
    echo "Esta es la ayuda del script del ejercicio 2 de la APL 1."
}
function validaciones(){
    #$1 = matriz
    #$2 = productoEscalar
    #$3 = trasponer
    #$4 = separador
    if [[ "$2" = "" &&  "$3" = "" ]]; then
        echo "No se cargó un producto escalar ni se indicó la trasposición"
        exit 1
    fi
    if [[ ! -s "$1" ]]; then
        echo "El directorio de la matriz no existe o tiene un tamaño de 0 bytes"
        exit 2
    fi
    if [[ ! "$1" == *.txt ]]; 
    then
        echo "El directorio de la matriz no es del tipo texto"
        exit 3
    fi

    if [[ "$1" == *.*.* ]]; 
    then
        echo "El directorio de la matriz contiene doble extension"
        exit 4
    fi

    if [[ "$2" != "" &&  "$3" != "" ]]; then
        echo "Solo se puede trasponer la matriz o realizar producto por un escalar"
        exit 5
    fi

    if [[ "$4" == "" || $4 =~ ^([0-9]|-)$ ]];then
        echo "El caracter separador no puede estar vacio, ser un numero o el signo -"
        exit 6
    fi
    if [[ ${#4} -gt 1 ]];then #funciona como un strlen de $4
        echo "El caracter separador solo puede ser un único caracter"
        exit 7
    fi
    aux=`grep "$4" matriz.txt`
    if [[ $aux == "" ]];then
        echo "El separador $4 no aparece en el archivo provisto en el parámetro -m o --matriz"
        exit 8
    fi

    if [[ ! "$2" =~  ^([-]?[0-9]+|[-]?[0-9]+\.[0-9]+)$ ]];then
        echo "El valor para el producto escalar solamente puede ser numerico."
        exit 9
    fi

}
##---------------------------------------"GETOPT"---------------------------------------

options=$(getopt -o m:p:ts:h --long help,matriz:,producto:,trasponer,separador: -- "$@" 2> /dev/null)
if [ "$?" != "0" ] 
then
    echo 'Opciones incorrectas'
    exit 1
fi
eval set -- "$options"
echo ""$2""
while true
do
    case "$1" in
        -m | --matriz) 
            
            matriz="$2"
            shift 2

            echo "El parámetro -m o --matriz tiene el valor $matriz"
            ;;
        -p | --producto)
            productoEscalar="$2"
            shift 2
            
            echo "El parámetro -p o --producto tiene el valor $productoEscalar"
            ;;
        
        -t | --trasponer)
            trasponer="true"
            shift 
            
            echo "Se selecciono el parámetro -t o --trasponer"
            ;;   
        -s | --separador)
            separador="$2"
            shift 2
            
            echo "El parámetro -s o --separador tiene el valor $separador"
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

validaciones "$matriz" "$productoEscalar" "$trasponer" "$separador"

#validarPathing
#Falta validar el pathing, podria ir simplemente en las validaciones pero lo dejo como cosa aparte para validarlo
if [[ $productoEscalar == "" ]];
then
    opcion="trasponer"
else 
    opcion=$productoEscalar;
fi

#obtenerRutaSalida
#Dejo esta funcion como pendiente, es para obtener la ruta de salida donde se va a mostrar la matriz

ruta="salida.matriz.txt"

resultado= awk -F"$separador" -v opcion="$opcion" -v ruta="$ruta" -f script.awk "$matriz"
exit $resultado #exitea el resultado porque si falla el awk por los parametros tiene que fallar la ejecucion
 