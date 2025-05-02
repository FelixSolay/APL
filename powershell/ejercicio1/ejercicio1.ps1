<#
.SYNOPSIS
    Script del ejercicio 1 de la APL 1.

.DESCRIPTION
    Lee un archivo CSV con registros de temperaturas en distintas ubicaciones.
    Procesa la información y genera una salida en formato JSON con:
        • Promedios
        • Máximos
        • Mínimos
    agrupados por fecha y ubicación.

.PARAMETER Directorio
    Ruta del archivo CSV de entrada.

.PARAMETER Archivo
    Ruta del archivo JSON de salida.

.PARAMETER Pantalla
    Muestra el resultado por pantalla.

.PARAMETER Help
    Muestra esta ayuda.

.NOTES
    No se pueden usar simultáneamente -Archivo y -Pantalla.
    Se debe elegir uno u otro.

.EXAMPLE
    .\ejercicio1.ps1 -Directorio .\pruebas_normales.csv -Archivo .\salida.json

.EXAMPLE
    .\ejercicio1.ps1 -d .\entrada.csv -p
#>

param(
    [Alias("d")][string]$Directorio,
    [Alias("a")][string]$Archivo,
    [Alias("p")][switch]$Pantalla,
    [Alias("h")][switch]$Help
)
function ValidarParametros {
    param(
        [string]$Directorio,
        [string]$Archivo,
        [bool]$Pantalla
    )

    if (-not $Archivo -and -not $Pantalla) {
        Write-Error "No se cargó un archivo de salida ni se pidió mostrar por pantalla"
        exit 1
    }

    if (-not (Test-Path $Directorio) -or (Get-Content $Directorio).Length -eq 0) {
        Write-Error "El archivo no existe o está vacío"
        exit 2
    }

    if ([System.IO.Path]::GetExtension($Directorio) -ne ".csv") {
        Write-Error "El archivo no es del tipo CSV (Valores separados por comas)"
        exit 3
    }

    $NombreArchivo = [System.IO.Path]::GetFileName($Directorio)
    if ($NombreArchivo -match '\.csv\.\w+$') {
        Write-Error "El archivo tiene una doble extensión"
        exit 4
    }

    if ($Archivo -and $Pantalla) {
        Write-Error "Solo se puede mostrar la salida por archivo o por pantalla, no ambos"
        exit 5
    }
    #si por ejemplo creamos \home\usuario\salida.json, esta validacion es que \home\usuario exista y ademas que el archivo sea un JSON
    if ($Archivo) {
        
        $directorioPadre = Split-Path -Path $Archivo -Parent

        
        if (-not (Test-Path $directorioPadre)) {
            Write-Error "El directorio '$directorioPadre' no existe."
            exit 6
        }

        
        if (-not (Get-Item $directorioPadre).PSIsContainer) {
            Write-Error "La ruta '$directorioPadre' no es un directorio."
            exit 7
        }

        if (-not ($Archivo -match "\.json$")) {
            Write-Error "El archivo '$Archivo' debe tener extensión .json."
            exit 8
        }
    }
}

function ValidarJSON {
    param([string]$RutaArchivo)
    try {
        Get-Content -Raw -Path $RutaArchivo | ConvertFrom-Json | Out-Null
        Write-Output "El JSON es válido."
    } catch {
        Write-Output "El JSON es inválido."
        exit 1
    }
}

