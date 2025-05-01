param(
    [Alias("d")][string]$Directorio,
    [Alias("s")][string]$Salida,
    [Alias("k")][bool]$kill,
    [Alias("h")][switch]$help,
    [Alias("c")][int]$cantidad
)
<#
.SYNOPSIS
    Script del ejercicio 2 de la APL 1.

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
    .\ejercicio1.ps1 -Directorio .\pruebas_normales.csv -Archivo .\salida.json

.EXAMPLE
    .\ejercicio1.ps1 -d .\entrada.csv -p
#>


function ejecutarDaemon()
{Validar-Parametros -directorio $directorio -salida $salida -kill  $kill -cantidad $cantidad
$IncludeSubfolders = $false
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Resolve-Path $Directorio).Path
$watcher.Filter = '*' 
$watcher.IncludeSubdirectories = $IncludeSubfolders
$watcher.NotifyFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite

# Cada vez que los register detecten algo, va a ejecutar este bloque de codigo
$onChange = {
    $archivo = Get-Item $Event.SourceEventArgs.FullPath

    # Si no es un archivo, salir
    if (-not $archivo.PSIsContainer) {
        $extension = $archivo.Extension.TrimStart(".")

        # Crear carpeta para la extensión si no existe
        $destino = Join-Path -Path $directorio -ChildPath $extension
        if (-not (Test-Path $destino)) {
            New-Item -ItemType Directory -Path $destino | Out-Null
        }

        # Mover archivo al directorio correspondiente
        Move-Item -Path $archivo.FullName -Destination $destino

        # Incrementar contador global
        $global:cantidadArchivosOrdenados++

        # Si se llegó a la cantidad límite, hacer backup
        if ($global:cantidadArchivosOrdenados -eq $cantidad) {
            $nombreDir = Split-Path -Path (Get-Location) -Leaf
            $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
            $nombreZip = "${nombreDir}_${fecha}.zip"
            $rutaZip = Join-Path -Path $salida -ChildPath $nombreZip

            Compress-Archive -Path "$directorio\*" -DestinationPath $rutaZip -Force

            # Reiniciar contador
            $global:cantidadArchivosOrdenados = 0
        }
    }
}

#Los eventos son crear, cambiar o renombrar un archivo. Cuando movemos un archivo a esta carpeta, vscode/windows generan un movimiento equivalente que puede ser tanto created
#como renamed, asi que ponemos los dos para que tome todos los casos.
Register-ObjectEvent $watcher Created -Action $onChange
Register-ObjectEvent $watcher Changed -Action $onChange
Register-ObjectEvent $watcher Renamed -Action $onChange

# Activar watcher
$watcher.EnableRaisingEvents = $true

# Mensaje para confirmar que está en espera
Write-Host "Vigilando $Directorio... presioná Ctrl+C para cortar."

# Mantener el script en espera (como un daemon)
while ($true) { Start-Sleep -Seconds 1 }}

function Validar-Parametros {
    param(
        [string]$directorio,
        [string]$salida,
        [bool]$kill,
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

    if($cantidad -lt 0)
    {
        Write-Error "La cantidad debe ser un numero entero positivo"
        exit 6
    }
    
}

if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}



function Matar-Procesos {
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

# Listar solo archivos (sin subcarpetas)
$archivos = Get-ChildItem -Path $directorio -File ##

foreach ($archivo in $archivos) {
    $extension = $archivo.Extension.TrimStart(".")  # sin el punto

    # Crear carpeta de la extensión si no existe
    $destino = Join-Path -Path $directorio -ChildPath $extension
    if (-not (Test-Path $destino)) {
        New-Item -ItemType Directory -Path $destino | Out-Null
    }

    # Mover archivo al directorio correspondiente
    Move-Item -Path $archivo.FullName -Destination $destino

    # Incrementar contador
    $cantidadArchivosOrdenados++

    # Si se llegó a la cantidad límite, hacer backup
    if ($cantidadArchivosOrdenados -eq $cantidad) {
        $nombreDir = Split-Path -Path (Get-Location) -Leaf
        $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
        $nombreZip = "${nombreDir}_${fecha}.zip"
        $rutaZip = Join-Path -Path $salida -ChildPath $nombreZip

        # Crear backup comprimido del directorio actual
        Compress-Archive -Path "$directorio\*" -DestinationPath $rutaZip -Force

        # Reiniciar contador
        $cantidadArchivosOrdenados = 0
    }
}


