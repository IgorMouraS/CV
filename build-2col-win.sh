#!/usr/bin/env bash

# ==========================================
# BUILD CV 2 COLUNAS - WINDOWS / GIT BASH
# ==========================================
#
# Converte: cv.md -> cv-2col.pdf
# Utiliza template-2col-win.html e filter-2col-win.lua
#
# Requisitos:
# - Windows com Git Bash
# - Pandoc
# - Microsoft Edge
# - Windows PowerShell
#
# Saida: cv-2col.pdf na mesma pasta deste script

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INPUT_MD="$SCRIPT_DIR/cv.md"
OUT_PDF="$SCRIPT_DIR/cv-2col.pdf"
TEMPLATE="$SCRIPT_DIR/template-2col-win.html"
LUA_FILTER="$SCRIPT_DIR/filter-2col-win.lua"
LOG_FILE="$SCRIPT_DIR/edge-2col-debug.log"

EDGE="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
if [ ! -f "$EDGE" ]; then
    EDGE="/c/Program Files/Microsoft/Edge/Application/msedge.exe"
fi


if [ ! -f "$EDGE" ]; then
    echo "ERRO: Microsoft Edge nao encontrado."
    exit 1
fi

if ! command -v pandoc >/dev/null 2>&1; then
    echo "ERRO: Pandoc nao encontrado."
    exit 1
fi

if ! command -v powershell.exe >/dev/null 2>&1; then
    echo "ERRO: PowerShell nao encontrado."
    exit 1
fi

for file in "$INPUT_MD" "$TEMPLATE" "$LUA_FILTER"; do
    if [ ! -f "$file" ]; then
        echo "ERRO: Arquivo nao encontrado: $file"
        exit 1
    fi
done


HTML_FILE="$(mktemp "$SCRIPT_DIR/.cv-2col-build.XXXXXXXX.html")"
PROFILE="$(mktemp -d)"

cleanup() {
    local exit_code=$?

    rm -f "$HTML_FILE" || true

    for i in {1..10}; do
        if rm -rf "$PROFILE" 2>/dev/null; then
            break
        fi
        sleep 1
    done

    return "$exit_code"
}
trap cleanup EXIT

echo "=========================================="
echo "BUILD CV - 2 COLUNAS"
echo "=========================================="
echo
echo "1/2 - Gerando HTML com Pandoc..."

pandoc cv.md \
    -f markdown \
    -t html5 \
    --template="template-2col-win.html" \
    --lua-filter="filter-2col-win.lua" \
    -o "$HTML_FILE"

if [ ! -s "$HTML_FILE" ]; then
    echo "ERRO: HTML nao foi gerado."
    exit 1
fi

echo "HTML gerado com sucesso."


export CV_EDGE_WIN="$(cygpath -w "$EDGE")"
export CV_HTML_WIN="$(cygpath -w "$HTML_FILE")"
export CV_PDF_WIN="$(cygpath -w "$OUT_PDF")"
export CV_PROFILE_WIN="$(cygpath -w "$PROFILE")"

echo
echo "Configuracoes:"
echo "Navegador: $CV_EDGE_WIN"
echo "HTML: $CV_HTML_WIN"
echo "Destino: $CV_PDF_WIN"


echo
echo "2/2 - Gerando PDF com Microsoft Edge..."

rm -f "$OUT_PDF"
: > "$LOG_FILE"

if ! MSYS_NO_PATHCONV=1 powershell.exe \
    -NoProfile \
    -NonInteractive \
    -ExecutionPolicy Bypass \
    -Command '
        $ErrorActionPreference = "Stop"

        $edge = $env:CV_EDGE_WIN
        $html = $env:CV_HTML_WIN
        $pdf = $env:CV_PDF_WIN
        $profileDir = $env:CV_PROFILE_WIN

        $url = ([System.Uri]::new($html)).AbsoluteUri

        Write-Host "Iniciando Microsoft Edge..."
        Write-Host "HTML: $url"
        Write-Host "PDF: $pdf"

        & $edge `
            --headless `
            --disable-gpu `
            "--user-data-dir=$profileDir" `
            "--print-to-pdf=$pdf" `
            --no-pdf-header-footer `
            "$url"

        Write-Host "Aguardando geracao do PDF..."

        $maxAttempts = 60
        $pdfGenerated = $false

        for ($i = 0; $i -lt $maxAttempts; $i++) {
            if (Test-Path -LiteralPath $pdf) {
                $file = Get-Item -LiteralPath $pdf

                if ($file.Length -gt 0) {
                    $sizeBefore = $file.Length
                    Start-Sleep -Milliseconds 500
                    $file = Get-Item -LiteralPath $pdf
                    $sizeAfter = $file.Length

                    if ($sizeBefore -eq $sizeAfter -and $sizeAfter -gt 0) {
                        $pdfGenerated = $true
                        Write-Host "PDF encontrado!"
                        Write-Host "Tamanho: $sizeAfter bytes"
                        break
                    }
                }
            }
            Start-Sleep -Milliseconds 500
        }

        if (-not $pdfGenerated) {
            throw "O Edge nao gerou o PDF."
        }

        Start-Sleep -Seconds 1
        Write-Host "PDF gerado com sucesso!"
        exit 0
    ' > "$LOG_FILE" 2>&1; then

    echo
    echo "=========================================="
    echo "ERRO: Falha na geracao do PDF."
    echo "=========================================="
    echo
    echo "Log do Microsoft Edge:"
    cat "$LOG_FILE"
    exit 1
fi


if [ ! -s "$OUT_PDF" ]; then
    echo "ERRO: PDF nao encontrado ou vazio."
    echo "Destino esperado: $OUT_PDF"
    cat "$LOG_FILE"
    exit 1
fi

echo
echo "=========================================="
echo "PDF GERADO COM SUCESSO!"
echo "=========================================="
echo
echo "Arquivo: $OUT_PDF"
echo
echo "Log:"
cat "$LOG_FILE"
