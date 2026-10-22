# Instala o actualiza el Gestor de Certificados en el usuario actual, sin
# administrador y sin pasar por el instalador .exe. Uso (en PowerShell):
#
#   irm https://raw.githubusercontent.com/jotaa97/gestor-certificados-releases/main/instalar.ps1 | iex
#
# Que hace: lee la ultima release publica, descarga el ZIP portable, lo
# extrae en %LOCALAPPDATA%\Programs\Gestor de Certificados, crea accesos
# directos en el escritorio y el menu de inicio y abre la aplicacion. Despues
# la aplicacion se actualiza sola desde ese mismo repositorio.
#
# La propia aplicacion lo lanza tambien (copia en resources\instalar.ps1)
# cuando una actualizacion descargada no llego a instalarse al cerrar
# (2026-10-22). Entonces llega GESTOR_DESTINO con la carpeta donde vive la
# aplicacion, que puede no ser la de por defecto.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = 'jotaa97/gestor-certificados-releases'
$porDefecto = Join-Path $env:LOCALAPPDATA 'Programs\Gestor de Certificados'
$destino = if ($env:GESTOR_DESTINO) { $env:GESTOR_DESTINO.TrimEnd('\') } else { $porDefecto }
$esPorDefecto = ($destino -ieq $porDefecto)
$exe = Join-Path $destino 'Gestor de Certificados.exe'

Write-Host 'Gestor de Certificados: buscando la ultima version...'
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'gestor-certificados-instalador' }
$zip = $release.assets | Where-Object { $_.name -like 'GestorCertificados-*-win.zip' } | Select-Object -First 1
if (-not $zip) { throw 'La ultima release no tiene el ZIP de Windows.' }
$version = $release.tag_name.TrimStart('v')
Write-Host "Version $version ($([math]::Round($zip.size / 1MB)) MB)"

$temporal = Join-Path $env:TEMP ("gestor-certificados-" + [guid]::NewGuid().ToString('N') + '.zip')
Write-Host 'Descargando...'
Invoke-WebRequest -Uri $zip.browser_download_url -OutFile $temporal -UseBasicParsing
Unblock-File -Path $temporal -ErrorAction SilentlyContinue

# Si la aplicacion esta abierta se cierra: no se pueden sustituir sus ficheros.
# Solo la de ESTA carpeta (otra copia, la de pruebas por ejemplo, se queda), y
# primero por las buenas: cerrar la ventana hace que la aplicacion guarde sus
# datos antes de salir. Solo si no sale en 20 s se fuerza.
$abiertos = @(Get-Process -Name 'Gestor de Certificados' -ErrorAction SilentlyContinue |
  Where-Object { $_.Path -and $_.Path.StartsWith($destino + '\', [StringComparison]::OrdinalIgnoreCase) })
if ($abiertos.Count -gt 0) {
  Write-Host 'Cerrando la aplicacion...'
  foreach ($p in $abiertos) { try { [void]$p.CloseMainWindow() } catch { } }
  $limite = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $limite -and @($abiertos | Where-Object { -not $_.HasExited }).Count -gt 0) {
    Start-Sleep -Milliseconds 500
    foreach ($p in $abiertos) { try { $p.Refresh() } catch { } }
  }
  $abiertos | Where-Object { -not $_.HasExited } | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
}

Write-Host "Instalando en $destino ..."
New-Item -ItemType Directory -Force -Path $destino | Out-Null
Expand-Archive -LiteralPath $temporal -DestinationPath $destino -Force
Remove-Item -LiteralPath $temporal -Force -ErrorAction SilentlyContinue
if (-not (Test-Path $exe)) { throw "No se encuentra $exe tras extraer el ZIP." }

# Accesos directos y entrada de «Aplicaciones instaladas»: solo en la carpeta
# de siempre. Si la aplicacion vive en otra (instalada con el .exe en una
# carpeta elegida), ya tiene los suyos y no se tocan.
if ($esPorDefecto) {
# Accesos directos (escritorio y menu de inicio). Son ficheros del usuario,
# no hace falta administrador.
$escritorio = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Gestor de Certificados.lnk'
$menu = Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\Gestor de Certificados.lnk'
$shell = New-Object -ComObject WScript.Shell
foreach ($ruta in @($escritorio, $menu)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $ruta) | Out-Null
  $acceso = $shell.CreateShortcut($ruta)
  $acceso.TargetPath = $exe
  $acceso.WorkingDirectory = $destino
  $acceso.Description = 'Gestor de Certificados'
  $acceso.Save()
}

# Entrada en "Aplicaciones instaladas" para poder desinstalar desde Windows.
$clave = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GestorCertificados'
New-Item -Path $clave -Force | Out-Null
Set-ItemProperty -Path $clave -Name 'DisplayName' -Value 'Gestor de Certificados'
Set-ItemProperty -Path $clave -Name 'DisplayVersion' -Value $version
Set-ItemProperty -Path $clave -Name 'InstallLocation' -Value $destino
Set-ItemProperty -Path $clave -Name 'DisplayIcon' -Value $exe
Set-ItemProperty -Path $clave -Name 'NoModify' -Value 1 -Type DWord
Set-ItemProperty -Path $clave -Name 'NoRepair' -Value 1 -Type DWord
$desinstalar = "powershell -NoProfile -Command `"Get-Process -Name 'Gestor de Certificados' -ErrorAction SilentlyContinue | Stop-Process -Force; Remove-Item -Recurse -Force '$destino'; Remove-Item -Force '$escritorio','$menu' -ErrorAction SilentlyContinue; Remove-Item -Path '$clave' -Recurse -Force`""
Set-ItemProperty -Path $clave -Name 'UninstallString' -Value $desinstalar
}

Write-Host 'Abriendo la aplicacion...'
Start-Process -FilePath $exe -WorkingDirectory $destino
Write-Host 'Listo. La aplicacion se actualizara sola a partir de ahora.'
