#!/bin/bash

##---------------------------------------FUNCIONES---------------------------------------
function ayuda() {
    cat << EOF
───────────────────────────────────────────────
 Ayuda - Script del ejercicio 5 de la APL 1
───────────────────────────────────────────────

 Objetivo:
  El script debe permitir consultar informacion relacionada a los nutrientes de las frutas a travez
  de la api Fruityvice. Se permitira buscar informacion a traves de los ids o nombres o ambos a la
  vez.
 
 Parámetros:
  -i, --id           Id/s de las frutas a buscar
  -n, --name         Nombre/s de als frutas a buscar

 Aclaraciones:
  Una vez obtenida la informacion, se generará esta a modo de cache para no volver a consultarse en la api. Se mostrara la informacion con el siguiente formato:
  id: 2,
  name: Orange,
  genus: Citrus,
  calories: 43,
  fat: 0.2,
  sugar: 8.2,
  carbohydrates: 8.3,
  protein: 1

Ejemplo de uso:
  ./ejercicio5.sh --id "11,22" --name "banana,orange"

EOF
}

function validaciones(){

    local id="$1"
    local name="$2"

    if [[ -z "$id" && -z "$name" ]]; then
        echo "No se cargo ninguna id ni ningun nombre"
        exit 1
    fi
}

##---------------------------------------"GETOPT"---------------------------------------
options=$(getopt -o i:n:h --long id:,name:,help -- "$@" 2> /dev/null)
if [ "$?" != "0" ] 
then
    echo 'Opciones incorrectas'
    exit 1
fi
eval set -- "$options"
while true
do
    case "$1" in
        -i | --id) 
            ids="$2"
            shift 2
            ;;
        -n | --name)
            names="$2"
            shift 2
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

validaciones "$ids" "$names"

IFS=',' read -ra id <<< "$ids"
IFS=',' read -ra name <<< "$names"

for i in "${id[@]}"; do
    echo $i
done

for i in "${name[@]}"; do
    echo $i
done