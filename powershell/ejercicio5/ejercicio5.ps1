<#
.SYNOPSIS
    Script del ejercicio 5 de la APL 1.

.DESCRIPTION
    El script debe permitir consultar informacion relacionada a los nutrientes de las frutas a travez de la api Fruityvice. Se permitira buscar informacion a traves de los ids o nombres o ambos a la vez.

.PARAMETER id
    Id de las frutas a buscar en la API

.PARAMETER name
    Nombre de las frutas a buscar en la API
    
.EXAMPLE
    ./ejercicio5.ps1 -id 1,2,3

.EXAMPLE
    ./ejercicio5.ps1 -name banana,orange,pear

.EXAMPLE
    ./ejercicio5.ps1 -id 1,2,3 -name banana,orange,pear

.NOTES
    ########################################
    #INTEGRANTES DEL GRUPO
    # MARTINS LOURO, LUCIANO AGUSTÍN
    # PASSARELLI, AGUSTIN EZEQUIEL
    # WEIDMANN, GERMAN ARIEL
    # DE SOLAY, FELIX                       
    ########################################
#>
[CmdletBinding(DefaultParameterSetName = 'id')]
param (
    [Parameter(Mandatory,ParameterSetName = 'id')]
    [Parameter(Mandatory,ParameterSetName = 'idName')]
    [ValidateRange(1,9999)]
    [int[]]$id,

    [Parameter(Mandatory,ParameterSetName = 'name')]
    [Parameter(Mandatory,ParameterSetName = 'idName')]
    [ValidateNotNullOrWhiteSpace()]
    [string[]]$name,

    [Alias("help")][switch]$helpPS
)

#Funcion para mostrar en formato
function MostrarFruta($f) {
    Write-Output "id: $($f.id)"
    Write-Output "name: $($f.name)"
    Write-Output "genus: $($f.genus)"
    Write-Output "calories: $($f.nutritions.calories)"
    Write-Output "fat: $($f.nutritions.fat)"
    Write-Output "sugar: $($f.nutritions.sugar)"
    Write-Output "carbohydrates: $($f.nutritions.carbohydrates)"
    Write-Output "protein: $($f.nutritions.protein)"
    Write-Output ""
}

#----------------------------------------------------Main---------------------------------------------------------

if ($HelpPS) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}

#Variables necesarias
$apiFrutas = "https://www.fruityvice.com/api/fruit/"
$cacheFile = "./cacheFile.txt"
$cacheJSON = @{}
$cacheERROR = @{}

#Cargar cache
if (Test-Path $cacheFile) {
    Get-Content $cacheFile | ForEach-Object {
        $json = $_ | ConvertFrom-Json
        $cacheJSON["$($json.id)"] = $json
    }
}

# Eliminar duplicados
$idUnicos = if ($id) { $id | Select-Object -Unique } else { @() }
$nameUnicos =  if ($name) { $name | Select-Object -Unique } else { @() }

# Consultar por ID
foreach ($i in $idUnicos) {
    if (-not $cacheJSON.ContainsKey("$i")) {
        try {
            $json = Invoke-RestMethod -Uri "$apiFrutas$i" -ErrorAction Stop
            if($json -and $null -ne $json.id) {
                $cacheJSON["$($json.id)"] = $json
                MostrarFruta $json
            } else {
                $cacheERROR["$i"] = "Id ${i}: Respuesta invalida o vacia de la API"
                continue
            }
        } catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.Value__ -eq 404) {
                $cacheERROR["$i"] = "Id ${i}: Id no encontrada o válida"
            } else {
                $cacheERROR["$i"] = "No se pudo conectar a la API. Verifique su conexión a Internet"
            }
            continue
        }
    } else {
        MostrarFruta $cacheJSON["$i"]
    }
    #Si la id esta repetida en el nombre ej: -id 1 -name banana, esto eliminaria banana de los parametros
    $nameFruta = $cacheJSON["$i"].name.ToLower()
    $nameUnicos = $nameUnicos | Where-Object{$_.ToLower() -ne $nameFruta}
}

# Consultar por nombre
foreach ($n in $nameUnicos) {
    #Hay que comparar todo en minuscula
    $nameMinus = $n.ToLower()
    $nameCache = $cacheJSON.Values | Where-Object {$_.name.tolower() -eq $nameMinus}
    if ($nameCache) {
        MostrarFruta $nameCache
    } else {
        try {
            $json = Invoke-RestMethod -Uri "$apiFrutas$n" -ErrorAction Stop
            if($json -and $null -ne $json.id) {
                $cacheJSON["$($json.id)"] = $json
                MostrarFruta $json
            } else {
                $cacheERROR["$n"] = "Nombre ${n}: Respuesta invalida o vacia de la API"
                continue
            }
        } catch {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode.Value__ -eq 404) {
                $cacheERROR["$n"] = "Nombre ${n}: Nombre no encontrado o válido"
            } else {
                $cacheERROR["$n"] = "No se pudo conectar a la API. Verifique su conexión a Internet"
            }
            continue
        }
    }
}

# Mostrar errores
if ($cacheERROR.count -gt 0) {
    Write-Host "\n---- Errores ----" -ForegroundColor Red
    $cacheERROR.GetEnumerator() | ForEach-Object { Write-Host $_.value -ForegroundColor Yellow}
}

# Guardar cache evitando duplicados -- Si no, es posible que se guarde informacion repetida en el cache
$idsGuardados = @{}
$cacheJSON.Values | Where-Object {
    if ($idsGuardados.ContainsKey($_.id)) {$false}
    else {$idsGuardados[$_.id] = $true; $true }
    } | ForEach-Object {$_ | ConvertTo-Json -Compress } | Set-Content $cacheFile
exit 0