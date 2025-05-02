

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

.PARAMETER help
    Muestra esta ayuda.

.NOTES
    El parámetro -k o --kill se debe utilizar únicamente junto con -d o --directorio
    

.EXAMPLE

    .\ejercicio4.ps1 -directorio ./descargas -salida ./backup -cantidad 3 -kill
    .\ejercicio4.ps1 -directorio ./descargas -salida ./backup -cantidad 3 
    .\ejercicio4.ps1 -directorio ./descargas2 -salida ./backup -cantidad 5 -kill

#>
param(
    [Alias("directorio")][string]$directorioPS,
    [Alias("salida")][string]$salidaPS,
    [Alias("kill")][switch]$killPS,
    [Alias("help")][switch]$helpPS,
    [Alias("cantidad")][System.int32]$cantidadPS
)
$global:ordenados = 0 #Necesito que sea global para que contemple los archivos ordenados en el barrido inicial del daemon

function ValidarParametros {
    param(
        [string]$directorio,
        [string]$salida,
        [System.Boolean]$kill,
        [switch]$help,
        [System.int32]$cantidad
    )

    if (-not (Test-Path $directorio)) {
        Write-Error "El directorio de entrada no existe"
        exit 2
    }

    $directorioAbsoluto = (Resolve-Path $directorio).Path

    # Definimos nombre de job basado en el path absoluto
    $jobName = "${directorioAbsoluto}_job"
    #Para validar si un job ya esta corriendo en el directorio, primero le asignamos nombreDirectorio_job al crearlo, despues lo buscamos y que su estado sea "running"
    $jobExistente = Get-Job -Name $jobName -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' } 
    if ($kill) {
        if ($jobExistente) {
            # Si hay un job corriendo y seleccionamos kill, lo mata y termina
            Write-Host "Finalizando job en ejecución para $directorioAbsoluto"
            Stop-Job -Name $jobName
            Remove-Job -Name $jobName
            Write-Host "Job eliminado correctamente."
            exit 0
        }
        else {
            #Si seleccionamos kill y no hay ningun job activo, termina
            Write-Error "No hay ningún job en ejecución para $directorioAbsoluto"
            exit 3
        }
    }
    # Si ya hay un job corriendo en el directorio y no seleccionamos kill, termina el proceso
    if ($jobExistente) {
        Write-Error "Ya hay un job ejecutándose para el directorio $directorioAbsoluto."
        exit 4
    }

    if (-not (Test-Path $salida) -and (-not $kill)) {
        Write-Error "El directorio de salida no existe"
        exit 5
    }


    if ($kill -and (-not $directorio)) {
        Write-Error "No se puede usar kill sin indicar un directorio"
        exit 6
    }

    if ($cantidad -le 0) {
        Write-Error "La cantidad debe ser un numero entero positivo"
        exit 7
    }
}
function ProcesarArchivo {
    param(
        [string]$rutaArchivo,   
        [string]$directorio,    
        [string]$salida,       
        [int]$cantidad         
    )

    # Obtiene el objeto de archivo a partir de su ruta
    $archivo = Get-Item $rutaArchivo

    # Si no es una carpeta, lo procesa
    if (-not $archivo.PSIsContainer) {
        
        $extension = $archivo.Extension.TrimStart(".")
        $destino = Join-Path -Path $directorio -ChildPath $extension

        # Crea el directorio de la extensión si no existe
        if (-not (Test-Path $destino)) {
            New-Item -ItemType Directory -Path $destino | Out-Null
        }

        # nombre base del archivo
        $nombreBase = [IO.Path]::GetFileNameWithoutExtension($archivo)
        # extension del archivo
        $extension = [IO.Path]::GetExtension($archivo)
        $nombreDestino = Join-Path -Path $destino -ChildPath ($nombreBase + $extension)
        $contador = 1

        # Si ya existe un archivo con ese nombre, le agrega _copy1, _copy2, etc.
        while (Test-Path $nombreDestino) {
            $nombreDestino = Join-Path -Path $destino -ChildPath ("${nombreBase}_copy$contador$extension")
            $contador++
        }
        #Realizo un try-catch por razones de seguridad
        try {
            Move-Item -Path $archivo -Destination $nombreDestino -ErrorAction Stop
        }
        catch {
            return
        }
        # Incrementa el contador global de archivos ordenados
        $global:ordenados++

        # Si se llegó a la cantidad requerida de archivos movidos, se empaqueta todo
        if ($global:ordenados -eq $cantidad) {

            $nombreDir = Split-Path -Path (Get-Location) -Leaf
            $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
            $nombreZip = "${nombreDir}_${fecha}.zip"
            $rutaZip = Join-Path -Path $salida -ChildPath $nombreZip

            # Comprime todo el contenido del directorio en el ZIP
            Compress-Archive -Path "$directorio\*" -DestinationPath $rutaZip -Force

            # Resetea el contador
            $global:ordenados = 0
        }
    }
}

