#!/bin/bash

# Configuraciones
origen="$1"  # Carpeta a respaldar
backup_dir="$HOME/bups"  # Carpeta donde se guardan los backups
fecha=$(date +"%Y-%m-%d_%H-%M-%S")
nombre_backup="backup_$(basename "$origen")_$fecha.tar.gz"

# Verificación
if [ ! -d "$origen" ]; then
    echo "La carpeta origen no existe: $origen"
    exit 1
fi

# Crear carpeta de backups si no existe
mkdir -p "$backup_dir"

# Crear backup
tar -czf "$backup_dir/$nombre_backup" -C "$(dirname "$origen")" "$(basename "$origen")"

# Confirmación
if [ $? -eq 0 ]; then
    echo "Backup creado en: $backup_dir/$nombre_backup"
else
    echo "Error al crear el backup."
fi