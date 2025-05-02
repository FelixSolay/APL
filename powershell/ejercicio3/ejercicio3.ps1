<#
.SYNOPSIS
    Script del ejercicio 3 de la APL 1

.DESCRIPTION
    El script debe identificar la cantidad de ocurrencias de determinadas palabras en determinados
    archivos dentro de un directorio (incluyendo los subdirectorios).

.PARAMETER Directorio
    Ruta del directorio a analizar.

.PARAMETER Palabras
    Lista de palabras separadas por comas.

.PARAMETER Archivos
    Lista de extensiones separadas por comas (sin puntos).

.PARAMETER Help
    Muestra esta ayuda.

.EXAMPLE
    ./ejercicio3.sh -d /ruta/al/directorio --archivo txt,sh -p for,else
#>

param (
    [Alias("h")][switch]$Help,
    [Alias("d")][string]$Directorio,
    [Alias("a")][string[]]$Archivos,
    [Alias("p")][string[]]$Palabras
)

function ValidarParametros($Directorio, $Extensiones, $Palabras) {
    if (-not (Test-Path $Directorio -PathType Container)) {
        Write-Error "El directorio especificado no existe."
        exit 1
    }
    if (-not $Extensiones) {
        Write-Error "No se cargaron extensiones para buscar."
        exit 2
    }
    if (-not $Palabras) {
        Write-Error "No se cargaron palabras para buscar."
        exit 3
    }
}

# MAIN
if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}

ValidarParametros $Directorio $Archivos $Palabras
#antepongo "*." a las extensiones de los archivos buscados para utilizarlo como patrón de búsqueda
$extensiones = $Archivos -split ',' | ForEach-Object { "*." + $_ }
#Al parámetro Palabras lo separo y corto todos los posibles espacios que haya entre la lista
$palabras = $Palabras -split ',' | ForEach-Object { $_.Trim() }
#armar vector de archivos
$archivosEncontrados = @()
foreach ($ext in $extensiones) {
    # -Recurse es para buscar en subdirectorios
    # -Filter $ext : para aplicar el patrón de búsqueda, por ejemplo "*.txt" 
    # -File : Solo archivos, no carpetas
    # -ErrorAction SilentlyContinue : para no mostrar errorres, por ejemplo si no encuentra nada
    $archivosEncontrados += Get-ChildItem -Path $Directorio -Recurse -Filter $ext -File -ErrorAction SilentlyContinue
}
#armar vector de apariciones por palabras
$apariciones = @{}
foreach ($palabra in $palabras) {
    $apariciones[$palabra] = 0
}
#iterar y contar apariciones
foreach ($archivo in $archivosEncontrados) {
    Get-Content $archivo.FullName | ForEach-Object {
        $linea = $_ 
        foreach ($palabra in $palabras) {
            $temp = $linea
            while (($idx = $temp.IndexOf($palabra)) -ge 0) {
                $apariciones[$palabra]++
                $temp = $temp.Substring($idx + 1)
            }
        }
    }
}
#ordenar y mostrar resultado
$apariciones.GetEnumerator() | 
    Sort-Object Value -Descending |
    ForEach-Object { "{0,-10}: {1}" -f $_.Key, $_.Value }


