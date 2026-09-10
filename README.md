# Gestor de Certificados — instaladores

Este repositorio solo contiene los instaladores de Windows y macOS del Gestor
de Certificados. El código fuente está en un repositorio privado.

## Instalar (recomendado): una línea en PowerShell

Abre PowerShell (menú Inicio → escribe «PowerShell») y pega:

```powershell
irm https://raw.githubusercontent.com/jotaa97/gestor-certificados-releases/main/instalar.ps1 | iex
```

Descarga la última versión, la instala solo para tu usuario (sin
administrador), crea los accesos directos y abre la aplicación. Después se
actualiza sola. Sirve también para reinstalar o reparar.

## Instalar en un Mac: una línea en Terminal

Abre Terminal (Spotlight → escribe «Terminal») y pega:

```bash
curl -fsSL https://raw.githubusercontent.com/jotaa97/gestor-certificados-releases/main/instalar-mac.sh | bash
```

Elige sola la versión del chip del Mac (Apple o Intel), la instala en
Aplicaciones y la abre. Así no hay bloqueo de Gatekeeper: la aplicación no
lleva firma de Apple, y un ZIP bajado con el navegador sí lo bloquearía. Para
actualizar: Ajustes → Actualizaciones → «Actualizar ahora», o volver a pegar
la misma línea.

## Otras formas (Windows)

- `GestorCertificados-<versión>-win.zip` (en **Releases**): versión portable.
  Extraer y ejecutar `Gestor de Certificados.exe`.
- `GestorCertificados-Setup-<versión>.exe`: instalador clásico. Antes de
  ejecutarlo, botón derecho → Propiedades → «Desbloquear»; Windows avisará de
  editor desconocido porque no va firmado.
