BEGIN{
    split(pals, palabrasABuscar,",")
}

{
    for (clave in palabrasABuscar)
    {   
        #usamos regex para que tome la palabra completa y no una porcion de la misma
        regex = "\\<" palabrasABuscar[clave] "\\>"
        #De esta otra manera busca las palabras tal cual, sin considerar si son porción de otra palabra
        #regex = palabrasABuscar[clave]
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
