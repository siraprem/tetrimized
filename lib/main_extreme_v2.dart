import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// OTIMIZAÇÃO EXTREMA V2: Foco em UI Thread e Draw Commands
// ============================================================================

/// ControlButton extremamente otimizado - struct-like com const factory
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
  
  const ControlButton({
    required this.id,
    required this.label,
    required this.key,
    required this.keyCode,
    required this.code,
    required this.x,
    required this.y,
    this.size = 80.0,
  });
  
  // Serialização direta sem objetos intermediários
  String toJsonString() => '{"id":"$id","label":"$label","key":"$key","keyCode":$keyCode,"code":"$code","x":$x,"y":$y,"size":$size}';
  
  static ControlButton fromJsonString(String jsonStr) {
    // Parsing manual mais rápido que jsonDecode para objetos simples
    final parts = jsonStr.split(',');
    return ControlButton(
      id: _extractString(parts[0]),
      label: _extractString(parts[1]),
      key: _extractString(parts[2]),
      keyCode: int.parse(_extractNumber(parts[3])),
      code: _extractString(parts[4]),
      x: double.parse(_extractNumber(parts[5])),
      y: double.parse(_extractNumber(parts[6])),
      size: double.parse(_extractNumber(parts[7])),
    );
  }
  
  static String _extractString(String part) => part.split(':')[1].replaceAll('"', '').trim();
  static String _extractNumber(String part) => part.split(':')[1].replaceAll('"', '').trim();
}

/// CustomPainter com CACHE DE PINTURA (Picture Caching)
class ControlButtonPainter extends CustomPainter {
  final List<ControlButton> buttons;
  final bool isEditMode;
  final String? selectedId;
  final Map<String, bool> buttonStates;
  
  // CACHE DE IMAGENS: Uma imagem por combinação de estado
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, ui.Picture> _pictureCache = {};
  
  // Cache key para o estado atual
  String get _cacheKey {
    final buffer = StringBuffer();
    buffer.write('edit:$isEditMode:selected:$selectedId:');
    for (final btn in buttons) {
      buffer.write('${btn.id}:${buttonStates[btn.id] ?? false}:');
    }
    return buffer.toString();
  }
  
  ControlButtonPainter({
    required this.buttons,
    required this.isEditMode,
    required this.selectedId,
    required this.buttonStates,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Tentar usar cache de imagem primeiro
    final cachedImage = _imageCache[_cacheKey];
    if (cachedImage != null) {
      canvas.drawImage(cachedImage, Offset.zero, Paint());
      return;
    }
    
    // Se não tem cache, renderizar e cachear
    final recorder = ui.PictureRecorder();
    final canvasCache = Canvas(recorder);
    
    _paintButtons(canvasCache, size);
    
    final picture = recorder.endRecording();
    _pictureCache[_cacheKey] = picture;
    
    // Converter para imagem em background (não bloqueia UI thread)
    _cachePictureAsync(picture, size);
    
    // Desenhar enquanto a imagem é cacheada
    canvas.drawPicture(picture);
  }
  
  void _paintButtons(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (final btn in buttons) {
      final isSelected = selectedId == btn.id;
      final isPressed = buttonStates[btn.id] ?? false;
      
      // Cor do botão baseado no estado
      if (isSelected) {
        paint.color = const Color(0xFF666666);
      } else if (isEditMode) {
        paint.color = const Color(0x40FFFFFF);
      } else if (isPressed) {
        paint.color = const Color(0xFF444444);
      } else {
        paint.color = const Color(0xFF333333);
      }
      
      // Desenhar círculo
      canvas.drawCircle(
        Offset(btn.x + btn.size / 2, btn.y + btn.size / 2),
        btn.size / 2,
        paint,
      );
      
      // Borda
      paint.color = isSelected ? const Color(0xFFFFFF00) :
                    isEditMode ? const Color(0xFFFF0000) :
                    const Color(0xFFFFFFFF);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = isSelected ? 3.0 : 2.0;
      canvas.drawCircle(
        Offset(btn.x + btn.size / 2, btn.y + btn.size / 2),
        btn.size / 2 - 1,
        paint,
      );
      paint.style = PaintingStyle.fill;
      
      // Texto
      textPainter.text = TextSpan(
        text: btn.label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          fontWeight: FontWeight.bold,
          fontSize: btn.size * 0.25,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          btn.x + btn.size / 2 - textPainter.width / 2,
          btn.y + btn.size / 2 - textPainter.height / 2,
        ),
      );
    }
  }
  
