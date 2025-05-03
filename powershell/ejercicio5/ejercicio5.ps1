<#
.SYNOPSIS
    Script del ejercicio 5 de la APL 1.

.DESCRIPTION
    El script debe permitir consultar informacion relacionada a los nutrientes de las frutas a travez
    de la api Fruityvice. Se permitira buscar informacion a traves de los ids o nombres o ambos a la
    vez.

.PARAMETER id
    Ruta del directorio a monitorear

.PARAMETER name
    Ruta del directorio en donde se van a crear los backups

.PARAMETER help
    Muestra esta ayuda.

.NOTES
    Una vez obtenida la informacion, se generará esta a modo de cache para no volver a consultarse en la api.
    Se mostrara la informacion con el siguiente formato:
    id: 2,
    name: Orange,
    genus: Citrus,
    calories: 43,
    fat: 0.2,
    sugar: 8.2,
    carbohydrates: 8.3,
    protein: 1
    
.EXAMPLE
    ./ejercicio5.ps1 -id "11,22" -name "banana,orange"
#>

param (
    [int[]]$id,
    [string[]]$name,
    [switch]$help
)

# MAIN
if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}


if (-not $id -and -not $name) {
    Write-Error "No se cargo ninguna id ni ningun nombre"
    exit 1
}

# Validar que los IDs sean positivos
if ($id) {
    foreach ($i in $id) {
        #DEBUG
        #Write-Host "Id numero: $i"
        if ($i -lt 0) {
            Write-Error "ID inválido: $i. Debe ser un número entero positivo"
            exit 2
        }
    }
}

# Eliminar duplicados
$idUnicos = @{}
$nameUnicos = @{}
if ($id) { foreach ($i in $id) { $idUnicos[$i] = $true } }
if ($name) { foreach ($n in $name) { $nameUnicos[$n] = $true } }

# Cargar cache
$cacheFile = "./cacheFile.txt"
$cacheJSON = @{}
$cacheERROR = @{}

if (Test-Path $cacheFile) {
    Get-Content $cacheFile | ForEach-Object {
        $json = $_ | ConvertFrom-Json
        $cacheJSON["$($json.id)"] = $json
    }
}

$apiFrutas = "https://www.fruityvice.com/api/fruit/"

# Consultar por ID
foreach ($id in $idUnicos.Keys) {
    if (-not $cacheJSON.ContainsKey($id)) {
        try {
            #DEBUG
            #Write-Host "intentando conectar con... $apiFrutas$id"
            $json = Invoke-RestMethod -Uri "$apiFrutas$id" -ErrorAction Stop
        } catch {
            $cacheERROR["$id"] = "Id ${id}: ERROR 6, No se pudo conectar a la API. Verifique su conexión a Internet"
            continue
        }
        if ($json.error -eq "Not found") {
            $cacheERROR["$id"] = "Id ${id}: Id no encontrada o válida"
            continue
        }
        $cacheJSON["$($json.id)"] = $json
    }

    $fruta = $cacheJSON[$id]
    $salida = @{
        id = $fruta.id
        name = $fruta.name
        genus = $fruta.genus
        calories = $fruta.nutritions.calories
        fat = $fruta.nutritions.fat
        sugar = $fruta.nutritions.sugar
        carbohydrates = $fruta.nutritions.carbohydrates
        protein = $fruta.nutritions.protein
    }
    $salida | ConvertTo-Json -Compress

    foreach ($n in $nameUnicos.Keys) {
        if ($fruta.name -eq $n) {
            $nameUnicos[$n] = $null
        }
    }
}

# Consultar por nombre
foreach ($n in $nameUnicos.Keys) {
    if (-not $n) { continue }

    $found = $false
    foreach ($f in $cacheJSON.Values) {
        if ($f.name -eq $n) {
            $salida = @{
                id = $f.id
                name = $f.name
                genus = $f.genus
                calories = $f.nutritions.calories
                fat = $f.nutritions.fat
                sugar = $f.nutritions.sugar
                carbohydrates = $f.nutritions.carbohydrates
                protein = $f.nutritions.protein
            }
            $salida | ConvertTo-Json -Compress
            $found = $true
            break
        }
    }

    if (-not $found) {
        try {
            $json = Invoke-RestMethod -Uri "$apiFrutas$n" -ErrorAction Stop
        } catch {
            $cacheERROR["$n"] = "Fruta ${n}: ERROR 6, No se pudo conectar a la API. Verifique su conexión a Internet"
            continue
        }

        if ($json.error -eq "Not found") {
            $cacheERROR["$n"] = "Fruta ${n}: Fruta no encontrada o válida"
            continue
        }

        $cacheJSON["$($json.id)"] = $json
        $salida = @{
            id = $json.id
            name = $json.name
            genus = $json.genus
            calories = $json.nutritions.calories
            fat = $json.nutritions.fat
            sugar = $json.nutritions.sugar
            carbohydrates = $json.nutritions.carbohydrates
            protein = $json.nutritions.protein
        }
        $salida | ConvertTo-Json -Compress
    }
}

# Mostrar errores
foreach ($e in $cacheERROR.Keys) {
    Write-Host $cacheERROR[$e]
}

# Guardar cache
$cacheJSON.Values | ForEach-Object { $_ | ConvertTo-Json -Compress } | Set-Content $cacheFile