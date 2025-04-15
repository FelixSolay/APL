#!/bin/bash

#./ejercicio4.sh -d ./descargas -s ./backup -c 4 -k
function ayuda() {
    echo "Esta es la ayuda del script del ejercicio 4 de la APL 1."
}

function validaciones(){
    #$1 = directorio
    #$2 = salida
    #$3 = cantidad
    #$4 = kill

    if [[ ! -d $1 ]];then
        echo "El directorio especificado no existe. Revisa haber escrito bien la ruta"
        #exit 1
    fi

    if [[ ! -d $2 ]];then
        echo "El directorio de salida especificado no existe. Revisa haber escrito bien la ruta"
       # exit 1
    fi

    if [[ ! $3 =~ ^[0-9]+$ ]];then
        echo "El parametro cantidad solo puede ser un numero entero positivo"
       # exit 2
    fi

    if [[ $4 == "" ]];then
        echo "El parametro kill debe ir acompañado del parametro directorio"
        #exit 3
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

validaciones $directorio $salida $cantidad $kill

#validarKill $kill

#El disown hace que el proceso se siga ejecutando en segundo plano y me libera la terminal
ordenarArchivosPorExtension & disown




