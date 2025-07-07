########################################
#INTEGRANTES DEL GRUPO
# MARTINS LOURO, LUCIANO AGUSTÍN
# PASSARELLI, AGUSTIN EZEQUIEL
# WEIDMANN, GERMAN ARIEL
# DE SOLAY, FELIX                       
########################################

<#
.SYNOPSIS
    Script del ejercicio 2 de la APL 1

.DESCRIPTION
    El Script permite realizar producto escalar o trasposición de matrices.
    Entrada: archivo de texto plano.
    Salida: archivo llamado "salida.nombreArchivoEntrada" en el mismo directorio.

    Ejemplo formato:
     0|1|2
     1|1|1
    -3|-3|-1


.PARAMETER Matriz
    Ruta del archivo de entrada.

.PARAMETER Producto
    Valor entero para utilizar en el producto escalar.

.PARAMETER Trasponer
    Indica que debe realizar la transposición sobre la matriz.

.PARAMETER Separador
    Caracter que se utilizará como separador de columnas.

.PARAMETER Help
    Muestra esta ayuda.

.NOTES
    No se pueden usar simultáneamente -Producto y -Trasponer.
    Se debe elegir uno u otro.
    El separador por defecto es "|"

.EXAMPLE
    .\ejercicio2.ps1 -Matriz .\matriz.txt -Trasponer -Separador "|"

.EXAMPLE
    .\ejercicio2.ps1 -m .\matriz.txt -p 3 -s "|"
#>

[CmdletBinding(DefaultParameterSetName = "Producto")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Producto")]
    [Parameter(Mandatory = $true, ParameterSetName = "Transponer")]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ (Test-Path $_) -and (Get-Item $_).Length -gt 0 })]
    [ValidateScript({ $_.EndsWith(".txt") })]
    [validateScript({ -not (([System.IO.Path]::GetFileName($_)) -match '\.txt\.\w+$') })]
    [Alias("m")][string]$matriz,

    [Parameter(Mandatory, ParameterSetName = "Producto")]
    [validateNotNull()]
    [Alias("p")][double]$producto,

    [Parameter(Mandatory, ParameterSetName = "Transponer")]
    [Alias("t")][switch]$trasponer,

    [Parameter(Mandatory = $true, ParameterSetName = "Producto")]
    [Parameter(Mandatory = $true, ParameterSetName = "Transponer")]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ $_ -match '^[^0-9-]{1}$' })]
    [ValidateScript({ $_.Length -eq 1 })]
    [Alias("s")][string]$separador,
    [Parameter(Mandatory = $false)]
    [Alias("h")][switch]$Help
)
function ProcesarMatriz {
    param (
        [string]$archivo,
        [string]$salida,
        [Nullable[Double]]$producto,
        [bool]$trasponer,
        [string]$sep
    )

    $lineas = Get-Content $archivo
    $matriz = @()
    $numCols = $null

    if ($lineas.Count -eq 1){
        Write-Error "La cantidad de filas tiene que ser mayor a 1."
        exit 1
    }
    
    foreach ($i in 0..($lineas.Count - 1)) {#por cada línea leída...
        #Uso Escape($sep) por si pasan un separador que sea caracter especial
        $valores = $lineas[$i] -split [regex]::Escape($sep) | ForEach-Object { $_.Trim() }
        if (-not $numCols) { 
            $numCols = $valores.Count 
        }
        elseif ($valores.Count -ne $numCols) { #validar consistencia de columnas
            Write-Error "La cantidad de columnas no es consistente."
            exit 1
        }
        #validar si es numérico el contenido ($_ es el elemento actual procesado "PipelineVariable")

        if ($valores | Where-Object { $_ -notmatch '^[-]?\d+(\.\d+)?$' }) { 
            Write-Error "La matriz contiene valores no numéricos"
            exit 1
        }
        #Con ,$valores me aseguro que se agrega como una lista completa 
        $matriz += ,$valores
    }

    if ($trasponer) {
        Write-Host "Seleccionaste trasponer la matriz"
        $resultado = for ($col = 0; $col -lt $numCols; $col++) {
            #Transposición -> Toma el valor de la columna actual $col, para cada fila $_[$col]
            ($matriz | ForEach-Object { $_[$col] }) -join $sep
            #uso el -join $sep para juntar los valores de la nueva fila transpuesta a la salida
        }
    } else {
        Write-Host "Seleccionaste multiplicar por el escalar $producto"
        #Producto escalar -> A cada elemento de la matriz multiplicar por *$producto
        $resultado = $matriz | ForEach-Object { #La forma más rápida de iterar la matriz completa es con un doble $_
            ($_ | ForEach-Object { [double]$_ * $producto }) -join $sep
        }
    }

    Set-Content -Path $salida -Value $resultado
    Write-Host "La ruta de salida donde se encuentra la matriz es: $salida"
}

# MAIN
if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}

if (-not (Get-Content $matriz | Select-String -SimpleMatch $separador)) {
    Write-Error "El separador '$separador' no aparece en el archivo"; 
    exit 8
}

#Similar al basename y dirname de bash, para armar la ruta de salida
$rutaAbsolutaMatriz = (Resolve-Path $matriz).Path
$nombreArchivo = [System.IO.Path]::GetFileName($rutaAbsolutaMatriz)
$directorio = Split-Path $rutaAbsolutaMatriz -Parent
$rutaSalida = Join-Path $directorio "salida.$nombreArchivo"

ProcesarMatriz -archivo $rutaAbsolutaMatriz -salida $rutaSalida -producto $producto -trasponer $trasponer.IsPresent -sep $separador