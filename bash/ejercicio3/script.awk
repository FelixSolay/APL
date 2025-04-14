BEGIN{
    split(pals, palabrasABuscar,",")
}

{
    linea=$0
    for (clave in palabrasABuscar)
    {    
        pos=index(linea, palabrasABuscar[clave])
        while(pos!=0)
        {
            apariciones[clave]++;
            linea=substr(linea, pos+1)
            pos=index(linea, palabrasABuscar[clave])
        }
        }

}
END{
    for (clave in palabrasABuscar)
    {
        printf("%s: %d\n", palabrasABuscar[clave], apariciones[clave])
    } 
}