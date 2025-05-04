#!/bin/bash
########################################
#INTEGRANTES DEL GRUPO
# MARTINS LOURO, LUCIANO AGUSTÍN
# PASSARELLI, AGUSTIN EZEQUIEL
# WEIDMANN, GERMAN ARIEL
# DE SOLAY, FELIX                       
########################################



function ayuda() {
    cat << EOF
───────────────────────────────────────────────
 Ayuda - Script del ejercicio 3 de la APL 1
───────────────────────────────────────────────

 Objetivo:
  identificar la cantidad de ocurrencias de determinadas palabras en determinados
archivos dentro de un directorio (incluyendo los subdirectorios).

Ingresar un directorio base, las extensiones de archivos (csv, txt por ejemplo) sin 
puntos ni espacios y separadas por comas y por último las palabras que estés buscando, 
tambien entre comas y sin espacios

 Parámetros:
  -h, --help           Muestra esta ayuda
  -d, --directorio     Ruta del directorio a analizar
  -p, --palabras       Lista de palabras a contabilizar
  -a, --archivos       Lista de extensiones de archivos a buscar

Ejemplo de uso: buscando unicamente en /ruta las palabras for y else en las extensiones txt y sh
  ./ejercicio3.sh -d /ruta/al/directorio --archivo txt,sh -p for,else

EOF
}

function validaciones(){
    local directorio="$1"
    local archivos="$2"
    local palabras="$3"
    
    if [[ ! -d "$directorio" ]];then
        echo "El directorio "$directorio" no existe. Revisa haber escrito bien la ruta"
        exit 1
    fi

    if [[ -z "$archivos" ]];then
        echo "No se cargaron extensiones para buscar"
        exit 2
    fi

    if [[ -z "$palabras" ]];then
        echo "No se cargaron palabras para buscar"
        exit 3
    fi
}
##---------------------------------------"GETOPT"---------------------------------------

options=$(getopt -o d:p:a:h --long help,directorio:,palabras:,archivos: -- "$@" 2> /dev/null)
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
        -p | --palabras)
            palabra="$2"
            shift 2
            ;;
        
        -a | --archivos)
            archivos=()
            archivo="$2"
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

validaciones "$directorio" "$archivo" "$palabra"


#IFS: Internal field separator, en este caso separa por comas. -r le dice que no interprete los \ como caracteres de escape. -a le dice que el contenido va 
# a ser guardado en un array llamado archivos. <<< "$archivo" le indica de donde viene el input de datos
IFS=',' read -r -a archivos <<< "$archivo"
num=0
existe=0
while [[ num -lt ${#archivos[@]} ]]
do
    archivos[num]="*.${archivos[num]}"
    #Hago una verificacion de que al menos existe una extension en el directorio. Find de por si busca de manera recursiva
     if [[ "$existe" -eq 0 ]];then
        encuentraExtension=$(find "$directorio" -name "${archivos[num]}" -type f)
        if [[ "$encuentraExtension" ]];then
            (( existe += 1 ))
        fi
    fi

    (( num += 1 ))
done

if [[ $existe -eq 0 ]];then
    echo "No existe ningún archivo con la/s extension/es seleccionada/s en el directorio provisto"
    exit 5
fi

num=0
aux=()
while [[ num -lt ${#archivos[@]} ]]
do
     # Mapfile guarda en el array "encontrados" el resultado del comando find indicado. El -t hace que no ponga los saltos de linea sino que los separe con un espacio
    mapfile -t encontrados < <(find "$directorio" -name "${archivos[num]}")

    aux+=("${encontrados[@]}")

    (( num += 1 ))
done

awk -F' ' -v pals="$palabra" -f script.awk "${aux[@]}"