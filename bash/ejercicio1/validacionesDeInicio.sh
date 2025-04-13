#!/bin/bash

parametros=("./ejercicio1.sh -d pepe.txt -p" "./ejercicio1.sh -d pruebas_normales.csv" "./ejercicio1.sh -d pruebas_normales.csv -a pepe.json"
"./ejercicio1.sh -d pruebas_normales.csv -a /pepe.json" "./ejercicio1.sh -d pruebas_normales.csv -p" 
"./ejercicio1.sh -d pruebas_normales.txt.csv -p" "./ejercicio1.sh -d pruebas_normales.csv -p -a pepe.json")

for param in "${parametros[@]}"; do
    
    echo "------------------------------------------------"
    echo "Parametros: $param"
    echo ""
    $param
done