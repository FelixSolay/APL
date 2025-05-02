#!/bin/bash

#./ejercicio4.sh -d ./descargas -s ./backup -c 4 -k
#librerias necesarias: zip, inotify-tools 
#sudo apt-get install inotify-tools

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
  -c, --cantidad       cantidad de archivos a ordenar antes de generar un backup

 Aclaraciones:
  El parámetro -k o --kill se debe utilizar únicamente junto con -d o --directorio


Ejemplos de uso:
  $ ./demonio.sh -d ../descargas --salida ../backup -c 3
  $ ./demonio.sh -d ../documentos --salida ../backup --cantidad 3

Aclaraciones:
  Debido al uso de inotify-tools, si estás usando un WSL solamente va a poder detectar los cambios que hagas fuera de linux si estas en el directorio home.
  Si haces por ejemplo touch /tu/ruta/archivo.txt lo va a ordenar efectivamente, pero si la creas desde Visual Studio Code no la va a detectar a menos que estés en el directorio home.

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
function validarKill(){
    local directorio="$1"
    local kill="$2"
    #Validar si otro proceso esta corriendo en el mismo directorio
    if [[ $kill = "false" ]];then
    for pid in $(ps -eo pid --no-headers); do #obtiene un iterable de todos los pid solo con el numero, sin headers
        dir=$(readlink -f /proc/$pid/cwd) #/proc/$pid/cwd devuelve una referencia al proceso. Con readlink podemos obtener su ruta absoluta para asi compararla
        if [[ "$dir" == "$directorio" && $pid -ne $$ ]]; then
            echo "El proceso daemon ya está siendo ejecutado en el directorio actual."
            exit 7
        fi
    done
    fi

}

function ordenarArchivosPorExtension() {
    #Primero tiene que hacer un barrido inicial y despues se queda escuchando
    cd "$directorio" || { echo "No se pudo cambiar de directorio"; exit 1; }

    cantidadArchivosOrdenados=0

    mapfile -t archivos < <(find "$directorio" -maxdepth 1 -type f) #el maxdepth es para que no siga buscando adentro de las carpetas el find
        #echo "el mapfile: ${archivos[@]} "
        #echo "el mapfile tiene ${#archivos[@]} archivos "
        num=0
        while [[ num -lt ${#archivos[@]} ]]
        do
            
            IFS='.' read -r -a archivoActual <<< "${archivos[num]}" #El array archivoActual tiene en su posicion 0 el pathing y en el 1 la extension
            (( num += 1 ))
            #echo "en la posicion 1: ${archivoActual[0]}"
            #echo "en la posicion 2: ${archivoActual[1]}"
            #prueba=$(find "$directorio" -name "${archivoActual[1]}" -type d)
            #echo "pesos prueba: $prueba"
            `mkdir -p "$directorio"\/"${archivoActual[1]}"` #con el -p, mkdir no tira un error si el directorio ya existe por lo que no necesito validar

            `mv "${archivoActual[0]}"."${archivoActual[1]}" -t "$directorio"\/"${archivoActual[1]}"` #mueve el archivo actual al directorio indicado con -t, sin el -t solo cambia el nombre
             (( cantidadArchivosOrdenados += 1 ))
             if [[ $cantidadArchivosOrdenados -eq "$cantidad" ]];then
                nombre_dir=$(basename "$(pwd)")
                fecha=$(date +"%Y%m%d_%H%M%S")
                zip -r "$salida/${nombre_dir}_${fecha}.zip" . > /dev/null
                cantidadArchivosOrdenados=0;
            fi
        done

    inotifywait -m -e create -e moved_to -e close_write -e modify -e attrib --format "%w%f" "$directorio" | while read archivo
    do
        sleep 0.5 #Sin este sleep apenas pones el archivo lo mueve y vscode puede tirar un error. No es realmente necesario
        if [[ -f "$archivo" ]]; then
            nombreArchivo=$(basename "$archivo")
            extension="${nombreArchivo##*.}"
            
            if [[ "$nombreArchivo" == "$extension" ]]; then
                extension="sin_extension"
            fi

            mkdir -p "$directorio/$extension"
            mv "$archivo" -t "$directorio/$extension/"
            (( cantidadArchivosOrdenados++ ))

            # Backup si se alcanzó el límite
            if [[ $cantidadArchivosOrdenados -eq "$cantidad" ]]; then
                nombre_dir=$(basename "$(pwd)")
                fecha=$(date +"%Y%m%d_%H%M%S")
                zip -r "$salida/${nombre_dir}_${fecha}.zip" . > /dev/null
                cantidadArchivosOrdenados=0
            fi
        fi
    done
}

 function matarProcesos(){
    local kill="$1"
    if [[ $kill = "true" ]];then
    for pid in $(ps -eo pid --no-headers); do #obtiene un iterable de todos los pid solo con el numero, sin headers
        dir=$(readlink -f /proc/$pid/cwd) #/proc/$pid/cwd devuelve una referencia al proceso. Con readlink podemos obtener su ruta absoluta para asi compararla
        if [[ "$dir" == "$directorio" ]]; then
            if [[ "$pid" -ne "$$" ]]; then #Verifico que mate a todos los procesos menos al proceso actual
                echo "Matando proceso $pid en $dir"
                kill $pid
            fi
        fi
    done
    exit 0 #Exit mata al proceso actual y con el 0 decimos que fue exitoso. Si lo terminamos con un kill diria "terminated" y podria dar a entender que finalizó mal cuando no es asi.
    fi
 }

options=$(getopt -o d:s:khc: --long help,directorio:,salida:,cantidad:,kill -- "$@" 2> /dev/null)
if [ "$?" != "0" ] 
then
    echo 'Opciones incorrectas'
    exit 1
fi
eval set -- "$options"
kill="false"
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
            
            echo "El parámetro -c o --cantidad tiene el valor $cantidad"
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

#Para este punto sabemos que las rutas son validas y necesitamos manejar si o si direcciones absolutas, asi que las convertimos
directorio=$(realpath "$directorio");
salida=$(realpath "$salida");

validarKill "$directorio" "$kill"

matarProcesos "$kill"

#pruebanotify & disown

#El disown hace que el proceso se siga ejecutando en segundo plano y me libera la terminal
ordenarArchivosPorExtension & disown



# readlink -f /proc/pid/cwd 
 #en pid pones el pid del proceso
#./ejercicio4.sh -d ./descargas -s ./backup -c 4 -k
#./ejercicio4.sh -d ./descargas2 -s ./backup -c 4 -k