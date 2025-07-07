#!/bin/bash


########################################
#INTEGRANTES DEL GRUPO
# MARTINS LOURO, LUCIANO AGUSTÍN
# PASSARELLI, AGUSTIN EZEQUIEL
# WEIDMANN, GERMAN ARIEL
# DE SOLAY, FELIX                       
########################################
##---------------------------------------FUNCIONES---------------------------------------
function ayuda() {
    cat << EOF
───────────────────────────────────────────────
 Ayuda - Script del ejercicio 1 de la APL 1
───────────────────────────────────────────────

 Objetivo:
  Lee un Directorio con archivos CSV que contienen registros de 
  temperaturas en distintas ubicaciones. Procesa la información 
  y genera una salida en formato JSON con:
    • Promedios
    • Máximos
    • Mínimos
  agrupados por fecha y ubicación.

 Parámetros:
  -h, --help           Muestra esta ayuda
  -d, --directorio     Ruta del directorio con los archivos CSV de entrada
  -a, --archivo        Ruta del archivo JSON de salida
  -p, --pantalla       Muestra el resultado por pantalla

 Aclaraciones:
  No se pueden usar simultáneamente -a|--archivo y -p|--pantalla.
  Se debe elegir uno u otro.

Ejemplo de uso:
  ./ejercicio1.sh -d ./entradas_csv -a ./salida.json

EOF
}

#Valida el JSON sin imprimirlo en pantalla
function validarJSON()
{
    if jq empty $1 > /dev/null 2>&1; then
        echo "El JSON es válido." 
    else
        echo "El Formato del JSON no ha podido ser validado por el jq."
        exit 1
    fi
}

function validaciones()
{
    local directorio="$1"
    local archivo="$2"
    local pantalla="$3"

    if [[ -z "$archivo" &&  "$pantalla" != "true" ]]; then
        echo "No se cargó un archivo de salida ni se pidió mostrar por pantalla"
        exit 1
    fi

    if [[ ! -d "$directorio" ]]; then
        echo "El directorio especificado no existe"
        exit 2
    fi

    csv_count=$(find "$directorio" -maxdepth 1 -name "*.csv" -type f | wc -l)
    if [[ $csv_count -eq 0 ]]; then
        echo "No se encontraron archivos .csv en el directorio"
        exit 3
    fi

    if [[ -n "$archivo" && "$pantalla" == "true" ]]; then
        echo "Solo se puede mostrar la salida por archivo o por pantalla, no ambos"
        exit 5
    fi

    if [[ -n "$archivo" ]]; then
        directorioPadre=$(dirname "$archivo")

        if [[ ! -d "$directorioPadre" ]]; then
            echo "Error: El directorio '$directorioPadre' no existe." 
            exit 6
        fi

        if [[ ! -e "$directorioPadre" || ! -d "$directorioPadre" ]]; then
            echo "Error: La ruta '$directorioPadre' no es un directorio."
            exit 7
        fi

        if [[ ! "$archivo" =~ \.json$ ]]; then
            echo "Error: El archivo '$archivo' debe tener extensión .json."
            exit 8
        fi
    fi
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
            ;;
        -a | --archivo)
            archivo="$2"
            shift 2
            ;;
        -p | --pantalla)
            pantalla="true"
            shift 
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


validaciones "$directorio" "$archivo" "$pantalla"

##---------------------------------------RESOLUCION---------------------------------------

echo "Procesando AWK..."

#validar el JSON si se eligió archivo y no pantalla
if [[ "$pantalla" == "true" ]]; then
    for csv in "$directorio"/*.csv; do
        [[ -s "$csv" ]] && awk -F, -v ruta="/dev/stdout" -f script.awk "$csv"
    done
else
    tmp="$(mktemp)"
    for csv in "$directorio"/*.csv; do
        [[ -s "$csv" ]] && awk -F, -v ruta="$tmp" -f script.awk "$csv"
    done
    # Consolidar el archivo temporal en el archivo final y validar JSON
    mv "$tmp" "$archivo"
    validarJSON "$archivo"
fi



exit 0

