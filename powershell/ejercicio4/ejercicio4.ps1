param(
    [Alias("d")][string]$directorio,
    [Alias("s")][string]$salida,
    [Alias("k")][switch]$kill,
    [Alias("h")][switch]$help,
    [Alias("c")][int]$cantidad
)

<#
.SYNOPSIS
    Script del ejercicio 4 de la APL 1.

.DESCRIPTION
    Demonio que detecta cada vez que un archivo nuevo aparece en un directorio
    “descargas”. Una vez detectado, se mueve a un subdirectorio “extensión” cuyo nombre será la
    extensión del archivo y que estará localizado en un directorio “destino”
    Además cada cierta cantidad de archivos realizará un backup con el nobre del directorio respaldado
    junto con la fecha y hora (yyyyMMdd-HHmmss), 
    Ejemplo: descargas_20250401_212121.zip.

.PARAMETER directorio
    Ruta del directorio a monitorear

.PARAMETER salida
    Ruta del directorio en donde se van a crear los backups

.PARAMETER kill
    Flag que indica que el script debe detener el demonio iniciado

.PARAMETER cantidad
    cantidad de archivos a ordenar antes de generar un backup

.PARAMETER Help
    Muestra esta ayuda.

.NOTES
    El parámetro -k o --kill se debe utilizar únicamente junto con -d o --directorio
    

.EXAMPLE
    .\ejercicio4.ps1 -d ./descargas -s ./backup -c 4


#>
$global:ordenados = 0
function ProcesarArchivo {
    param(
        [string]$rutaArchivo,
        [string]$directorio,
        [string]$salida,
        [int]$cantidad
    )

    $archivo = Get-Item $rutaArchivo

    if (-not $archivo.PSIsContainer) {
        $extension = $archivo.Extension.TrimStart(".")
        $destino = Join-Path -Path $directorio -ChildPath $extension

        if (-not (Test-Path $destino)) {
            New-Item -ItemType Directory -Path $destino | Out-Null
        }

        $nombreArchivo = $archivo.Name
        $nombreDestino = Join-Path -Path $destino -ChildPath $nombreArchivo

        #El archivo puede existir desde antes, asi que le ponemos un copy adelante para evitar problemas.
        while (Test-Path $nombreDestino) {
            $nombreArchivo = "copy$nombreArchivo"
            $nombreDestino = Join-Path -Path $destino -ChildPath $nombreArchivo
        }

        Move-Item -Path $archivo.FullName -Destination $nombreDestino

        $global:ordenados++

        if ($global:ordenados -eq $cantidad) {
            $nombreDir = Split-Path -Path (Get-Location) -Leaf
            $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
            $nombreZip = "${nombreDir}_${fecha}.zip"
            $rutaZip = Join-Path -Path $salida -ChildPath $nombreZip

            Compress-Archive -Path "$directorio\*" -DestinationPath $rutaZip -Force

            $global:ordenados = 0
        }
    }
}

function ValidarParametros {
    param(
        [string]$directorio,
        [string]$salida,
        [System.Boolean]$kill,
        [switch]$help,
        [int]$cantidad
    )

    if (-not (Test-Path $directorio)) {
        Write-Error "El directorio de entrada no existe"
        exit 2
    }

    if (-not (Test-Path $salida)) {
        Write-Error "El directorio de salida no existe"
        exit 3
    }

    if(-not $cantidad){
        Write-Error "No fue indicada la cantidad de archivos para realizar backup"
        exit 4
    }

    if ($kill -and (-not $directorio)) {
        Write-Error "No se puede usar kill sin indicar un directorio"
        exit 5
    }

    if($cantidad -le 0)
    {
        Write-Error "La cantidad debe ser un numero entero positivo"
        exit 6
    }

    $directorioAbsoluto = (Resolve-Path $directorio).Path

    # Definimos nombre de job basado en el path absoluto
    $jobName = "${directorioAbsoluto}_job"
    $jobExistente = Get-Job -Name $jobName -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' }
    if ($kill) {
        if ($jobExistente) {
            # Si hay un job corriendo, eliminarlo
            Write-Host "Finalizando job en ejecución para $directorioAbsoluto..."
            Stop-Job -Name $jobName
            Remove-Job -Name $jobName
            Write-Host "Job eliminado correctamente."
            exit 0
        }
        else {
            Write-Host "No hay ningún job en ejecución para $directorioAbsoluto."
            exit 0
        }
    }
    # Validar si ya existe un job con ese nombre
    if ($jobExistente) {
        Write-Host "Ya hay un job ejecutándose para el directorio $directorioAbsoluto."
        exit
    }
    
}

if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}



