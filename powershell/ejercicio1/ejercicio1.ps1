########################################
#INTEGRANTES DEL GRUPO
# MARTINS LOURO, LUCIANO AGUSTÍN
# PASSARELLI, AGUSTIN EZEQUIEL
# WEIDMANN, GERMAN ARIEL
# DE SOLAY, FELIX                       
########################################

<#
.SYNOPSIS
    Script del ejercicio 1 de la APL 1.

.DESCRIPTION
    Lee un Directorio con archivos CSV que contienen registros de 
    temperaturas en distintas ubicaciones. Procesa la información 
    y genera una salida en formato JSON con:
        • Promedios
        • Máximos
        • Mínimos
    agrupados por fecha y ubicación.

.PARAMETER Directorio
    Ruta del Directorio que contiene los archivos CSV de entrada.

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
    .\ejercicio1.ps1 -Directorio ./entradas_csv -Archivo .\salida.json

.EXAMPLE
    .\ejercicio1.ps1 -d ./entradas_csv -p
#>

[CmdletBinding(DefaultParameterSetName = "Archivo")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Archivo")]
    [Parameter(Mandatory = $true, ParameterSetName = "Pantalla")]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({
        return (Test-Path $_) -and ((Get-Item $_).PSIsContainer)
    })]
    [Alias("d")][string]$Directorio,

    [Parameter(Mandatory, ParameterSetName = "Archivo")]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ $_ -match "\.json$" })]
    [ValidateScript({ Test-Path (Split-Path -Path $_ -Parent) })]
    [ValidateScript({ (Get-Item (Split-Path -Path $_ -Parent)).PSIsContainer })]
    [Alias("a")][string]$Archivo,

    [Parameter(Mandatory, ParameterSetName = "Pantalla")]
    [Alias("p")][switch]$Pantalla,

    [Parameter(Mandatory = $false,ParameterSetName = "Help")]
    [Alias("h")][switch]$Help    
)
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
    $Resultados = @{}  #hashtable clave|valor
    $archivosCSV = Get-ChildItem -Path $RutaCSV -Filter *.csv -File
    #Agrego otra validación para que no haya doble Extensión
    $archivosCSV = $archivosCSV | Where-Object { $_.Name -match '\.csv$' }

    if ($archivosCSV.Count -eq 0) {
        Write-Output "No se encontraron archivos CSV en el directorio especificado."
        exit 1
    }

    foreach ($CSV in $archivosCSV) {
        $Datos = Import-Csv -Path $CSV.FullName -Delimiter ',' -Header 'ID','Fecha','Hora','Direccion','Temperatura'
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

ProcesarCSV -RutaCSV $Directorio -ArchivoSalida $Archivo -Pantalla:$Pantalla
exit 0