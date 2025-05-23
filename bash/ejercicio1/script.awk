BEGIN{
    print "Inicializando el procesamiento de datos..."
}

function validarParametros(id, fecha, hora, direccion, temp)
{
    cadena = ""

    if(id !~ /^[0-9]+$/)
        cadena = cadena "Linea " NR ": Error en el ID. El mismo debe ser numerico. \n"
    if(fecha !~ /^[0-9]{4}\/(0[1-9]|1[0-2])\/(0[1-9]|[12][0-9]|3[0-1])$/)
        cadena = cadena "Linea " NR ": Error en la fecha. El formato debe ser yyyy/mm/dd. \n"
    if( hora !~ /([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]/)
        cadena = cadena "Linea " NR ": Error en la hora. El formato debe ser hh:mm:ss. \n"

    if((direccion != "Norte" && direccion != "Sur" && direccion != "Este" && direccion != "Oeste"))
        cadena = cadena "Linea " NR ": Error en la direccion. Sus posibles valores pueden ser \"Norte\", \"Sur\",\"Este\" u \"Oeste\". \n"
    if(temp !~ /[0-9]+\.[0-9]+/)
        cadena = cadena "Linea " NR ": Error en la temperatura. El valor debe contener numeros decimales.\n"

    if(cadena=="")
        cadena="valido"
    return cadena

}

{
    id=$1
    fecha=$2
    hora=$3
    direccion=$4
    temp=$5
    #Primero necesito "declarar" al mensaje como string, no se puede hacer en un solo paso
    mensajeSalida=""
    mensajeSalida = mensajeSalida validarParametros($1,$2,$3,$4,$5)

    if(mensajeSalida=="valido")
    {
        #SUBSEP es el separador de awk, es el mas seguro de usar en vez de hardcodearlo
        #Esto lo tengo que hacer asi porque awk no puede manejar arrays multidimensionales
        clave = fecha SUBSEP direccion

        #Variables para el promedio
        cantApariciones[clave]++
        suma[clave]+=temp


        #Inicializo las temperaturas si no fueron cargadas, sino actualizo la mayor y menor
        if(! (clave in temperaturaMin))
        {
            temperaturaMin[clave]=temp
            temperaturaMax[clave]=temp
        }
        else
        {
            temperaturaMax[clave]=temperaturaMax[clave]<temp?temp:temperaturaMax[clave]
            temperaturaMin[clave]=temperaturaMin[clave]>temp?temp:temperaturaMin[clave]
        }
    }
    else 
    {
        printf("%s", mensajeSalida);
    }
}

END{

    PROCINFO["sorted_in"] = "@ind_str_asc"  #Esta sola funcion reemplaza a todo el ordenamiento que hariamos normalmente
    
    #True es el valor por defecto que le asignamos a la salida por pantalla
    if(ruta=="/dev/stdout")
    {
        for (clave in temperaturaMin)
        {
            split(clave,partes, SUBSEP); 
            dia=partes[1] #Aca guarda el dia
            dir=partes[2] #Aca guarda la hora
            printf("Dia: %s, direccion: %s, minima: %.2f, maxima: %.2f, promedio: %.2f\n", dia,dir, temperaturaMin[clave],temperaturaMax[clave], suma[clave]/cantApariciones[clave] )
        }
    }
    else
    {
        #Mi idea es armar un array de días distintos, luego iterar sobre el mismo en las 4 direcciones posibles (Norte, Sur, Este y Oeste)
        vectorDirecciones["Sur"] = 1 
        vectorDirecciones["Norte"] = 1
        vectorDirecciones["Este"] = 1
        vectorDirecciones["Oeste"] = 1

        #1° iteración: armo un array de días distintos para iterar S N E O
        for (clave in temperaturaMin)
        {
            split(clave,partes, SUBSEP);
            dia=partes[1] #Aca guarda el dia
            if(! (dia in diasDistintos))
            {
                #Prende la bandera en la clave para ese dia
                diasDistintos[dia] = 1
                #agrego 1 día distinto a la cantidad total de días
                totalDias++
            }
        }

        print "{" > ruta # >ruta vendria a ser como un w en c, si no existe lo crea y si existe lo sobreescrie
        printf("\t\"fechas\":{\n") >> ruta #>>ruta seria como un append, le suma al final del archivo

        # Voy a utilizar los indices I y J para poner o no las ","
        i = 0
        for (dia in diasDistintos) #por cada día reviso SNEO
        {
            i++
            diaFormateado = dia
            gsub("/", "-", diaFormateado)
            printf("\t\t\"%s\": {\n", diaFormateado) >> ruta
            j = 0
            totalDirs = 0

            # Primero cuento cuántas direcciones válidas hay
            for (dir in vectorDirecciones) {
                clave = dia SUBSEP dir
                if (clave in cantApariciones && cantApariciones[clave] > 0) {
                    totalDirs++
                }
            }            
            # Ahora imprimo solo esas direcciones válidas
            for (dir in vectorDirecciones) {
                clave = dia SUBSEP dir
                if (clave in cantApariciones && cantApariciones[clave] > 0) {
                    j++
                    printf("\t\t\t\"%s\": {\n", dir) >> ruta
                    printf("\t\t\t\t\"Min\": %.2f,\n", temperaturaMin[clave]) >> ruta
                    printf("\t\t\t\t\"Max\": %.2f,\n", temperaturaMax[clave]) >> ruta
                    printf("\t\t\t\t\"Promedio\": %.2f\n", suma[clave] / cantApariciones[clave]) >> ruta
                    printf("\t\t\t}%s\n", (j == totalDirs ? "" : ",")) >> ruta
                }
            }
            printf("\t\t}%s\n", (i == totalDias ? "" : ",")) >> ruta
        }
         
        printf("\t}\n") >> ruta
        printf("}\n") >> ruta
    }

    print "Procesamiento de Datos Finalizado."
}
