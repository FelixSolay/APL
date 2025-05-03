BEGIN{
    split(pals, palabrasABuscar,",")
}

{
    for (clave in palabrasABuscar)
    {   
        #usamos regex para que tome la palabra completa y no una porcion de la misma
        regex = "\\<" palabrasABuscar[clave] "\\>"
        linea=$0
        while (match(linea,regex))
        {
            apariciones[clave]++;
            linea = substr(linea, RSTART + RLENGTH) 
        }
    }

}
END{
    #para ordenarlo voy a utilizar un array auxiliar de salida
    for (clave in palabrasABuscar)
    {
        if (apariciones[clave] == "") {
            apariciones[clave] = 0
        }
        salida[palabrasABuscar[clave]] = apariciones[clave]
    }
    #cargué el array de salida, ahora itero buscando el mayor, muestro y elimino el elemento del array (para no volver a procesarlo)
    while (length(salida) > 0) {
        max = -1
        for (palabra in salida) {
            if (salida[palabra] > max) {
                max = salida[palabra]
                max_palabra = palabra
            }
        }
        printf "%-10s: %d\n", max_palabra, salida[max_palabra]
        delete salida[max_palabra]
    }    
}




#backup: a veces cuenta mal porque está pisando la línea cuando encuentra una aparición

#    linea=$0
#    for (clave in palabrasABuscar)
#    {    
#        pos=index(linea, palabrasABuscar[clave])
#        while(pos!=0)
#        {
#            apariciones[clave]++;
#            linea=substr(linea, pos+1)
#            pos=index(linea, palabrasABuscar[clave])
#        }
#    }

#Backup: no estaba mostrando en orden (de mayor a menor apariciones)
#END{
#    for (clave in palabrasABuscar)
#    {
#        printf("%-10s: %d\n", palabrasABuscar[clave], apariciones[clave])
#    } 
#}