#!/bin/bash

# Script para testar performance das diferentes versões do Tetrimized

set -e

PROJECT_DIR="/home/ley/tetr_io_wrapper"
BACKUP_FILE="$PROJECT_DIR/lib/main_backup.dart"
ORIGINAL_FILE="$PROJECT_DIR/lib/main.dart"
OPTIMIZED_FILE="$PROJECT_DIR/lib/main_optimized.dart"
EXTREME_FILE="$PROJECT_DIR/lib/main_extreme.dart"

DEVICE_ID="0084908847"

echo "================================================"
echo "TESTE DE PERFORMANCE - TETRIMIZED"
echo "Dispositivo: Moto G54 5G ($DEVICE_ID)"
echo "================================================"

# Função para instalar e rodar o app
test_version() {
    local version_name=$1
    local source_file=$2
    
    echo ""
    echo "=== TESTANDO VERSÃO: $version_name ==="
    echo "Copiando $source_file para $ORIGINAL_FILE"
    
    cp "$source_file" "$ORIGINAL_FILE"
    
    # Limpar build anterior
    echo "Limpando build anterior..."
    cd "$PROJECT_DIR" && flutter clean
    
    # Build para Android
    echo "Buildando para Android..."
    cd "$PROJECT_DIR" && flutter build apk --release
    
    # Instalar no dispositivo
    echo "Instalando no dispositivo..."
    adb -s "$DEVICE_ID" install -r "$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    
    echo "App instalado! Por favor teste manualmente:"
    echo "1. Abra o app 'Tetr.io Mobile' no seu dispositivo"
    echo "2. Jogue algumas partidas de Tetr.io"
    echo "3. Observe:"
    echo "   - Micro-stuttering (travamentos curtos)"
    echo "   - Responsividade dos controles"
    echo "   - Aquecimento do dispositivo"
    echo "   - Consumo de bateria"
    echo ""
    echo "Pressione ENTER quando terminar o teste desta versão..."
    read -r
    
    # Desinstalar para próxima versão
    echo "Desinstalando app..."
    adb -s "$DEVICE_ID" uninstall com.example.tetr_io_wrapper
}

# Verificar se o dispositivo está conectado
echo "Verificando dispositivo..."
adb devices | grep "$DEVICE_ID" || {
    echo "ERRO: Dispositivo $DEVICE_ID não encontrado!"
    echo "Certifique-se que:"
    echo "1. O dispositivo está conectado via USB"
    echo "2. A depuração USB está ativada"
    echo "3. O dispositivo está autorizado"
    exit 1
}

# Mostrar informações do dispositivo
echo ""
echo "Informações do dispositivo:"
adb -s "$DEVICE_ID" shell getprop ro.product.model
adb -s "$DEVICE_ID" shell getprop ro.product.manufacturer
adb -s "$DEVICE_ID" shell getprop ro.build.version.release
adb -s "$DEVICE_ID" shell getprop ro.hardware
echo ""

# Menu de seleção
echo "Selecione a versão para testar:"
echo "1. Versão ORIGINAL (atual)"
echo "2. Versão OTIMIZADA (object pooling, cache)"
echo "3. Versão EXTREMA (CustomPainter, minimalista)"
echo "4. Testar TODAS as versões sequencialmente"
echo "5. Restaurar versão original e sair"
echo ""
read -p "Escolha (1-5): " choice

case $choice in
    1)
        test_version "ORIGINAL" "$BACKUP_FILE"
        ;;
    2)
        test_version "OTIMIZADA" "$OPTIMIZED_FILE"
        ;;
    3)
        test_version "EXTREMA" "$EXTREME_FILE"
        ;;
    4)
        echo "Testando TODAS as versões sequencialmente..."
        test_version "ORIGINAL" "$BACKUP_FILE"
        test_version "OTIMIZADA" "$OPTIMIZED_FILE"
        test_version "EXTREMA" "$EXTREME_FILE"
        ;;
    5)
        echo "Restaurando versão original..."
        cp "$BACKUP_FILE" "$ORIGINAL_FILE"
        echo "Pronto!"
        exit 0
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac

# Restaurar versão original ao final
echo ""
echo "Restaurando versão original..."
cp "$BACKUP_FILE" "$ORIGINAL_FILE"
echo "Teste concluído!"
echo "================================================"