BEGIN{
    printf("opcion: %s\n", opcion)
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
            fallo++
            if( $i !~ /^[-]?[0-9]+$/)
            {
                print "Los valores que contiene la matriz no son numericos"
                exit 1
            }
        }

    if(opcion == "trasponer") #Trasponer
    {
        for(i=1; i<=columnas; i++)
            matriz[i]= matriz[i] " " $i;
    }
    else #Producto escalar
    {
        for(i=1; i<=columnas; i++)
            matriz[NR]= matriz[NR] " " $i * opcion;
    }
}

END{
    
    if(fallo == 0)
    {
        printf("") > ruta
        for(i=1; i<=columnas; i++)
            printf("%s\n", matriz[i]) >> ruta
    }
}