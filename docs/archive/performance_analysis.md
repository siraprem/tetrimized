# Análise de Performance - Tetrimized (Wrapper Android para TETR.IO)

## Diagnóstico Inicial

### 1. Pontos Críticos de Alocação de Memória

#### A. `_sendAction()` - Função de Envio de Inputs
**Problema**: Criação de strings JavaScript dinâmicas a cada evento
```dart
final jsCode = "window.sendTetrIoKey('${btn.key}', ${btn.keyCode}, '${btn.code}', $isDown);"
```
- **Alocação**: String concatenada a cada evento (8-10 eventos por segundo em gameplay intenso)
- **GC Impact**: Strings temporárias pressionam o heap

#### B. `ControlButton` Objects
**Problema**: Lista de botões com múltiplas instâncias e conversões JSON
```dart
_buttons = decoded.map((e) => ControlButton.fromJson(e)).toList();
```
- **Alocação**: 9 objetos `ControlButton` + objetos `Map` intermediários
- **Serialização/Deserialização**: `toJson()`/`fromJson()` cria objetos `Map` temporários

#### C. `setState()` Calls
**Problema**: Rebuilds frequentes da UI
```dart
setState(() {
  _isGameStarted = args[0] as bool;
});
```
- **Impacto**: Rebuild de toda a árvore de widgets a cada mudança de estado
- **GC Pressure**: Widgets temporários criados e descartados

#### D. JavaScript Injection
**Problema**: Script grande injetado na WebView
```dart
final _userScript = UserScript(source: """...""")
```
- **Memory**: Script mantido em memória + contexto JavaScript separado
- **Parsing Overhead**: JavaScript precisa ser parseado pelo motor V8

### 2. Gargalos de Renderização

#### A. WebView Hardware Acceleration
**Configuração atual**:
```dart
hardwareAcceleration: true,
useHybridComposition: true,
```
- **Problema**: `useHybridComposition` pode causar overhead em dispositivos mais antigos
- **Solução**: Testar `useHybridComposition: false` para performance raw

#### B. Stack de Widgets com Opacidade
**Problema**: Múltiplas camadas de `Opacity` e `Container`
```dart
Opacity(
  opacity: _isEditMode ? 0.8 : 0.4,
  child: Container(...)
)
```
- **Render Cost**: Cada `Opacity` cria uma camada de composição separada
- **Overdraw**: Overlap de botões transparentes

#### C. PointerInterceptor Overhead
**Problema**: Interceptação condicional de eventos touch
```dart
PointerInterceptor(intercepting: _isGameStarted || _isEditMode, ...)
```
- **Event Routing**: Overhead adicional no pipeline de eventos

### 3. Memory Leaks Potenciais

#### A. WebViewController Lifecycle
**Problema**: Controller não é limpo adequadamente
```dart
_webViewController?.stopLoading();
_webViewController = null;
```
- **Risk**: Retenção de contexto WebView após dispose

#### B. JavaScript Handlers
**Problema**: Handlers não removidos
```dart
_webViewController?.addJavaScriptHandler(...)
```
- **Memory**: Handlers mantêm referências ao contexto Flutter

#### C. Timer/Interval no JavaScript
**Problema**: `setInterval` não limpo
```dart
setInterval(() => { ... }, 1000);
```
- **Leak**: Interval continua rodando mesmo após navegação

## Otimizações Propostas

### 1. Object Pooling para Input Events

**Implementar pool de strings JavaScript**:
```dart
class JSCodePool {
  static final Map<String, String> _cache = {};
  
  static String getKeyEvent(String key, int keyCode, String code, bool isDown) {
    final key = '$key:$keyCode:$code:$isDown';
    return _cache.putIfAbsent(key, () => 
      "window.sendTetrIoKey('$key', $keyCode, '$code', $isDown);");
  }
}
```

### 2. ControlButton como Struct Imutável

**Usar `@immutable` e `const` factories**:
```dart
@immutable
class ControlButton {
  final String id;
  final String label;
  final String key;
  final int keyCode;
  final String code;
  final double x;
  final double y;
  final double size;
  
  const ControlButton({...});
  
  // Factory com cache
  static final Map<String, ControlButton> _cache = {};
  
  factory ControlButton.cached({...}) {
    final key = '$id:$label:$key:$keyCode:$code:$x:$y:$size';
    return _cache.putIfAbsent(key, () => ControlButton(...));
  }
}
```

### 3. Otimização de WebView Configuration

**Configurações agressivas para performance**:
```dart
initialSettings: InAppWebViewSettings(
  useHybridComposition: false, // Testar performance raw
  hardwareAcceleration: true,
  cacheEnabled: true,
  cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
  transparentBackground: true, // Reduz composição
  disableVerticalScroll: true,
  disableHorizontalScroll: true,
  disableContextMenu: true,
  mediaPlaybackRequiresUserGesture: false,
  // Otimizações específicas para WebGL/Canvas
  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
  // Force 16-bit color para dispositivos antigos
  // forceColorProfile: ColorProfile.COLOR_PROFILE_SRGB,
),
```

### 4. JavaScript Injection Otimizado

**Script minimalista com cache de eventos**:
```javascript
// Versão otimizada - menos alocação, mais reuso
(function() {
  const eventCache = new Map();
  
  function getCachedEvent(type, key, keyCode, code) {
    const cacheKey = `${type}:${key}:${keyCode}:${code}`;
    if (!eventCache.has(cacheKey)) {
      eventCache.set(cacheKey, new KeyboardEvent(type, {
        key, keyCode, code, bubbles: true, cancelable: true
      }));
    }
    return eventCache.get(cacheKey);
  }
  
  window.sendTetrIoKey = function(key, keyCode, code, isDown) {
    const event = getCachedEvent(isDown ? 'keydown' : 'keyup', key, keyCode, code);
    (document.querySelector('canvas') || document).dispatchEvent(event);
  };
})();
```

### 5. Renderização Otimizada de Botões

**Usar `CustomPainter` em vez de Widgets**:
```dart
class ControlButtonPainter extends CustomPainter {
  final List<ControlButton> buttons;
  final bool isEditMode;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar todos os botões de uma vez
    for (final btn in buttons) {
      _paintButton(canvas, btn);
    }
  }
  
  // Implementação otimizada com Path reutilizável
}
```

## Plano de Implementação

### Fase 1: Otimizações de Baixo Impacto
1. Implementar pool de strings JavaScript
2. Adicionar cache para objetos ControlButton
3. Otimizar configurações da WebView

### Fase 2: Otimizações de Médio Impacto
1. Implementar CustomPainter para botões
2. Reduzir rebuilds com ValueNotifier/Stream
3. Otimizar JavaScript injection

### Fase 3: Otimizações Agressivas
1. Implementar WebView nativa com SurfaceTexture
2. Usar FFI para input direto
3. Bypass completo do framework Flutter para renderização

## Métricas a Monitorar

1. **Frame Time**: Tempo entre frames (alvo: <16ms para 60fps)
2. **GC Pauses**: Frequência e duração das pausas do coletor
3. **Heap Size**: Tamanho do heap Dart durante gameplay
4. **Input Latency**: Tempo entre touch e ação no jogo
5. **Memory Usage**: Uso total de RAM do app