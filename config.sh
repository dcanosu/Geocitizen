#!/bin/bash
set -e

echo "➡️  Configurando idioma y teclado a español - Latinoamérica"
sudo apt install -y console-data

sudo loadkeys la-latin1

sudo localectl set-keymap la-latin1
sudo localectl set-x11-keymap latam

echo "✅ Configuración regional aplicada"
