# Gestor de Certificados — instaladores

Este repositorio solo contiene los instaladores de Windows del Gestor de
Certificados. El código fuente está en un repositorio privado.

## Instalar (recomendado): una línea en PowerShell

Abre PowerShell (menú Inicio → escribe «PowerShell») y pega:

```powershell
irm https://raw.githubusercontent.com/jotaa97/gestor-certificados-releases/main/instalar.ps1 | iex
```

Descarga la última versión, la instala solo para tu usuario (sin
administrador), crea los accesos directos y abre la aplicación. Después se
actualiza sola. Sirve también para reinstalar o reparar.

## Otras formas

- `GestorCertificados-<versión>-win.zip` (en **Releases**): versión portable.
  Extraer y ejecutar `Gestor de Certificados.exe`.
- `GestorCertificados-Setup-<versión>.exe`: instalador clásico. Antes de
  ejecutarlo, botón derecho → Propiedades → «Desbloquear»; Windows avisará de
  editor desconocido porque no va firmado.
