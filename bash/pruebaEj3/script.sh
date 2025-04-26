#!/bin/bash

# Script que genera 5 números aleatorios y dice si son pares o impares

echo "Generando 5 números aleatorios..."

for i in {1..5}
do
    num=$(( RANDOM % 100 ))  # Número aleatorio entre 0 y 99
    echo "Número $i: $num"

    if (( num % 2 == 0 )); then
        echo "  -> Es par."
    else
        echo "  -> Es impar."
    fi
done