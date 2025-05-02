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


param(
    [Alias("m")][string]$matriz,
    [Alias("p")][double]$producto,
    [Alias("t")][switch]$trasponer,
    [Alias("s")][string]$separador = "|",
    [Alias("h")][switch]$help
)

function ValidarParametros {
    param (
        [string]$matriz,
        [Nullable[Double]]$producto,
        [bool]$trasponer,
        [string]$separador
    )

    if (-not (Test-Path $matriz) -or (Get-Item $matriz).Length -eq 0) {
        Write-Error "El archivo no existe o está vacío."; exit 2
    }

    if (-not $matriz.EndsWith(".txt")) {
        Write-Error "El archivo debe tener extensión .txt"; exit 3
    }

    $NombreArchivo = [System.IO.Path]::GetFileName($matriz)
    if ($NombreArchivo -match '\.txt\.\w+$') {
        Write-Error "El archivo tiene una doble extensión"
        exit 4
    }

    if ($producto -and $trasponer) {
        Write-Error "No se puede hacer trasposición y producto escalar a la vez"; exit 5
    }

    if ([string]::IsNullOrWhiteSpace($separador) -or $separador -match '^-?\d+$') {
        Write-Error "Separador no puede estar vacío, ser un número o '-'"; exit 6
    }

    if ($separador.Length -ne 1) {
        Write-Error "El separador debe ser un único carácter"; exit 7
    }

    if (-not (Get-Content $matriz | Select-String -SimpleMatch $separador)) {
        Write-Error "El separador '$separador' no aparece en el archivo"; exit 8
    }

    if ($producto -and -not ($producto -match '^-?\d+(\.\d+)?$')) {
        Write-Error "El producto escalar debe ser numérico"; exit 9
    }
}

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
        $valores = $lineas[$i] -split [regex]::Escape($sep)
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
        #Recorrer cada columna de la matriz original
        #    $col
        # _$  [1 2 3]
        #     [4 5 6]
        #
        # $resultado = 1 | 4
        #              2 | 5
        #              3 | 6

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

ValidarParametros -matriz $matriz -producto $producto -trasponer $trasponer -separador $separador

#Similar al basename y dirname de bash, para armar la ruta de salida
$nombreArchivo = [System.IO.Path]::GetFileName($matriz)
$directorio = Split-Path $matriz -Parent
$rutaSalida = Join-Path $directorio "salida.$nombreArchivo"

ProcesarMatriz -archivo $matriz -salida $rutaSalida -producto $producto -trasponer $trasponer.IsPresent -sep $separador