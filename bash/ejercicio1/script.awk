BEGIN{
    print "Inicializando el procesamiento de datos..."
}

    # if(id ~ /^[0-9]+$/ && fecha ~ /^[0-9]{4}\/(0[1-9]|1[0-2])\/(0[1-9]|[12][0-9]|3[0-1])$/ && 
    # hora ~ /([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]/ && 
    # (direccion == "Norte" || direccion == "Sur" || direccion == "Este" || direccion == "Oeste") && 
    # temp ~ /[0-9]+.[0-9]+/)
    #     return "valido"
    # return "invalido"

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
        lineasConError++
        printf("%s", mensajeSalida);
        #Aca lo podemos printear o redirigir a un archivo tipo errores.log
    }
}

END{

    PROCINFO["sorted_in"] = "@ind_str_desc"  #Esta sola funcion reemplaza a todo el ordenamiento que hariamos normalmente
    
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
        #Necesito iterar alrededor de la clave compuesta. No encontre mejor forma de hacer esto sin reescribir todo el codigo
        vectorDirecciones["Sur"]++
        vectorDirecciones["Norte"]++
        vectorDirecciones["Este"]++
        vectorDirecciones["Oeste"]++
        n=0; #Necesitamos un contador para determinar cuando lleguemos al ultimo elemento porque no lleva ,
         print "{" > ruta # >ruta vendria a ser como un w en c, si no existe lo crea y si existe lo sobreescrie
         printf("\t\"fechas\":{\n") >> ruta #>>ruta seria como un append, le suma al final del archivo
         for (clave in temperaturaMin)
        {                      
            split(clave,partes, SUBSEP);
            dia=partes[1]

            if(diaAct!=dia)
            {
                n+=4; 
                 printf("\t\t\"%s\": {\n", dia) >>ruta
                for(dir in vectorDirecciones)
                {
                    printf("\t\t\t\"%s\": {\n", dir) >>ruta
                    clave = dia SUBSEP dir
                    printf("\t\t\t\t\"Min\": %d,\n", temperaturaMin[clave]) >>ruta
                    printf("\t\t\t\t\"Max\": %d,\n", temperaturaMax[clave]) >>ruta
                    printf("\t\t\t\t\"Promedio\": %d\n", cantApariciones[clave]==0?0:suma[clave]/cantApariciones[clave]) >>ruta
                    printf("\t\t\t%s\n", dir=="Este"?"}":"},") >>ruta
                }
                diaAct=dia
                printf("\t\t%s\n", n==(NR-lineasConError)?"}":"},") >>ruta #Si es el ultimo archivo no tiene que meter una coma, si no es el ultimo si
            }
            
        }
         
         printf("\t}\n") >> ruta
         printf("}\n") >> ruta
    }
}



#backup de la lógica de Agus, de alguna manera está fallando en el momento de poner la coma al final, estoy buscando otra forma de iterar
#        #Necesito iterar alrededor de la clave compuesta. No encontre mejor forma de hacer esto sin reescribir todo el codigo
#        vectorDirecciones["Sur"]++
#        vectorDirecciones["Norte"]++
#        vectorDirecciones["Este"]++
#        vectorDirecciones["Oeste"]++
#        n=0; #Necesitamos un contador para determinar cuando lleguemos al ultimo elemento porque no lleva ,
#         print "{" > ruta # >ruta vendria a ser como un w en c, si no existe lo crea y si existe lo sobreescrie
#         printf("\t\"fechas\":{\n") >> ruta #>>ruta seria como un append, le suma al final del archivo
#         for (clave in temperaturaMin)
#        {                      
#            split(clave,partes, SUBSEP);
#            dia=partes[1]
#
#            if(diaAct!=dia)
#            {
#                n+=4; 
#                 printf("\t\t\"%s\": {\n", dia) >>ruta
#                for(dir in vectorDirecciones)
#                {
#                    printf("\t\t\t\"%s\": {\n", dir) >>ruta
#                    clave = dia SUBSEP dir
#                    printf("\t\t\t\t\"Min\": %d,\n", temperaturaMin[clave]) >>ruta
#                    printf("\t\t\t\t\"Max\": %d,\n", temperaturaMax[clave]) >>ruta
#                    printf("\t\t\t\t\"Promedio\": %d\n", cantApariciones[clave]==0?0:suma[clave]/cantApariciones[clave]) >>ruta
#                    printf("\t\t\t%s\n", dir=="Este"?"}":"},") >>ruta
#                }
#                diaAct=dia
#                printf("\t\t%s\n", n==(NR-lineasConError)?"}":"},") >>ruta #Si es el ultimo archivo no tiene que meter una coma, si no es el ultimo si
#            }
#            
#        }
#         
#         printf("\t}\n") >> ruta
#         printf("}\n") >> ruta