#!/bin/bash
# Instala o actualiza el Gestor de Certificados en macOS, sin administrador y
# sin pasar por el navegador. Uso (en Terminal):
#
#   curl -fsSL https://raw.githubusercontent.com/jotaa97/gestor-certificados-releases/main/instalar-mac.sh | bash
#
# Que hace: lee la ultima release publica, descarga el ZIP de macOS de la
# arquitectura del Mac (chip de Apple o Intel), lo extrae en /Aplicaciones (o
# en ~/Aplicaciones si no se puede escribir alli) y abre la aplicacion.
#
# Por que asi: la aplicacion no lleva firma de Apple. Lo que se baja con el
# navegador queda marcado "de internet" y Gatekeeper lo bloquea; lo que baja
# curl no lleva esa marca, igual que el instalador de PowerShell evita
# SmartScreen en Windows.
#
# La propia aplicacion reutiliza este guion para actualizarse (lleva una
# copia en Contents/Resources). Variables que usa entonces:
#   GESTOR_DESTINO   carpeta donde esta instalada (por defecto, la de arriba)
#   GESTOR_VERSION   version concreta a instalar (por defecto, la ultima)
#
# Todo va dentro de main(): con `curl | bash`, bash lee el guion entero antes
# de ejecutar nada, y una descarga cortada no ejecuta medio guion.

set -euo pipefail

REPO='jotaa97/gestor-certificados-releases'
APP='Gestor de Certificados'
# macOS recorta el nombre de proceso a 16 caracteres, asi que `pgrep -x` con
# el nombre completo no encuentra nada. Se busca por la ruta del ejecutable
# principal, que no coincide con la de los "Helper" de Electron.
PROCESO="$APP\\.app/Contents/MacOS/$APP( |\$)"

fallo() {
  echo "Error: $*" >&2
  exit 1
}

main() {
  [[ "$(uname -s)" == 'Darwin' ]] || fallo 'este instalador es para macOS. En Windows, usar instalar.ps1.'

  # Arquitectura real: una Terminal abierta con Rosetta dice x86_64 en un Mac
  # con chip de Apple.
  local arch
  if [[ "$(uname -m)" == 'arm64' || "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" == '1' ]]; then
    arch='arm64'
  else
    arch='x64'
  fi

  local destino
  if [[ -n "${GESTOR_DESTINO:-}" ]]; then
    destino="$GESTOR_DESTINO"
  elif [[ -w /Applications ]]; then
    destino='/Applications'
  else
    destino="$HOME/Applications"
  fi

  echo 'Gestor de Certificados: buscando la ultima version...'
  local api
  if [[ -n "${GESTOR_VERSION:-}" ]]; then
    api="https://api.github.com/repos/$REPO/releases/tags/v${GESTOR_VERSION#v}"
  else
    api="https://api.github.com/repos/$REPO/releases/latest"
  fi
  local release
  release="$(curl -fsSL -H 'User-Agent: gestor-certificados-instalador' "$api")" \
    || fallo 'no se pudo consultar la ultima version en GitHub.'

  local version url
  version="$(printf '%s' "$release" | grep -o '"tag_name": *"[^"]*"' | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/' || true)"
  version="${version#v}"
  url="$(printf '%s' "$release" | grep -o "\"browser_download_url\": *\"[^\"]*-mac-${arch}\\.zip\"" | head -n 1 | sed 's/.*"\(https[^"]*\)"$/\1/' || true)"
  if [[ -z "$url" ]]; then
    fallo "la version ${version:-publicada} no tiene todavia el ZIP de macOS ($arch). Si se acaba de publicar, se esta compilando: probar de nuevo en unos minutos."
  fi
  if [[ "$arch" == 'arm64' ]]; then
    echo "Version $version para Mac con chip de Apple"
  else
    echo "Version $version para Mac con chip Intel"
  fi

  local temporal
  temporal="$(mktemp -d -t gestor-certificados)"
  # shellcheck disable=SC2064
  trap "rm -rf '$temporal'" EXIT

  echo 'Descargando...'
  curl -fL --progress-bar -o "$temporal/app.zip" "$url" || fallo 'la descarga no se completo.'
  ditto -x -k "$temporal/app.zip" "$temporal/extraido" || fallo 'no se pudo descomprimir el ZIP.'
  [[ -d "$temporal/extraido/$APP.app" ]] || fallo "el ZIP no contiene $APP.app."

  # Si la aplicacion esta abierta se cierra con SIGTERM, que la aplicacion
  # atiende guardando sus datos antes de salir (main.js). Si no ha salido en
  # 30 s, se fuerza. No se pueden sustituir sus ficheros mientras corre.
  if pgrep -f "$PROCESO" >/dev/null; then
    echo 'Cerrando la aplicacion...'
    pkill -TERM -f "$PROCESO" 2>/dev/null || true
    local i
    for i in $(seq 1 30); do
      pgrep -f "$PROCESO" >/dev/null || break
      sleep 1
    done
    if pgrep -f "$PROCESO" >/dev/null; then
      pkill -KILL -f "$PROCESO" 2>/dev/null || true
      sleep 1
    fi
  fi

  echo "Instalando en $destino ..."
  mkdir -p "$destino"
  rm -rf "$destino/$APP.app"
  ditto "$temporal/extraido/$APP.app" "$destino/$APP.app"
  # Por si acaso: curl no pone la marca de cuarentena, pero si alguien bajo el
  # ZIP con el navegador y lo paso por aqui, se quita.
  xattr -dr com.apple.quarantine "$destino/$APP.app" 2>/dev/null || true

  echo 'Abriendo la aplicacion...'
  open "$destino/$APP.app"
  echo 'Listo. La aplicacion avisara cuando haya una version nueva.'
}

main "$@"
