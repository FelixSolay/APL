#!/bin/bash

##---------------------------------------FUNCIONES---------------------------------------
function ayuda() {
    cat << EOF
───────────────────────────────────────────────
 Ayuda - Script del ejercicio 1 de la APL 1
───────────────────────────────────────────────

 Objetivo:
  Lee un archivo CSV con registros de temperaturas en distintas ubicaciones.
  Procesa la información y genera una salida en formato JSON con:
    • Promedios
    • Máximos
    • Mínimos
  agrupados por fecha y ubicación.

 Parámetros:
  -h, --help           Muestra esta ayuda
  -d, --directorio     Ruta del directorio con el archivo CSV de entrada
  -a, --archivo        Ruta del archivo JSON de salida
  -p, --pantalla       Muestra el resultado por pantalla

 Aclaraciones:
  No se pueden usar simultáneamente -a|--archivo y -p|--pantalla.
  Se debe elegir uno u otro.

Ejemplo de uso:
  ./ejercicio1.sh -d ./pruebas_normales.csv -a ./salida.json

EOF
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
    local directorio="$1"
    local archivo="$2"
    local pantalla="$3"

    if [[ -z "$archivo" && -z "$pantalla" ]]; then
        echo "No se cargó un archivo de salida ni se pidió mostrar por pantalla"
        exit 1
    fi

    if [[ ! -s "$directorio" ]]; then
        echo "El archivo no existe o está vacío"
        exit 2
    fi

    if [[ "${directorio##*.}" != "csv" ]]; then
        echo "El archivo no es del tipo CSV (Valores separados por comas)"
        exit 3
    fi

    if [[ $(basename "$directorio" | grep -o "\." | wc -l) -gt 1 ]]; then
        echo "El archivo tiene una doble extensión"
        exit 4
    fi

    if [[ -n "$archivo" && "$pantalla" == "true" ]]; then
        echo "Solo se puede mostrar la salida por archivo o por pantalla, no ambos"
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
#validar el JSON si se eligió archivo y no pantalla
if [[ "$pantalla" == "true" ]]; then
    awk -F, -v ruta="/dev/stdout" -f script.awk "$directorio"
else
    awk -F, -v ruta="$archivo" -f script.awk "$directorio"
    validarJSON "$archivo"
fi



exit 0