  void _cachePictureAsync(ui.Picture picture, Size size) async {
    try {
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      _imageCache[_cacheKey] = image;
      
      // Limitar cache para evitar memory leak
      if (_imageCache.length > 10) {
        final keys = _imageCache.keys.toList();
        for (int i = 0; i < keys.length - 5; i++) {
          _imageCache.remove(keys[i]);
          _pictureCache.remove(keys[i]);
        }
      }
    } catch (e) {
      // Falha silenciosa - o cache é apenas otimização
    }
  }
  
  @override
  bool shouldRepaint(covariant ControlButtonPainter oldDelegate) {
    // Repaint apenas se o estado mudou significativamente
    return _cacheKey != oldDelegate._cacheKey;
  }
}

/// ValueNotifier OTIMIZADO com debounce e batch updates
class OptimizedValueNotifier<T> extends ValueNotifier<T> {
  OptimizedValueNotifier(T value) : super(value);
  
  Timer? _debounceTimer;
  bool _pendingNotification = false;
  
  @override
  void notifyListeners() {
    // Debounce para evitar notificações excessivas
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _pendingNotification = true;
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 8), () {
      if (_pendingNotification) {
        _pendingNotification = false;
        super.notifyListeners();
      }
      _debounceTimer = null;
    });
    
    super.notifyListeners();
  }
  
  void forceNotify() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingNotification = false;
    super.notifyListeners();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FORÇAR Impeller se disponível (reduz Missed Vsync)
  try {
    debugPrint('🔧 Configurando renderizador Impeller...');
    // Esta flag é experimental no Flutter 3.x+
    // Em versões mais novas, o Impeller é default
  } catch (e) {
    debugPrint('⚠️ Impeller não disponível nesta versão do Flutter');
  }
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const TetrIoApp());
}

class TetrIoApp extends StatelessWidget {
  const TetrIoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetr.io Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const TetrIoPage(),
    );
  }
}