if ($HelpPS) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    exit 0
}

ValidarParametros -directorio $directorioPS -salida $salidaPS -kill  $killPS -cantidad $cantidadPS

# Barrido inicial de los archivos que haya en el directorio. Despues de esto se queda el FSwatcher
$archivosExistentes = Get-ChildItem -Path $directorioPS -File
foreach ($archivo in $archivosExistentes) {
    ProcesarArchivo -rutaArchivo $archivo.FullName -directorio $directorioPS -salida $salidaPS -cantidad $cantidadPS
}

#El nombre del job es la ruta donde se ejecuta y _job
$rutaAbsoluta = (Resolve-Path $directorioPS).Path
$nombreJob = "${rutaAbsoluta}_job"

Write-Host "`nEl proceso se está ejecutando correctamente en segundo plano.`n"

Start-Job -Name "$nombreJob" -ScriptBlock {
    param($directorio, $salida, $cantidad, $ordenados)

    
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Resolve-Path $directorio).Path
    $watcher.Filter = '*'
    $watcher.IncludeSubdirectories = $false
    $watcher.NotifyFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite

    # Variable contador local dentro del job
    $script:contadorOrdenados = $ordenados

    $onChange = {
        $archivo = $Event.SourceEventArgs.FullPath

        if (-not (Test-Path $archivo)) {
            return
        }

        if (-not (Get-Item $archivo).PSIsContainer) {
            $extension = [IO.Path]::GetExtension($archivo).TrimStart(".")
            $destino = Join-Path -Path $directorio -ChildPath $extension

            if (-not (Test-Path $destino)) {
                New-Item -ItemType Directory -Path $destino | Out-Null
            }

            $nombreBase = [IO.Path]::GetFileNameWithoutExtension($archivo)
            $ext = [IO.Path]::GetExtension($archivo)
            $nombreDestino = Join-Path -Path $destino -ChildPath ($nombreBase + $ext)
            $copia = 1

            while (Test-Path $nombreDestino) {
                $nombreDestino = Join-Path -Path $destino -ChildPath ("${nombreBase}_copy$copia$ext")
                $copia++
            }

            try {
                Move-Item -Path $archivo -Destination $nombreDestino -ErrorAction Stop
            }
            catch {
                return
            }

            # Incrementa contador local
            $script:contadorOrdenados++

            if ($script:contadorOrdenados -eq $cantidad) {
                $nombreDir = Split-Path -Path (Get-Location) -Leaf
                $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
                $nombreZip = "${nombreDir}_${fecha}.zip"
                $rutaZip = Join-Path -Path $salida -ChildPath $nombreZip

                Compress-Archive -Path "$directorio\*" -DestinationPath $rutaZip -Force
                Write-Host "Se creó el zip en $rutaZip"

                $script:contadorOrdenados = 0
            }
        }
    }
     #Los eventos son crear o renombrar un archivo. Cuando movemos un archivo a esta carpeta, vscode/windows generan un movimiento equivalente que puede ser tanto created
    #como renamed, asi que ponemos los dos para que tome todos los casos.
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $onChange
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $onChange

    $watcher.EnableRaisingEvents = $true

    while ($true) {
        Wait-Event -Timeout 1 | Out-Null
    }

} -ArgumentList $directorioPS, $salidaPS, $cantidadPS, $global:ordenados | Out-Null


