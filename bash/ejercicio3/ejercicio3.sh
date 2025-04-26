#!/bin/bash

#./ejercicio3.sh -d ~/repos/virtu/APL/bash --archivos txt,csv,sh --palabras if,for,else
function ayuda() {
    echo "Esta es la ayuda del script del ejercicio 3 de la APL 1."
    echo "Ingresa un directorio base, las extensiones de archivos (csv, txt por ejemplo) sin puntos ni espacios y separadas por comas y por último las palabras que estés buscando, tambien entre comas y sin espacios"
    echo "Ejemplo: Si estás buscando unicamente en /ruta las palabras for y else en las extensiones txt y sh, una correcta llamada seria:"
    echo "./ejercicio3.sh -d /ruta/al/directorio --archivo txt,sh -p for,else"
}

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
    #$1 = directorio
    #$2 = archivos
    #$3 = palabras

    if [[ ! -d "$1" ]];then
        echo "El directorio especificado no existe. Revisa haber escrito bien la ruta"
        exit 1
    fi

    if [[ -z "$2" ]];then
        echo "No se cargaron extensiones para buscar"
        exit 2
    fi

    if [[ -z "$3" ]];then
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

            #echo "El parámetro -d o --directorio tiene el valor $directorio"
            ;;
        -p | --palabras)
            palabra="$2"
            shift 2
            
            #echo "El parámetro -p o --palabras tiene el valor $palabra"
            ;;
        
        -a | --archivos)
            archivos=()
            archivo="$2"
            shift 2
            
            #echo "El parámetro -a o --archivos tiene el valor $archivo"
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

validaciones $directorio $archivo $palabra

#IFS: Internal field separator, en este caso separa por comas. -r le dice que no interprete los \ como caracteres de escape. -a le dice que el contenido va 
# a ser guardado en un array llamado archivos. <<< "$archivo" le indica de donde viene el input de datos
IFS=',' read -r -a archivos <<< "$archivo"
num=0
while [[ num -lt ${#archivos[@]} ]]
do
    archivos[num]="*.${archivos[num]}"
    (( num += 1 ))
done

#echo "Archivo:  ${archivos[@]}"

num=0
aux=()
while [[ num -lt ${#archivos[@]} ]]
do
     # Mapfile guarda en el array "encontrados" el resultado del comando find indicado. El -t hace que no ponga los saltos de linea sino que los separe con un espacio
    mapfile -t encontrados < <(find "$directorio" -name "${archivos[num]}")
    #va con <() en vez de `` porque con el primero la salida de mapfile va a ser tomada como un archivo con multiples lineas y a partir de ahi lo puede procesar.
    #hacerlo con `` hace que sea una cadena, con lo que mapfile no puede trabajar

    # echo "${encontrados[@]}"
    #aux+=`find $directorio -name "${archivos[num]}"` #Esta fue la forma original que lo pensé
    
    aux+=("${encontrados[@]}")

    (( num += 1 ))
done

#aux=`grep -r -l .txt ~/repos/virtu/APL/bash` 
#aux=`find $directorio -name "*.txt"`
#echo "aux final: ${aux[@]}"

awk -F' ' -v pals="$palabra" -f script.awk "${aux[@]}"