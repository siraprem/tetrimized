import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// OTIMIZAÇÃO EXTREMA: Minimalismo e Performance Raw
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

/// CustomPainter para renderização otimizada dos botões
class ControlButtonPainter extends CustomPainter {
  final List<ControlButton> buttons;
  final bool isEditMode;
  final String? selectedId;
  final Map<String, bool> buttonStates;
  
  ControlButtonPainter({
    required this.buttons,
    required this.isEditMode,
    required this.selectedId,
    required this.buttonStates,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (final btn in buttons) {
      final isSelected = selectedId == btn.id;
      final isPressed = buttonStates[btn.id] ?? false;
      
      // Cor do botão baseado no estado
      if (isSelected) {
        paint.color = const Color(0xFF666666); // Cinza médio
      } else if (isEditMode) {
        paint.color = const Color(0x40FFFFFF); // Branco 25% opacidade
      } else if (isPressed) {
        paint.color = const Color(0xFF444444); // Cinza escuro pressionado
      } else {
        paint.color = const Color(0xFF333333); // Cinza padrão
      }
      
      // Desenhar círculo
      canvas.drawCircle(
        Offset(btn.x + btn.size / 2, btn.y + btn.size / 2),
        btn.size / 2,
        paint,
      );
      
      // Borda
      paint.color = isSelected ? const Color(0xFFFFFF00) : // Amarelo selecionado
                    isEditMode ? const Color(0xFFFF0000) : // Vermelho edit mode
                    const Color(0xFFFFFFFF); // Branco normal
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
  
  @override
  bool shouldRepaint(covariant ControlButtonPainter oldDelegate) {
    return buttons != oldDelegate.buttons ||
           isEditMode != oldDelegate.isEditMode ||
           selectedId != oldDelegate.selectedId ||
           buttonStates != oldDelegate.buttonStates;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  
  // Cache de strings JavaScript para cada combinação de tecla
  final Map<String, String> _jsCodeCache = {};
  
  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  @override
  void dispose() {
    _webViewController?.stopLoading();
    _webViewController = null;
    super.dispose();
  }

  /// Injeção de eventos OTIMIZADA AO EXTREMO
  void _sendAction(ControlButton btn, bool isDown) {
    if (_webViewController == null) return;

    final currentState = _buttonStates[btn.id] ?? false;
    if (isDown == currentState) return;
    _buttonStates[btn.id] = isDown;

    // Cache extremo: string JavaScript pré-computada
    final cacheKey = '${btn.key}:${btn.keyCode}:${btn.code}:$isDown';
    var jsCode = _jsCodeCache[cacheKey];
    if (jsCode == null) {
      jsCode = "window.sendTetrIoKey('${btn.key}',${btn.keyCode},'${btn.code}',$isDown);";
      _jsCodeCache[cacheKey] = jsCode;
    }
    
    // evaluateJavascript sem await - fire and forget
    _webViewController?.evaluateJavascript(source: jsCode);

    // Haptic feedback apenas se necessário e não bloqueante
    if (isDown && _hapticEnabled) {
      Future.microtask(() => HapticFeedback.lightImpact());
    }
    
    // Forçar repaint do CustomPainter
    if (mounted) {
      setState(() {});
    }
  }

  // Script JavaScript MINIMALISTA
  final _userScript = UserScript(
    source: """
(function() {
  let target = document.querySelector('canvas') || document;
  const gameKeys = new Set(['ArrowLeft','ArrowRight','ArrowDown',' ','z','x','a','c','Escape']);
  
  window.sendTetrIoKey = function(key, keyCode, code, isDown) {
    const event = new KeyboardEvent(isDown ? 'keydown' : 'keyup', {
      key: key,
      keyCode: keyCode,
      code: code,
      bubbles: true,
      cancelable: true
    });
    
    target.dispatchEvent(event);
    if (target !== window && target !== document) {
      window.dispatchEvent(event);
    }
    
    if (gameKeys.has(key)) {
      event.preventDefault();
    }
  };
  
  // Atualizar target periodicamente (mais raro)
  setInterval(() => {
    const newTarget = document.querySelector('canvas') || document;
    if (newTarget !== target) target = newTarget;
  }, 10000);
})();
""",
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  void _setupGameDetection() {
    _webViewController?.addJavaScriptHandler(
      handlerName: 'onGameStateChange', 
      callback: (args) {
        if (mounted) {
          setState(() {
            _isGameStarted = args[0] as bool;
          });
        }
      }
    );

    const js = """
(function() {
  let lastState = false;
  const check = () => {
    const isGame = !!document.querySelector('#game_canvas, .game_board, canvas[class*="game"]');
    if (isGame !== lastState) {
      lastState = isGame;
      window.flutter_inappwebview.callHandler('onGameStateChange', isGame);
    }
  };
  setInterval(check, 3000);
  check(); // Check inicial
})();
""";
    _webViewController?.evaluateJavascript(source: js);
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buttonsJson = prefs.getString('control_buttons_v5');
    
    if (mounted) {
      setState(() {
        _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      });
    }

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
              useHybridComposition: false, // DESABILITADO para performance raw
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

          // Overlay de controles com CustomPainter
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !(_isGameStarted || _isEditMode),
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
                        setState(() => _selectedButtonId = btn.id);
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
                  color: const Color(0x990000FF), // Azul 60%
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.refresh,
                  onPressed: () => _webViewController?.reload(),
                  color: const Color(0x99FF0000), // Vermelho 60%
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: _isEditMode ? Icons.save : Icons.edit,
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                      if (!_isEditMode) {
                        _selectedButtonId = null;
                        _saveButtons();
                      }
                    });
                  },
                  color: _isEditMode ? const Color(0x9900FF00) : const Color(0x99FF9900), // Verde/Laranja
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE0000000), // Preto 88%
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
        ],
      ),
    );
  }

  ControlButton? _findButtonAt(Offset position) {
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
    return Container(
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
    );
  }
}

class TetrIoPage extends StatefulWidget {
  const TetrIoPage({super.key});

  @override
  State<TetrIoPage> createState() => _TetrIoPageState();
}