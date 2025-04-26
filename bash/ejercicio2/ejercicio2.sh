#!/bin/bash

function ayuda() {
    cat << EOF
───────────────────────────────────────────────
 Ayuda - Script del ejercicio 2 de la APL 1
───────────────────────────────────────────────

 Objetivo:
  El Script debe permitir realizar producto escalar y trasposición de matrices.
  La entrada se realiza mediante un archivo de texto plano, la salida es en un
  archivo que se llamará "salida.nombreArchivoEntrada", en el mismo directorio
  donde esté el archivo de entrada.
  
  Ejemplo formato de archivo de matrices:
        0|1|2
        1|1|1
        -3|-3|-1

 Parámetros:
  -h, --help           Muestra esta ayuda.
  -m, --matriz         Ruta del archivo que contiene la matriz de entrada.
  -p, --producto       Valor entero para utilizar en el producto escalar.
  -t, --trasponer      Indica que debe realizar la transposición sobre la matriz.
  -s, --separador      Caracter que se utilizará como separador de columnas.

 Aclaraciones:
  No se pueden usar simultáneamente -t|--trasponer y -p|--producto.
  Se debe elegir uno u otro.

Ejemplos de uso:
  ./ejercicio2.sh -m ./matriz.txt -t --separador "|"
  ./ejercicio2.sh -m ./matriz.txt -p 3 -s "|"
  ./ejercicio2.sh -m ./matriz.txt --trasponer -s "|"

EOF
}


function validaciones(){

    local matriz="$1"
    local producto="$2"
    local trasponer="$3"
    local separador="$4"

    if [[ -z "$producto" && -z "$trasponer" ]]; then
        echo "No se cargó un producto escalar ni se indicó la trasposición"
        exit 1
    fi

    if [[ ! -s "$matriz" ]]; then
        echo "El directorio de la matriz no existe o tiene un tamaño de 0 bytes"
        exit 2
    fi

    if [[ ! "$matriz" =~ \.txt$ ]]; then
        echo "El archivo no tiene extensión .txt"
        exit 3
    fi

    if [[ $(basename "$matriz" | grep -o "\." | wc -l) -gt 1 ]]; then
        echo "El archivo tiene una doble extensión"
        exit 4
    fi

    if [[ -n "$producto"  &&  "$pantalla" == "true" ]]; then
        echo "Solo se puede trasponer la matriz o realizar producto por un escalar"
        exit 5
    fi

    if [[ "$separador" == "" || $separador =~ ^([0-9]|-)$ ]];then
        echo "El caracter separador no puede estar vacio, ser un numero o el signo -"
        exit 6
    fi

    if [[ ${#separador} -gt 1 ]];then #funciona como un strlen de $4
        echo "El caracter separador solo puede ser un único caracter"
        exit 7
    fi

    aux=$(grep "$separador" "$matriz")
    if [[ $aux == "" ]]; then
        echo "El separador $separador no aparece en el archivo provisto en el parámetro -m o --matriz"
        exit 8
    fi

    if [[ -n "$producto" && ! "$producto" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
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
while true
do
    case "$1" in
        -m | --matriz) 
            
            matriz="$2"
            shift 2

            #echo "El parámetro -m o --matriz tiene el valor $matriz"
            ;;
        -p | --producto)
            productoEscalar="$2"
            shift 2
            
            #echo "El parámetro -p o --producto tiene el valor $productoEscalar"
            ;;
        
        -t | --trasponer)
            trasponer="true"
            shift 
            
            #echo "Se selecciono el parámetro -t o --trasponer"
            ;;   
        -s | --separador)
            separador="$2"
            shift 2
            
            #echo "El parámetro -s o --separador tiene el valor $separador"
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
nombre_archivo=$(basename "$matriz")
directorio_matriz=$(dirname "$matriz")

#poner la salida donde esta la entrada
ruta="$directorio_matriz/salida.$nombre_archivo"

resultado= awk -F"$separador" -v separador="$separador" -v opcion="$opcion" -v ruta="$ruta" -f script.awk "$matriz"
exit $resultado #exitea el resultado porque si falla el awk por los parametros tiene que fallar la ejecucion
 