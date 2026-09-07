#!/usr/bin/env bash
# Layout de duas colunas.  cv.md -> resume/cv-2col.pdf
# Requer apenas pandoc (brew install pandoc). O PDF sai do Chrome instalado.
set -e

OUT_DIR="resume"
OUT_PDF="$OUT_DIR/cv-2col.pdf"
TEMPLATE="template-2col.html"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || CHROME="/Applications/Chromium.app/Contents/MacOS/Chromium"
[ -x "$CHROME" ] || CHROME="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
[ -x "$CHROME" ] || { echo "ERRO: navegador nao encontrado. Ajuste a variavel CHROME."; exit 1; }

# HTML e apenas intermediario: vive num diretorio temporario e e apagado no fim.
TMP="$(mktemp -d)"
PROFILE="$(mktemp -d)"
trap 'rm -rf "$TMP" "$PROFILE"' EXIT

mkdir -p "$OUT_DIR"
rm -f cv-2col.html                      # limpa HTML de versoes antigas do script

echo "1/2 pandoc"
pandoc cv.md -f markdown -t html5 --template="$TEMPLATE" --lua-filter=filter-2col.lua -o "$TMP/cv.html"

echo "2/2 chrome"
rm -f "$OUT_PDF"
"$CHROME" --headless --disable-gpu --user-data-dir="$PROFILE" \
  --no-pdf-header-footer --print-to-pdf="$PWD/$OUT_PDF" "file://$TMP/cv.html"

[ -f "$OUT_PDF" ] || { echo "ERRO: PDF nao gerado. Veja a mensagem acima."; exit 1; }
echo "OK -> $PWD/$OUT_PDF"
