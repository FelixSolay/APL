########################################
#INTEGRANTES DEL GRUPO
# MARTINS LOURO, LUCIANO AGUSTÍN
# PASSARELLI, AGUSTIN EZEQUIEL
# WEIDMANN, GERMAN ARIEL
# DE SOLAY, FELIX                       
########################################
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
    ./ejercicio3.ps1 -d /ruta/al/directorio -archivo txt,csv,ps1 -p for,else
    ./ejercicio3.ps1 -d . -archivo txt,csv,ps1 -p for,else
#>

param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [Alias("d")][string]$Directorio,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [Alias("a")][string[]]$Archivos, #pasan como lista

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [Alias("p")][string[]]$Palabras, #pasan como lista

    [Alias("h")][switch]$Help
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

#DEBUG
#Write-Host "Extensiones: $($Archivos -join ', ')"
#Write-Host "Palabras: $($Palabras -join ', ')"

ValidarParametros $Directorio $Archivos $Palabras
#antepongo "*." a las extensiones de los archivos buscados para utilizarlo como patrón de búsqueda
$extensiones = $Archivos -split ',' | ForEach-Object { "*." + $_ } # -split ',' <- Habría que hacerlo sin split, pero corriendo desde linux no lo detecta como lista
#Al parámetro Palabras lo separo y corto todos los posibles espacios que haya entre la lista
$palabras = $Palabras -split ',' | ForEach-Object { $_.Trim() }# -split ',' <- Habría que hacerlo sin split, pero corriendo desde linux no lo detecta como lista
#armar vector de archivos
$archivosEncontrados = @()
foreach ($ext in $extensiones) {
    # -Recurse es para buscar en subdirectorios
    # -Filter $ext : para aplicar el patrón de búsqueda, por ejemplo "*.txt" 
    # -File : Solo archivos, no carpetas
    # -ErrorAction SilentlyContinue : para no mostrar errorres, por ejemplo si no encuentra nada
    $archivosEncontrados += Get-ChildItem -Path $Directorio -Recurse -Filter $ext -File -ErrorAction SilentlyContinue
}
#armar vector de apariciones por palabras. Tenemos que armarlo asi para que sea case sensitive
$apariciones = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
foreach ($palabra in $palabras) {
    $apariciones[$palabra] = 0
}
#iterar y contar apariciones
foreach ($archivo in $archivosEncontrados) {
    Get-Content $archivo.FullName | ForEach-Object {
        $linea = $_ 
        foreach ($palabra in $palabras) {
            #usamos regex para que tome la palabra completa y no una porcion de la misma
            $regex = New-Object System.Text.RegularExpressions.Regex ("\b$([regex]::Escape($palabra))\b", [System.Text.RegularExpressions.RegexOptions]::None)
            #Si se quiere que funcione aún considerando subcadenas dentro de una cadena, sería esta definición
            #$regex = New-Object System.Text.RegularExpressions.Regex ("$([regex]::Escape($palabra))", [System.Text.RegularExpressions.RegexOptions]::None)
            $apariciones[$palabra] += ([regex]::Matches($linea,$regex)).Count
        }
    }
}
#ordenar y mostrar resultado
$apariciones.GetEnumerator() | 
    Sort-Object Value -Descending |
    ForEach-Object { "{0,-10}: {1}" -f $_.Key, $_.Value }

exit 0

