#!/bin/zsh
# One-time setup on a new machine: Python environment + the Vision OCR helper.
# Safe to re-run; it skips whatever is already in place.
cd "${0:A:h}"
set -e

if [[ ! -x ./venv/bin/python ]]; then
  echo "Creating Python environment..."
  python3 -m venv venv
  ./venv/bin/pip install -q --upgrade pip >/dev/null 2>&1 || true
  ./venv/bin/pip install -q openpyxl pillow
else
  echo "Python environment already present."
fi
./venv/bin/python -c "import openpyxl, PIL" || { echo "dependency install failed"; exit 1; }

if [[ ! -x ./ocr ]]; then
  echo "Building the OCR helper (Apple Vision)..."
  command -v swiftc >/dev/null 2>&1 || {
    echo "swiftc not found. Install Xcode Command Line Tools:  xcode-select --install"; exit 1; }
  swiftc -O -o ocr ocr.swift
else
  echo "OCR helper already built."
fi

chmod +x *.sh 2>/dev/null || true
echo
echo "Setup complete. Next: ./preflight.sh"