function MatarProcesos {
    param(
        [string]$kill,
        [string]$directorio
    )

    if ($kill -eq "true") {
        # Obtiene todos los procesos con su PID y directorio de trabajo
        Get-Process | ForEach-Object {
            try {
                # Obtiene el directorio actual del proceso desde Win32_Process (en Windows no existe /proc)
                $proc = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)"
                $cwd = $proc.ExecutablePath

                # Si se pudo obtener la ruta (algunos procesos pueden no tenerla)
                if ($cwd) {
                    $dir = Split-Path $cwd -Parent
                    # Compara con el directorio buscado
                    if ($dir -eq $directorio -and $_.Id -ne $PID) {
                        Write-Output "Matando proceso $($_.Id) en $dir"
                        Stop-Process -Id $_.Id -Force
                    }
                }
            } catch {
                # Algunos procesos pueden no permitir acceso
                Write-Verbose "No se pudo acceder al proceso $($_.Id)"
            }
        }

        exit 0
    }
}
ValidarParametros -directorio $directorio -salida $salida -kill  $kill -cantidad $cantidad

$global:directorio = $directorio
$global:salida = $salida
$global:cantidad = $cantidad

# Barrido inicial de los archivos que haya en el directorio. Despues de esto se queda el FSwatcher
$archivosExistentes = Get-ChildItem -Path $directorio -File
foreach ($archivo in $archivosExistentes) {
    ProcesarArchivo -rutaArchivo $archivo.FullName -directorio $directorio -salida $salida -cantidad $cantidad
}
$rutaAbsoluta = (Resolve-Path $directorio).Path
$nombreJob = "${rutaAbsoluta}_job"

$job = Start-Job -Name "$nombreJob" -ScriptBlock {
    param($directorio, $salida, $cantidad)

    # Variables dentro del job (propias de su scope)
    $global:directorio = $directorio
    $global:salida = $salida
    $global:cantidad = $cantidad
    $global:ordenados = 0

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Resolve-Path $directorio).Path
$watcher.Filter = '*' 
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite


# Cada vez que los register detecten algo, va a ejecutar este bloque de codigo
$onChange = {
    Write-Host "Evento detectado: $($Event.SourceEventArgs.ChangeType) - $($Event.SourceEventArgs.FullPath)"
    
    $archivo = $Event.SourceEventArgs.FullPath
    if (-not (Test-Path $archivo)) {
        #Write-Host "El archivo $archivo no existe. Cancelando procesamiento."
        return
    }
     Write-Host ""
    # Write-Host "Adentro del registro del archivo::::::::::::::::::::::::::"
    # Write-Host "Archivo: $archivo"
    # Write-Host "Directorio: $global:directorio"
    # Write-Host "Salida: $global:salida"
    # Write-Host "Cantidad: $global:cantidad"
    if (-not $archivo.PSIsContainer) {
    $extension = [IO.Path]::GetExtension($archivo).TrimStart(".")
    $destino = Join-Path -Path $global:directorio -ChildPath $extension

    if (-not (Test-Path $destino)) {
        New-Item -ItemType Directory -Path $destino | Out-Null
    }

        $nombreBase = [IO.Path]::GetFileNameWithoutExtension($archivo)
    $extension = [IO.Path]::GetExtension($archivo)
    $nombreDestino = Join-Path -Path $destino -ChildPath ($nombreBase + $extension)
    $contador = 1

    while (Test-Path $nombreDestino) {
        $nombreDestino = Join-Path -Path $destino -ChildPath ("${nombreBase}_copy$contador$extension")
        $contador++
    }

    try {
        Move-Item -Path $archivo -Destination $nombreDestino -ErrorAction Stop
        Write-Host "Archivo movido a $nombreDestino"
    }
    catch {
        Write-Host "No se pudo mover $archivo"
        return
}
    $global:ordenados++

    if ($global:ordenados -eq $global:cantidad) {
        $nombreDir = Split-Path -Path (Get-Location) -Leaf
        $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
        $nombreZip = "${nombreDir}_${fecha}.zip"
        $rutaZip = Join-Path -Path $global:salida -ChildPath $nombreZip

        Compress-Archive -Path "$global:directorio\*" -DestinationPath $rutaZip -Force
        Write-Host "Se creó el zip en $rutaZip"

        $global:ordenados = 0
    }}
}

#Los eventos son crear, cambiar o renombrar un archivo. Cuando movemos un archivo a esta carpeta, vscode/windows generan un movimiento equivalente que puede ser tanto created
#como renamed, asi que ponemos los dos para que tome todos los casos.


Register-ObjectEvent -InputObject $watcher -EventName Created -Action $onChange
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $onChange
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $onChange
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $onChange

# Activar watcher
try{
$watcher.EnableRaisingEvents = $true
# Write-Host "Antes de registrar el archivo"
# Write-Host "Archivo: $archivo"
# Write-Host "Directorio: $global:directorio"
# Write-Host "Salida: $global:salida"
# Write-Host "Cantidad: $global:cantidad"

# Mensaje para confirmar que está en espera
Write-Host "Vigilando $directorio..."

# Mantener el script en espera (como un daemon)
while ($true) {
    Wait-Event -Timeout 1 | Out-Null
}
}
finally{
    Write-Host "`nLiberando subscriptores..."
    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } | Unregister-Event
}} -ArgumentList $global:directorio, $global:salida, $global:cantidad
