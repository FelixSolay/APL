#!/bin/bash

########################################
#INTEGRANTES DEL GRUPO
# MARTINS LOURO, LUCIANO AGUSTÍN
# PASSARELLI, AGUSTIN EZEQUIEL
# WEIDMANN, GERMAN ARIEL
# DE SOLAY, FELIX                       
########################################

#librerias necesarias jq
#sudo apt-get install jq

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
  -n, --name         Nombre/s de las frutas a buscar

 Aclaraciones:
  Una vez obtenida la informacion, se generará esta a modo de cache para no volver a consultarse en la api.
  Se mostrara la informacion con el siguiente formato:
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
#funciones
function validacionesParam(){

    local id=$1
    local name=$2

    if [[ -z "$id" && -z "$name" ]]; then
        echo "No se cargo ninguna id ni ningun nombre"
        exit 1
    fi

}

function validacionesId(){
    for i in "${@}"; do
        if [[ ! $i =~ ^[0-9]+$ ]]; then
            echo "id debe ser un numero entero positivo"
            exit 2
        fi
    done
}

#Opciones
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

#Se valida que haya parametros
validacionesParam $ids $names 

IFS=',' read -ra id <<< "$ids"
IFS=',' read -ra name <<< "$names"

#Se valida que si hay id, estos sean numeros
validacionesId ${id[@]}

declare -A cacheJSON
declare -A cacheERROR
apiFrutas="https://www.fruityvice.com/api/fruit/"
cacheFile="./cacheFile.txt"

#Se inicia o carga el cache. Si $cacheFile ya existe, touch no hace nada
    touch $cacheFile


if [ -s $cacheFile ]; then #Si el cacheFile no esta vacio cargo el array cacheJSON
    while read linea; do
        cacheJSON["$(echo $linea | jq .id)"]=$linea
    done < $cacheFile
fi

#Se eliminan los repetidos
idUnicos=()
nameUnicos=()
for elem in "${id[@]}"; do
    if [[ ! " ${idUnicos[@]} " =~ " $elem " ]]; then
        idUnicos+=("$elem")
    fi
done
for elem in "${name[@]}"; do
    if [[ ! " ${nameUnicos[@]} " =~ " $elem " ]]; then
        nameUnicos+=("$elem")
    fi
done

#me fijo por el parametro Id
for i in "${idUnicos[@]}"; do
    if [ -z ${cacheJSON["$i"]} ]; then
        json=$(curl -s $apiFrutas$i)
        if [ $? -eq 6 ]; then
            cacheERROR["$i"]="Id $i: ERROR 6, No se pudo conectar a la API. Pruebe su conexion a internet"
            continue
        fi
        if [[ "$(echo $json | jq -r '.error')" == "Not found" ]]; then
            cacheERROR["$i"]="Id $i: Id no encontrada o valida"
            continue
        fi
        cacheJSON["$i"]=$json
    fi
    echo ${cacheJSON["$i"]} | jq -j '{id: .id, name: .name, genus: .genus, calories: .nutritions.calories, fat: .nutritions.fat, sugar: .nutritions.sugar, carbohydrates: .nutritions.carbohydrates, protein: .nutritions.protein}'

    for((t = 0; t < ${#nameUnicos[@]} ; t++)); do
        if [[ "$(echo ${cacheJSON["$i"]} | jq -r '.name')" == "${nameUnicos[$t]}" ]];then
            nameUnicos[$t]=0
        fi
    done
done

#Me fijo por el parameto name
for i in "${nameUnicos[@]}"; do
    if [ "$i" == "0" ]; then
        continue
    fi
    for idKey in "${!cacheJSON[@]}"; do
        if [ "$i" == $(echo ${cacheJSON[${idKey}]} | jq -r '.name') ]; then
            key="$idKey"
            break
        fi
    done
    if [ -z $key ]; then
        json=$(curl -s $apiFrutas$i)
        if [ $? -eq 6 ]; then
            cacheERROR["$i"]="Fruta $i: ERROR 6, No se pudo conectar a la API. Pruebe su conexion a internet"
            continue
        fi
        if [[ "$(echo $json | jq -r '.error')" == "Not found" ]]; then
            cacheERROR["$i"]="Fruta $i: Fruta no encontrada o valida"
            continue
        fi
        key="$(echo $json | jq -r '.id')"
        cacheJSON["$key"]=$json
    fi
    echo ${cacheJSON["$key"]} | jq -j '{id: .id, name: .name, genus: .genus, calories: .nutritions.calories, fat: .nutritions.fat, sugar: .nutritions.sugar, carbohydrates: .nutritions.carbohydrates, protein: .nutritions.protein}'
    key=""
done

#Escribo mis errores a pantalla
for llave in "${!cacheERROR[@]}"; do
    echo ${cacheERROR["$llave"]}
done


#Reescribo el cacheFile con mi cacheJSON actualizado

> "$cacheFile"  # Funciona como hacer rm y touch pero evita operaciones sobre el filesystem, lo que la hace mas eficiente

for llave in "${!cacheJSON[@]}"; do
    echo "${cacheJSON["$llave"]}" >> $cacheFile
done





