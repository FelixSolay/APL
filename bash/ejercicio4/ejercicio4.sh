#!/bin/bash

#./ejercicio4.sh -d ./descargas -s ./backup -c 4 -k
function ayuda() {
    cat << EOF
───────────────────────────────────────────────
 Ayuda - Script del ejercicio 4 de la APL 1
───────────────────────────────────────────────

 Objetivo:
    Demonio que detecta cada vez que un archivo nuevo aparece en un directorio
    “descargas”. Una vez detectado, se mueve a un subdirectorio “extensión” cuyo nombre será la
    extensión del archivo y que estará localizado en un directorio “destino”
    Además cada cierta cantidad de archivos realizará un backup con el nobre del directorio respaldado
    junto con la fecha y hora (yyyyMMdd-HHmmss), 
    Ejemplo: descargas_20250401_212121.zip.

 Parámetros:
  -h, --help           Muestra esta ayuda
  -d, --directorio     Ruta del directorio a monitorear
  -s, --salida         Ruta del directorio en donde se van a crear los backups
  -k, --kill           Flag que indica que el script debe detener el demonio iniciado
  -c, --cantidad       antidad de archivos a ordenar antes de generar un backup

 Aclaraciones:
  El parámetro -k o --kill se debe utilizar únicamente junto con -d o --directorio


Ejemplos de uso:
  $ ./demonio.sh -d ../descargas --salida ../backup -c 3
  $ ./demonio.sh -d ../documentos --salida ../backup --cantidad 3

EOF
}

function validaciones(){
    local directorio="$1"
    local salida="$2"
    local cantidad="$3"
    local kill="$4"

    #siempre tiene que haber un directorio en -d ($1), ya sea con kill o no
    if [[ -z "$directorio" ]];then
        echo "ERROR: Debe especificar un directorio con -d o --directorio."
        exit 1
    fi
    
    if [[ ! -d "$directorio" ]];then
        echo "El directorio especificado no existe. Revisa haber escrito bien la ruta"
        exit 2
    fi
    
    # Si es un kill, no validar salida ni cantidad
#    echo "DEBUG: entré en validaciones con el parámetro 4 con valor: $kill" 
    if [[ "$kill" == "true" ]]; then
#        echo "DEBUG: deberia ignorar las otras validaciones porque me tiraste un kill"
        return
    fi    

    #si no salió con kill debe especificar una salida
    if [[ -z "$salida" ]]; then
        echo "ERROR: Debe especificar un directorio de salida con -s o --salida."
        exit 3
    fi
    #Y una cantidad
    if [[ -z "$cantidad" ]]; then
        echo "ERROR: Debe especificar una cantidad de archivos a ordenar antes de generar un backup con -c o --cantidad."
        exit 4
    fi    

    if [[ ! -d "$salida" ]];then
        echo "El directorio de salida especificado no existe. Revisa haber escrito bien la ruta"
        exit 5
    fi

    if [[ ! $cantidad =~ ^[0-9]+$ ]];then
        echo "El parametro cantidad solo puede ser un numero entero positivo"
        exit 6
    fi
}

function ordenarArchivosPorExtension(){
    while true;do
        #archivo=`find "$directorio" -maxdepth 1 -type f ` 
        #No se puede hacer con find porque necesitamos que las rutas con espacios sean un solo elemento del array
        mapfile -t archivos < <(find $directorio -maxdepth 1 -type f) #el maxdepth es para que no siga buscando adentro de las carpetas el find

        num=0
        while [[ num -lt ${#archivos[@]} ]]
        do
            IFS='.' read -r -a archivoActual <<< "${archivos[num]}" #El array archivoActual tiene en su posicion 1 el pathing y en el 2 la extension
            (( num += 1 ))
            prueba=$(find $directorio -name "${archivoActual[2]}" -type d)
            `mkdir -p "$directorio"\/"${archivoActual[2]}"` #con el -p, mkdir no tira un error si la carpeta ya existe por lo que no necesito validar

            `mv ".${archivoActual[1]}"."${archivoActual[2]}" -t "$directorio"\/"${archivoActual[2]}"` #mueve el archivo actual al directorio indicado con -t, sin el -t solo cambia el nombre
        done
        sleep 10
    done
}

function validarKill(){
    # Obtener el PID del proceso del script excluyendo el propio
    validaProceso=$(pgrep -f "ejercicio4.sh" | grep -v $$)
    echo $validaProceso
    if [[ -z $validaProceso ]]; then
        # Si no se encuentra el proceso, inicia el script en segundo plano
        echo "El proceso no estaba iniciado, iniciando..."

    else
        # Si se encuentra el proceso, lo mata
        echo "El proceso ya está siendo ejecutado. Procediendo a matarlo..."
        kill $validaProceso
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

#directorio=${directorio:-""}
#salida=${salida:-""}
#cantidad=${cantidad:-""}
#kill=${kill:-"false"}

validaciones "$directorio" "$salida" "$cantidad" "$kill"

#validarKill $kill

#El disown hace que el proceso se siga ejecutando en segundo plano y me libera la terminal
ordenarArchivosPorExtension & disown




