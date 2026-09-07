#!/usr/bin/env bash
# Gera cv.pdf a partir de cv.md   ->   ./build.sh
# Requer apenas pandoc (brew install pandoc). O PDF sai do Chrome ja instalado.
set -e

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || CHROME="/Applications/Chromium.app/Contents/MacOS/Chromium"
[ -x "$CHROME" ] || CHROME="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
[ -x "$CHROME" ] || { echo "ERRO: navegador nao encontrado. Ajuste a variavel CHROME."; exit 1; }

echo "1/2 pandoc: cv.md -> cv.html"
pandoc cv.md -f markdown -t html5 --template=template.html -o cv.html

echo "2/2 chrome: cv.html -> cv.pdf"
rm -f cv.pdf
# --user-data-dir e obrigatorio: sem ele, com o Chrome aberto o headless
# anexa a instancia existente e sai sem gerar nada.
PROFILE="$(mktemp -d)"
"$CHROME" --headless --disable-gpu --user-data-dir="$PROFILE" \
  --no-pdf-header-footer --print-to-pdf="$PWD/cv.pdf" "file://$PWD/cv.html"
rm -rf "$PROFILE"

if [ -f cv.pdf ]; then echo "OK -> $PWD/cv.pdf"; else echo "ERRO: cv.pdf nao gerado."; exit 1; fi
