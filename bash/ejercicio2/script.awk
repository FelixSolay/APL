BEGIN{
    if(opcion=="trasponer")
        printf("Seleccionaste trasponer la matriz\n")
    else printf("Seleccionaste multiplicar por el escalar %d\n", opcion)
}
NR<2{
    columnas= NF
}
{
    
    if(NF != columnas)
    {
        fallo++
        print "La cantidad de columnas en la matriz no es consistente"
        exit 1
    }

    for(i=1; i<=columnas; i++)
        {
            
            if( $i !~ /^([-]?[0-9]+|[-]?[0-9]+\.[0-9]+)$/)
            {
                fallo++
                print "Los valores que contiene la matriz no son numericos"
                exit 1
            }
        }

    if(opcion == "trasponer") #Trasponer
    { 
        for(i=1; i<=columnas; i++){
            if(matriz[i] == "")
                matriz[i] = $i
            else
                matriz[i]= matriz[i] separador $i
        }            
    }
    else #Producto escalar
    {
        for(i=1; i<=columnas; i++){
            valor = $i * opcion
            if(matriz[NR] == "")
                matriz[NR] = valor
            else
                matriz[NR]= matriz[NR] separador valor
        }
    }
}

END{
   
    if(fallo == 0) #Esto es necesario porque aun con exit ejecuta el bloque END
    {
        printf("") > ruta
        for(i=1; i<=columnas; i++)
            printf("%s\n", matriz[i]) >> ruta

        printf("La ruta de salida donde se encuentra la matriz es: %s\n", ruta)
    }
}