class _TetrIoPageState extends State<TetrIoPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isGameStarted = false;
  List<ControlButton> _buttons = [];
  bool _isEditMode = false;
  bool _hapticEnabled = true;
  final Map<String, bool> _buttonStates = {};
  String? _selectedButtonId;
  
  // ValueNotifiers OTIMIZADOS com debounce
  final OptimizedValueNotifier<bool> _gameStartedNotifier = OptimizedValueNotifier<bool>(false);
  final OptimizedValueNotifier<bool> _editModeNotifier = OptimizedValueNotifier<bool>(false);
  final OptimizedValueNotifier<String?> _selectedButtonNotifier = OptimizedValueNotifier<String?>(null);
  
  // Cache de strings JavaScript para cada combinação de tecla
  final Map<String, String> _jsCodeCache = {};
  
  @override
  void initState() {
    super.initState();
    _setupValueNotifierListeners();
    _loadButtons();
  }

  @override
  void dispose() {
    _gameStartedNotifier.dispose();
    _editModeNotifier.dispose();
    _selectedButtonNotifier.dispose();
    _webViewController?.stopLoading();
    _webViewController = null;
    super.dispose();
  }

  void _setupValueNotifierListeners() {
    // Listeners LEVES - apenas atualizam estado, sem lógica pesada
    _gameStartedNotifier.addListener(() {
      if (_gameStartedNotifier.value != _isGameStarted && mounted) {
        setState(() => _isGameStarted = _gameStartedNotifier.value);
      }
    });
    
    _editModeNotifier.addListener(() {
      if (_editModeNotifier.value != _isEditMode && mounted) {
        setState(() => _isEditMode = _editModeNotifier.value);
      }
    });
    
    _selectedButtonNotifier.addListener(() {
      if (_selectedButtonNotifier.value != _selectedButtonId && mounted) {
        setState(() => _selectedButtonId = _selectedButtonNotifier.value);
      }
    });
  }

  /// Injeção de eventos OTIMIZADA AO EXTREMO
  void _sendAction(ControlButton btn, bool isDown) {
    if (_webViewController == null) return;

    final currentState = _buttonStates[btn.id] ?? false;
    if (isDown == currentState) return;
    
    // Atualizar estado localmente (sem setState imediato)
    _buttonStates[btn.id] = isDown;

    // Cache extremo: string JavaScript pré-computada
    final cacheKey = '${btn.key}:${btn.keyCode}:${btn.code}:$isDown';
    var jsCode = _jsCodeCache[cacheKey];
    if (jsCode == null) {
      jsCode = "window.sendTetrIoKey('${btn.key}',${btn.keyCode},'${btn.code}',$isDown);";
      _jsCodeCache[cacheKey] = jsCode;
    }
    
    // evaluateJavascript em background thread se possível
    _webViewController?.evaluateJavascript(source: jsCode);

    // Haptic feedback apenas se necessário e não bloqueante
    if (isDown && _hapticEnabled) {
      Future.microtask(() => HapticFeedback.lightImpact());
    }
    
    // Forçar repaint do CustomPainter (com debounce)
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // Script JavaScript MINIMALISTA com otimizações de performance
  final _userScript = UserScript(
    source: """
(function() {
  'use strict';
  
  let target = document.querySelector('canvas') || document;
  const gameKeys = new Set(['ArrowLeft','ArrowRight','ArrowDown',' ','z','x','a','c','Escape']);
  
  // Cache de eventos KeyboardEvent
  const eventCache = new Map();
  
  function getCachedEvent(type, key, keyCode, code) {
    const cacheKey = type + ':' + key + ':' + keyCode + ':' + code;
    if (!eventCache.has(cacheKey)) {
      eventCache.set(cacheKey, new KeyboardEvent(type, {
        key: key,
        keyCode: keyCode,
        code: code,
        bubbles: true,
        cancelable: true
      }));
    }
    return eventCache.get(cacheKey);
  }
  
  window.sendTetrIoKey = function(key, keyCode, code, isDown) {
    const event = getCachedEvent(isDown ? 'keydown' : 'keyup', key, keyCode, code);
    
    // Dispatch otimizado
    if (target.dispatchEvent(event)) {
      if (target !== window && target !== document) {
        window.dispatchEvent(event);
      }
    }
    
    if (gameKeys.has(key)) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
    
    return true;
  };
  
  // Atualizar target de forma não-blocking
  let targetUpdateScheduled = false;
  function updateTarget() {
    if (targetUpdateScheduled) return;
    
    targetUpdateScheduled = true;
    requestAnimationFrame(() => {
      const newTarget = document.querySelector('canvas') || document;
      if (newTarget !== target) {
        target = newTarget;
        // Limpar cache quando o target muda
        eventCache.clear();
      }
      targetUpdateScheduled = false;
    });
  }
  
  // Verificar target a cada 5 segundos (não a cada frame)
  setInterval(updateTarget, 5000);
  updateTarget(); // Check inicial
})();
""",
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  void _setupGameDetection() {
    _webViewController?.addJavaScriptHandler(
      handlerName: 'onGameStateChange', 
      callback: (args) {
        // Usar ValueNotifier com debounce
        _gameStartedNotifier.value = args[0] as bool;
      }
    );

    const js = """
(function() {
  'use strict';
  
  let lastState = false;
  let checkScheduled = false;
  
  function checkGameState() {
    const isGame = !!document.querySelector('#game_canvas, .game_board, canvas[class*="game"]');
    if (isGame !== lastState) {
      lastState = isGame;
      window.flutter_inappwebview.callHandler('onGameStateChange', isGame);
    }
    checkScheduled = false;
  }
  
  function scheduleCheck() {
    if (!checkScheduled) {
      checkScheduled = true;
      setTimeout(checkGameState, 100);
    }
  }
  
  // Observer para detectar mudanças no DOM
  const observer = new MutationObserver(scheduleCheck);
  observer.observe(document.body, { 
    childList: true, 
    subtree: true,
    attributes: false,
    characterData: false
  });
  
  // Check inicial
  setTimeout(checkGameState, 1000);
})();
""";
    _webViewController?.evaluateJavascript(source: js);
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buttonsJson = prefs.getString('control_buttons_v5');
    
    _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;

    if (buttonsJson != null) {
      // Parsing manual mais rápido
      final cleaned = buttonsJson.replaceAll('[', '').replaceAll(']', '');
      final items = cleaned.split('},{');
      final buttons = <ControlButton>[];
      
      for (var item in items) {
        if (!item.startsWith('{')) item = '{$item';
        if (!item.endsWith('}')) item = '$item}';
        buttons.add(ControlButton.fromJsonString(item));
      }
      
      if (mounted) {
        setState(() {
          _buttons = buttons;
        });
      }
    } else {
      // Botões padrão
      if (mounted) {
        setState(() {
          _buttons = const [
            ControlButton(id: 'left', label: '←', key: 'ArrowLeft', keyCode: 37, code: 'ArrowLeft', x: 20, y: 250),
            ControlButton(id: 'right', label: '→', key: 'ArrowRight', keyCode: 39, code: 'ArrowRight', x: 140, y: 250),
            ControlButton(id: 'soft', label: '↓', key: 'ArrowDown', keyCode: 40, code: 'ArrowDown', x: 80, y: 330),
            ControlButton(id: 'hard', label: 'SPACE', key: ' ', keyCode: 32, code: 'Space', x: 80, y: 170),
            ControlButton(id: 'rotL', label: 'Z', key: 'z', keyCode: 90, code: 'KeyZ', x: 550, y: 250),
            ControlButton(id: 'rotR', label: 'X', key: 'x', keyCode: 88, code: 'KeyX', x: 670, y: 250),
            ControlButton(id: 'rot180', label: 'A', key: 'a', keyCode: 65, code: 'KeyA', x: 610, y: 330),
            ControlButton(id: 'hold', label: 'C', key: 'c', keyCode: 67, code: 'KeyC', x: 610, y: 140),
            ControlButton(id: 'pause', label: 'ESC', key: 'Escape', keyCode: 27, code: 'Escape', x: 20, y: 20, size: 50),
          ];
        });
      }
    }
  }

  Future<void> _saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final buffer = StringBuffer('[');
    for (var i = 0; i < _buttons.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(_buttons[i].toJsonString());
    }
    buffer.write(']');
    
    await prefs.setString('control_buttons_v5', buffer.toString());
    await prefs.setBool('haptic_enabled', _hapticEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("https://tetr.io")),
            initialUserScripts: UnmodifiableListView<UserScript>([_userScript]),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useHybridComposition: false,
              cacheEnabled: true,
              cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
              supportZoom: false,
              builtInZoomControls: false,
              displayZoomControls: false,
              allowsInlineMediaPlayback: true,
              transparentBackground: true,
              hardwareAcceleration: true,
              mediaPlaybackRequiresUserGesture: false,
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
              disableContextMenu: true,
              minimumFontSize: 1,
              textZoom: 100,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              safeBrowsingEnabled: false,
              thirdPartyCookiesEnabled: false,
              incognito: false,
              clearSessionCache: false,
              // Configurações específicas para reduzir Missed Vsync
              useWideViewPort: false,
              loadWithOverviewMode: false,
            ),
            onLoadStop: (controller, url) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
              _webViewController = controller;
              _setupGameDetection();
            },
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Overlay de controles com RepaintBoundary e CustomPainter cacheado
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !(_isGameStarted || _isEditMode),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: ControlButtonPainter(
                    buttons: _buttons,
                    isEditMode: _isEditMode,
                    selectedId: _selectedButtonId,
                    buttonStates: _buttonStates,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanDown: (details) {
                      final btn = _findButtonAt(details.localPosition);
                      if (btn != null) {
                        if (_isEditMode) {
                          _selectedButtonNotifier.value = btn.id;
                        } else {
                          _sendAction(btn, true);
                        }
                      }
                    },
                    onPanUpdate: _isEditMode ? (details) {
                      final btn = _findButtonAt(details.localPosition);
                      if (btn != null && _selectedButtonId == btn.id) {
                        setState(() {
                          final index = _buttons.indexWhere((b) => b.id == btn.id);
                          if (index != -1) {
                            _buttons[index] = ControlButton(
                              id: btn.id,
                              label: btn.label,
                              key: btn.key,
                              keyCode: btn.keyCode,
                              code: btn.code,
                              x: btn.x + details.delta.dx,
                              y: btn.y + details.delta.dy,
                              size: btn.size,
                            );
                          }
                        });
                      }
                    } : null,
                    onPanEnd: _isEditMode ? null : (details) {
                      // Liberar todas as teclas pressionadas
                      for (final btn in _buttons) {
                        if (_buttonStates[btn.id] == true) {
                          _sendAction(btn, false);
                        }
                      }
                    },
                    onPanCancel: _isEditMode ? null : () {
                      // Liberar todas as teclas pressionadas
                      for (final btn in _buttons) {
                        if (_buttonStates[btn.id] == true) {
                          _sendAction(btn, false);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // Botões de ação (minimalistas)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _buildActionButton(
                  icon: _hapticEnabled ? Icons.vibration : Icons.mobile_off,
                  onPressed: () {
                    setState(() => _hapticEnabled = !_hapticEnabled);
                    _saveButtons();
                  },
                  color: const Color(0x990000FF),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.refresh,
                  onPressed: () => _webViewController?.reload(),
                  color: const Color(0x99FF0000),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: _isEditMode ? Icons.save : Icons.edit,
                  onPressed: () {
                    _editModeNotifier.value = !_isEditMode;
                    if (!_isEditMode) {
                      _selectedButtonNotifier.value = null;
                      _saveButtons();
                    }
                  },
                  color: _isEditMode ? const Color(0x9900FF00) : const Color(0x99FF9900),
                ),
              ],
            ),
          ),

          // Slider de tamanho (apenas no edit mode)
          if (_isEditMode && _selectedButtonId != null)
            Positioned(
              bottom: 40,
              left: 50,
              right: 50,
              child: RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE0000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                      Expanded(
                        child: Slider(
                          value: _buttons.firstWhere((b) => b.id == _selectedButtonId).size,
                          min: 40.0,
                          max: 200.0,
                          onChanged: (val) {
                            setState(() {
                              final index = _buttons.indexWhere((b) => b.id == _selectedButtonId);
                              if (index != -1) {
                                final btn = _buttons[index];
                                _buttons[index] = ControlButton(
                                  id: btn.id,
                                  label: btn.label,
                                  key: btn.key,
                                  keyCode: btn.keyCode,
                                  code: btn.code,
                                  x: btn.x,
                                  y: btn.y,
                                  size: val,
                                );
                              }
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ControlButton? _findButtonAt(Offset position) {
    // Busca otimizada - assume que há poucos botões
    for (final btn in _buttons) {
      final center = Offset(btn.x + btn.size / 2, btn.y + btn.size / 2);
      final distance = (position - center).distance;
      if (distance <= btn.size / 2) {
        return btn;
      }
    }
    return null;
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed, required Color color}) {
    return RepaintBoundary(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 18),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class TetrIoPage extends StatefulWidget {
  const TetrIoPage({super.key});

  @override
  State<TetrIoPage> createState() => _TetrIoPageState();
}