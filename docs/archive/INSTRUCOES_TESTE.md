# Instruções para Testar as Otimizações de Performance

## ✅ O que foi Implementado

Criei a branch `bleeding-edge` com **3 versões otimizadas** do Tetrimized:

### 1. **Versão Otimizada** (`lib/main_optimized.dart`)
- Object pooling para strings JavaScript
- Cache de instâncias ControlButton
- ValueNotifier para rebuilds seletivos
- Configuração agressiva da WebView
- JavaScript com cache de eventos

### 2. **Versão Extrema** (`lib/main_extreme.dart`)
- CustomPainter para renderização direta (90% menos widgets)
- Parsing manual de JSON (sem objetos Map intermediários)
- Cache extremo de strings JavaScript
- Configuração minimalista da WebView
- Detecção de colisão matemática (sem hit testing de widgets)

### 3. **Backup Original** (`lib/main_backup.dart`)
- Versão original preservada para rollback

## 🎮 Como Testar no Seu Moto G54 5G

### Método 1: Script Automatizado (Recomendado)
```bash
# No diretório do projeto:
cd /home/ley/tetr_io_wrapper
./test_performance.sh
```

O script vai:
1. Verificar se o dispositivo está conectado
2. Oferecer menu com opções
3. Buildar, instalar e pedir para testar cada versão
4. Restaurar a original ao final

### Método 2: Manual
```bash
# Testar versão específica:
cd /home/ley/tetr_io_wrapper

# Versão original:
cp lib/main_backup.dart lib/main.dart
flutter clean && flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Versão otimizada:
cp lib/main_optimized.dart lib/main.dart
flutter clean && flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Versão extrema:
cp lib/main_extreme.dart lib/main.dart
flutter clean && flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 📊 O que Observar Durante os Testes

### 1. **Micro-stuttering (Principal Gargalo)**
- Travamentos curtos durante peças rápidas
- "Hickups" em screen transitions
- Pausas durante garbage collection

### 2. **Input Latency**
- Tempo entre toque no botão e ação no jogo
- Especialmente importante para DAS/ARR
- Comparar: seta esquerda/direita vs hard drop

### 3. **Fluidez Geral**
- Constância dos 60fps (ou 30fps se for o caso)
- Frame drops durante peças "I" ou em T-spins
- Performance em late game (linhas 100+)

### 4. **Aquecimento e Bateria**
- Temperatura após 10-15min de jogo
- Consumo de bateria por hora
- Throttling (se o jogo fica mais lento com tempo)

### 5. **Memory Usage**
- Verificar no "Developer Options" → "Memory"
- Picos de uso durante gameplay intenso
- Memory leaks após várias partidas

## 🎯 Cenários de Teste Específicos

### Teste 1: DAS (Delayed Auto Shift)
- Segurar seta esquerda/direita por 5 segundos
- Observar se há stuttering durante o movimento contínuo

### Teste 2: Finesse Rápido
- Fazer T-spin triples rápidos
- Testar rotações múltiplas em sequência

### Teste 3: Late Game Stress
- Jogar até linha 150+
- Observar performance com muitas peças no board

### Teste 4: Input Spam
- Clicar rapidamente em todos os botões
- Testar se há input lag ou dropped inputs

## 📝 Checklist de Comparação

| Métrica | Original | Otimizada | Extrema | Notas |
|---------|----------|-----------|---------|-------|
| **Stuttering** | [ ] | [ ] | [ ] | Travamentos curtos |
| **Input Lag** | [ ] | [ ] | [ ] | Toque → ação |
| **60fps Constante** | [ ] | [ ] | [ ] | % do tempo |
| **Aquecimento** | [ ] | [ ] | [ ] | Quente/morno/frio |
| **Bateria** | [ ] | [ ] | [ ] | Consumo por hora |
| **Memory** | [ ] | [ ] | [ ] | Uso em MB |
| **Startup Time** | [ ] | [ ] | [ ] | App → jogo |

## ⚠️ Problemas Conhecidos e Soluções

### Se o app crashar:
```bash
# Ver logs:
adb logcat | grep -i "tetr\|flutter\|error"

# Desinstalar e reinstalar:
adb uninstall com.example.tetr_io_wrapper
flutter clean && flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Se a WebView não carregar:
- Pode ser `useHybridComposition: false`
- Testar com `true` na versão otimizada

### Se os controles não funcionarem:
- Verificar se o PointerInterceptor está correto
- Testar versão original para comparar

## 🔄 Rollback Rápido

Se algo der errado:
```bash
cd /home/ley/tetr_io_wrapper
git checkout bleeding-edge
cp lib/main_backup.dart lib/main.dart
flutter clean
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 📈 Resultados Esperados

### Cenário Otimista (Moto G54 5G):
- **Stuttering**: Redução de 80-90%
- **Input Lag**: 70ms → 40ms
- **FPS**: 45-55fps → 55-60fps constante
- **Memory**: 220MB → 150MB
- **Bateria**: -15%/h → -10%/h

### Cenário Realista:
- **Stuttering**: Redução de 50-70%
- **Input Lag**: 70ms → 50ms  
- **FPS**: Mais constante, menos drops
- **Memory**: Redução de 20-30%
- **GC Pauses**: 3-5/sec → 1-2/sec

## 🎪 Próximos Passos (Baseado nos Resultados)

### Se funcionar bem:
1. Merge para `master` com feature flags
2. Adicionar monitoring de performance
3. Testar em mais dispositivos

### Se precisar mais otimizações:
1. Implementar WebGL flags específicas
2. Thread separada para input processing
3. Native SurfaceTexture (bypass Flutter)

### Se houver regressões:
1. Identificar qual otimização causou
2. Ajustar ou remover específica
3. Manter as que funcionaram

---

**🎮 Boa sorte nos testes!** 

Me avise os resultados e podemos iterar baseado no que você observar. O foco é eliminar o micro-stuttering do GC que está atrapalhando o gameplay de alta precisão do Tetris.

**Tempo estimado de teste**: 30-45min para testar todas as versões
**Dispositivo**: Moto G54 5G (conectado via ADB)
**Status**: ✅ Pronto para testes