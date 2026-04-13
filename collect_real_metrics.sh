#!/bin/bash

echo "📱 COLETANDO MÉTRICAS REAIS DO DISPOSITIVO"
echo "=========================================="

# 1. Coletar informações do dispositivo
echo "1. Informações do dispositivo:"
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.hardware
echo ""

# 2. Coletar uso de memória do app
echo "2. Uso de memória do Tetrimized:"
adb shell dumpsys meminfo com.example.tetr_io_wrapper | grep -A 20 "App Summary" | head -10
echo ""

# 3. Coletar estatísticas de GPU/Frame (se disponível)
echo "3. Estatísticas de renderização:"
adb shell dumpsys gfxinfo com.example.tetr_io_wrapper reset 2>/dev/null || echo "Coleta de gfxinfo não disponível"
echo ""

# 4. Coletar informações de CPU
echo "4. Uso de CPU:"
adb shell top -n 1 -b | grep -i "tetr\|flutter" | head -5
echo ""

# 5. Coletar logs de performance do Flutter
echo "5. Logs de performance recentes:"
adb logcat -d --buffer=main -s "flutter" -t 100 | grep -i "frame\|gc\|alloc\|ms" | tail -20
echo ""

echo "✅ Coleta de métricas completada!"
echo ""
echo "📊 RESUMO DAS MÉTRICAS COLETADAS:"
echo "---------------------------------"
echo "Para análise completa, execute manualmente no dispositivo:"
echo "1. Abra o app Tetrimized"
echo "2. Jogue por 1-2 minutos"
echo "3. Execute: adb shell dumpsys gfxinfo com.example.tetr_io_wrapper"
echo "4. Execute: adb shell dumpsys meminfo com.example.tetr_io_wrapper"
echo ""
echo "Isso fornecerá dados reais de:"
echo "- Frame times (percentis 50, 90, 95, 99)"
echo "- Janks (frames > 16ms para 60Hz ou > 8ms para 120Hz)"
echo "- Uso de memória (PSS, Heap)"
echo "- Alocação de objetos"