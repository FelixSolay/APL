$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "/home/agus/APL/powershell/ejercicio4"
$watcher.Filter = "*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
    Write-Host "Archivo creado: $($Event.SourceEventArgs.FullPath)"
}

while ($true) {
    Wait-Event -Timeout 1 | Out-Null
}