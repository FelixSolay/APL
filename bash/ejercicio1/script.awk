BEGIN{
    print "Inicializando el procesamiento de datos..."
}

{
    fecha=$2
    direccion=$4
    temp=$5

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

END{

    PROCINFO["sorted_in"] = "@ind_str_desc"  #Esta sola funcion reemplaza a todo el ordenamiento que hariamos normalmente
    
    #True es el valor por defecto que le asignamos a la salida por pantalla
    if(ruta=="true")
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
                printf("\t\t%s\n", n==NR?"}":"},") >>ruta #Si es el ultimo archivo no tiene que meter una coma, si no es el ultimo si
            }
            
        }
         
         printf("\t}\n") >> ruta
         printf("}\n") >> ruta
    }
}