function ProcesarCSV {
    param(
        [string]$RutaCSV,
        [string]$ArchivoSalida,
        [switch]$Pantalla        
    )

    $Datos = Import-Csv -Path $RutaCSV -Delimiter ',' -Header 'ID','Fecha','Hora','Direccion','Temperatura'

    $Resultados = @{}  #hashtable clave|valor
    $LineaActual = 1
    foreach ($Registro in $Datos) {
        $ID = $Registro.ID
        $Fecha = $Registro.Fecha
        $Hora = $Registro.Hora
        $Direccion = $Registro.Direccion
        $Temperatura = $Registro.Temperatura
        # Validaciones
        $Errores = @()
        if (-not ($ID -match '^\d+$')) {
            $Errores += "Línea ${LineaActual}: Error en el ID. El mismo debe ser numérico."
        }
        if (-not ($Fecha -match '^\d{4}/(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])$')) {
            $Errores += "Línea ${LineaActual}: Error en la fecha. El formato debe ser yyyy/mm/dd."
        }
        if (-not ($Hora -match '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$')) {
            $Errores += "Línea ${LineaActual}: Error en la hora. El formato debe ser hh:mm:ss."
        }
        if ($Direccion -notin @("Norte", "Sur", "Este", "Oeste")) {
            $Errores += "Línea ${LineaActual}: Error en la dirección. Valores posibles: Norte, Sur, Este, Oeste."
        }
        if (-not ($Temperatura -match '^-?\d+(\.\d+)?$')) {
            $Errores += "Línea ${LineaActual}: Error en la temperatura. Debe ser un número decimal."
        }
        $LineaActual++

        if ($Errores.Count -gt 0) {
            foreach ($Error in $Errores) {
                Write-Output $Error
            }
            continue
        }

        # Procesamiento
        if (-not $Resultados.ContainsKey($Fecha)) {
            $Resultados[$Fecha] = @{}
        }
        if (-not $Resultados[$Fecha].ContainsKey($Direccion)) {
            $Resultados[$Fecha][$Direccion] = @{ #hashtable de estadísticas para cierta fecha y dirección
                Min = [double]::MaxValue
                Max = [double]::MinValue
                Suma = 0
                Cont = 0
            }
        }

        $Temp = [double]$Temperatura
        if ($Temp -lt $Resultados[$Fecha][$Direccion].Min) {
            $Resultados[$Fecha][$Direccion].Min = $Temp
        }
        if ($Temp -gt $Resultados[$Fecha][$Direccion].Max) {
            $Resultados[$Fecha][$Direccion].Max = $Temp
        }
        $Resultados[$Fecha][$Direccion].Suma += $Temp
        $Resultados[$Fecha][$Direccion].Cont += 1
    }

    $Salida = @{ fechas = @{} }

    foreach ($Fecha in $Resultados.Keys) {
        $FechaFormateada = $Fecha -replace '/', '-'
        $Salida.fechas[$FechaFormateada] = @{}

        foreach ($Direccion in $Resultados[$Fecha].Keys) {
            $Min = $Resultados[$Fecha][$Direccion].Min
            $Max = $Resultados[$Fecha][$Direccion].Max
            $Promedio = [math]::Round($Resultados[$Fecha][$Direccion].Suma / $Resultados[$Fecha][$Direccion].Cont, 2)

            $Salida.fechas[$FechaFormateada][$Direccion] = @{
                Min = $Min
                Max = $Max
                Promedio = $Promedio
            }
        }
    }

    if ($Pantalla) {
        foreach ($Fecha in $Salida.fechas.Keys) {
            foreach ($Direccion in $Salida.fechas[$Fecha].Keys) {
                $DatosDir = $Salida.fechas[$Fecha][$Direccion]
                Write-Output "Día: $Fecha, Dirección: $Direccion, Mínima: $($DatosDir.Min), Máxima: $($DatosDir.Max), Promedio: $($DatosDir.Promedio)"
            }
        }
    } else {
        $JSON = $Salida | ConvertTo-Json -Depth 5
        Set-Content -Path $ArchivoSalida -Value $JSON -Encoding UTF8
        ValidarJSON -RutaArchivo $ArchivoSalida
    }
}

# MAIN
if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}
ValidarParametros -Directorio $Directorio -Archivo $Archivo -Pantalla $Pantalla
ProcesarCSV -RutaCSV $Directorio -ArchivoSalida $Archivo -Pantalla:$Pantalla
exit 0