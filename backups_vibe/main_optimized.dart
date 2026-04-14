import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// ============================================================================
// OTIMIZAÇÃO: Object Pooling e Cache
// ============================================================================

/// Pool de strings JavaScript para reduzir alocação
class JSCodePool {
  static final Map<String, String> _cache = {};
  
  static String getKeyEvent(String key, int keyCode, String code, bool isDown) {
    final cacheKey = '$key:$keyCode:$code:$isDown';
    return _cache.putIfAbsent(cacheKey, () => 
      "window.sendTetrIoKey('$key',$keyCode,'$code',$isDown);");
  }
}

/// ControlButton otimizado - imutável com factory cached
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
  
  // Cache estático para reutilizar instâncias idênticas
  static final Map<String, ControlButton> _cache = {};
  
  factory ControlButton.cached({
    required String id,
    required String label,
    required String key,
    required int keyCode,
    required String code,
    required double x,
    required double y,
    double size = 80.0,
  }) {
    final cacheKey = '$id:$label:$key:$keyCode:$code:$x:$y:$size';
    return _cache.putIfAbsent(cacheKey, () => ControlButton(
      id: id,
      label: label,
      key: key,
      keyCode: keyCode,
      code: code,
      x: x,
      y: y,
      size: size,
    ));
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'key': key,
    'keyCode': keyCode,
    'code': code,
    'x': x,
    'y': y,
    'size': size,
  };
  
  factory ControlButton.fromJson(Map<String, dynamic> json) => ControlButton.cached(
    id: json['id'],
    label: json['label'],
    key: json['key'],
    keyCode: json['keyCode'],
    code: json['code'] ?? '',
    x: json['x'].toDouble(),
    y: json['y'].toDouble(),
    size: json['size'].toDouble(),
  );
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
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
        ),
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
  
  // OTIMIZAÇÃO: ValueNotifier para reduzir rebuilds
  final ValueNotifier<bool> _gameStartedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _editModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _selectedButtonNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadButtons();
    
    // OTIMIZAÇÃO: Usar listeners em vez de setState direto
    _gameStartedNotifier.addListener(() {
      setState(() {
        _isGameStarted = _gameStartedNotifier.value;
      });
    });
    
    _editModeNotifier.addListener(() {
      setState(() {
        _isEditMode = _editModeNotifier.value;
      });
    });
    
    // _selectedButtonId removido - usando ValueNotifier diretamente
  }

  @override
  void dispose() {
    // OTIMIZAÇÃO: Limpar todos os listeners e controllers
    _gameStartedNotifier.dispose();
    _editModeNotifier.dispose();
    _selectedButtonNotifier.dispose();
    
    _webViewController?.stopLoading();
    _webViewController = null;
    super.dispose();
  }

  /// CAMADA 2 & 3: Injeção de Eventos OTIMIZADA com Object Pooling
  void _sendAction(ControlButton btn, bool isDown) {
    if (_webViewController == null) return;

    final currentState = _buttonStates[btn.id] ?? false;
    if (isDown == currentState) return;
    _buttonStates[btn.id] = isDown;

    // OTIMIZAÇÃO: Usar pool de strings JavaScript
    final jsCode = JSCodePool.getKeyEvent(btn.key, btn.keyCode, btn.code, isDown);
    
    // OTIMIZAÇÃO: evaluateJavascript é assíncrono mas não bloqueia se não esperarmos
    _webViewController?.evaluateJavascript(source: jsCode);

    // OTIMIZAÇÃO: Feedback tátil em microtask (não bloqueante)
    if (isDown && _hapticEnabled) {
      Future.microtask(() => HapticFeedback.lightImpact());
    }
  }

  // Script de injeção OTIMIZADO com cache de eventos
  final _userScript = UserScript(
    source: """
      (function() {
        'use strict';
        let cachedTarget = null;
        let lastTargetCheck = 0;
        const TARGET_CHECK_INTERVAL = 10000; // Aumentado para 10 segundos
        
        // Cache de eventos para reutilização
        const eventCache = new Map();
        
        function getCachedEvent(type, key, keyCode, code) {
          const cacheKey = type + ':' + key + ':' + keyCode + ':' + code;
          if (!eventCache.has(cacheKey)) {
            eventCache.set(cacheKey, new KeyboardEvent(type, {
              key: key,
              keyCode: keyCode,
              which: keyCode,
              code: code,
              bubbles: true,
              cancelable: true,
              repeat: false,
              view: window,
              composed: true
            }));
          }
          return eventCache.get(cacheKey);
        }
        
        window.sendTetrIoKey = function(key, keyCode, code, isDown) {
          const now = Date.now();
          if (!cachedTarget || !cachedTarget.isConnected || (now - lastTargetCheck) > TARGET_CHECK_INTERVAL) {
            cachedTarget = document.querySelector('canvas') || 
                          document.querySelector('#game_canvas') || 
                          document.querySelector('#game') || 
                          document;
            lastTargetCheck = now;
          }
          
          const event = getCachedEvent(isDown ? 'keydown' : 'keyup', key, keyCode, code);
          cachedTarget.dispatchEvent(event);
          
          if (cachedTarget !== window && cachedTarget !== document) {
            window.dispatchEvent(event);
          }
          
          // Prevenir comportamento padrão apenas para teclas de jogo
          if (['ArrowLeft','ArrowRight','ArrowDown',' ','z','x','a','c','Escape'].includes(key)) {
            event.preventDefault();
          }
        };
        
        // Inicializar cache imediatamente
        cachedTarget = document.querySelector('canvas') || document;
        
        // Limpar cache periodicamente (apenas se crescer muito)
        setInterval(() => {
          if (eventCache.size > 50) {
            eventCache.clear();
          }
        }, 60000);
      })();
    """,
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  // Monitora se a partida começou via DOM/JS (OTIMIZADO)
  void _setupGameDetection() {
    _webViewController?.addJavaScriptHandler(
      handlerName: 'onGameStateChange', 
      callback: (args) {
        _gameStartedNotifier.value = args[0] as bool;
      }
    );

    const js = """
      (function() {
        let lastState = false;
        const checkInterval = setInterval(() => {
          const isGame = !!document.querySelector('#game_canvas') || 
                        !!document.querySelector('.game_board') ||
                        !!document.querySelector('canvas[class*="game"]');
          if (isGame !== lastState) {
            lastState = isGame;
            window.flutter_inappwebview.callHandler('onGameStateChange', isGame);
          }
        }, 2000); // Aumentado para 2 segundos
        
        // Limpar intervalo quando a página for descarregada
        window.addEventListener('beforeunload', () => {
          clearInterval(checkInterval);
        });
      })();
    """;
    _webViewController?.evaluateJavascript(source: js);
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buttonsJson = prefs.getString('control_buttons_v5');
    
    // OTIMIZAÇÃO: Single setState
    setState(() {
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    });

    if (buttonsJson != null) {
      final List<dynamic> decoded = jsonDecode(buttonsJson);
      // OTIMIZAÇÃO: Usar factories cached
      setState(() {
        _buttons = decoded.map((e) => ControlButton.fromJson(e)).toList();
      });
    } else {
      // OTIMIZAÇÃO: Botões padrão usando cache
      setState(() {
        _buttons = [
          ControlButton.cached(id: 'left', label: '←', key: 'ArrowLeft', keyCode: 37, code: 'ArrowLeft', x: 20, y: 250),
          ControlButton.cached(id: 'right', label: '→', key: 'ArrowRight', keyCode: 39, code: 'ArrowRight', x: 140, y: 250),
          ControlButton.cached(id: 'soft', label: '↓', key: 'ArrowDown', keyCode: 40, code: 'ArrowDown', x: 80, y: 330),
          ControlButton.cached(id: 'hard', label: 'SPACE', key: ' ', keyCode: 32, code: 'Space', x: 80, y: 170),
          ControlButton.cached(id: 'rotL', label: 'Z', key: 'z', keyCode: 90, code: 'KeyZ', x: 550, y: 250),
          ControlButton.cached(id: 'rotR', label: 'X', key: 'x', keyCode: 88, code: 'KeyX', x: 670, y: 250),
          ControlButton.cached(id: 'rot180', label: 'A', key: 'a', keyCode: 65, code: 'KeyA', x: 610, y: 330),
          ControlButton.cached(id: 'hold', label: 'C', key: 'c', keyCode: 67, code: 'KeyC', x: 610, y: 140),
          ControlButton.cached(id: 'pause', label: 'ESC', key: 'Escape', keyCode: 27, code: 'Escape', x: 20, y: 20, size: 50),
        ];
      });
    }
  }

  Future<void> _saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_buttons.map((e) => e.toJson()).toList());
    await prefs.setString('control_buttons_v5', encoded);
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
              // ============================================================================
              // OTIMIZAÇÃO: Configurações agressivas para performance
              // ============================================================================
              javaScriptEnabled: true,
              useHybridComposition: false, // TESTAR: false pode ser mais rápido em dispositivos antigos
              cacheEnabled: true,
              cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK, // Priorizar cache
              supportZoom: false,
              builtInZoomControls: false,
              displayZoomControls: false,
              allowsInlineMediaPlayback: true,
              transparentBackground: true, // Reduz composição de layers
              hardwareAcceleration: true, // Forçar hardware acceleration
              mediaPlaybackRequiresUserGesture: false,
              // Otimizações de renderização
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
              disableContextMenu: true,
              // Configurações de performance
              minimumFontSize: 1,
              textZoom: 100,
              // WebGL/Canvas optimizations
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              // Force color profile para dispositivos antigos
              // forceColorProfile: ColorProfile.COLOR_PROFILE_SRGB,
              // Desabilitar features não essenciais
              safeBrowsingEnabled: false,
              thirdPartyCookiesEnabled: false,
              // Otimização de memória
              incognito: false,
              clearSessionCache: false,
            ),
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
              _webViewController = controller;
              _setupGameDetection();
            },
            onConsoleMessage: (controller, consoleMessage) {
              // Logs desativados para economizar processamento
            },
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Botões de Controle
          PointerInterceptor(
            intercepting: _isGameStarted || _isEditMode, 
            child: Stack(
              children: [
                // OTIMIZAÇÃO: Usar ValueListenableBuilder para rebuilds seletivos
                ..._buttons.map((btn) => _buildMovableButton(btn)),
                
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _buildTopActionButton(
                        icon: _hapticEnabled ? Icons.vibration : Icons.mobile_off,
                        onPressed: () {
                          setState(() => _hapticEnabled = !_hapticEnabled);
                          _saveButtons();
                        },
                        color: Colors.blue.withAlpha(153), // 0.6 opacity
                      ),
                      const SizedBox(width: 10),
                      _buildTopActionButton(
                        icon: Icons.refresh, 
                        onPressed: () => _webViewController?.reload(), 
                        color: Colors.red.withAlpha(153) // 0.6 opacity
                      ),
                      const SizedBox(width: 10),
                      ValueListenableBuilder<bool>(
                        valueListenable: _editModeNotifier,
                        builder: (context, isEditMode, child) {
                          return _buildTopActionButton(
                            icon: isEditMode ? Icons.save : Icons.edit,
                            onPressed: () {
                              _editModeNotifier.value = !isEditMode;
                              if (!isEditMode) {
                                _selectedButtonNotifier.value = null;
                                _saveButtons();
                              }
                            },
                            color: (isEditMode ? Colors.green : Colors.orange).withAlpha(153), // 0.6 opacity
                          );
                        }
                      ),
                    ],
                  ),
                ),

                // Slider de Redimensionamento
                ValueListenableBuilder<String?>(
                  valueListenable: _selectedButtonNotifier,
                  builder: (context, selectedId, child) {
                    if (!_isEditMode || selectedId == null) return const SizedBox.shrink();
                    
                    final btn = _buttons.firstWhere((b) => b.id == selectedId);
                    return Positioned(
                      bottom: 50,
                      left: MediaQuery.of(context).size.width * 0.25,
                      right: MediaQuery.of(context).size.width * 0.25,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_size_select_small, color: Colors.white),
                            Expanded(
                              child: Slider(
                                value: btn.size,
                                min: 40.0,
                                max: 200.0,
                                onChanged: (val) {
                                  setState(() {
                                    final index = _buttons.indexWhere((b) => b.id == selectedId);
                                    if (index != -1) {
                                      _buttons[index] = ControlButton.cached(
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
                            const Icon(Icons.photo_size_select_large, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton({required IconData icon, required VoidCallback onPressed, required Color color}) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20), 
        onPressed: onPressed,
        padding: EdgeInsets.zero, // OTIMIZAÇÃO: Reduzir padding
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36), // Tamanho mínimo
      ),
    );
  }

  Widget _buildMovableButton(ControlButton btn) {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedButtonNotifier,
      builder: (context, selectedId, child) {
        final isSelected = selectedId == btn.id;
        return Positioned(
          left: btn.x,
          top: btn.y,
          child: Listener(
            onPointerDown: (_) {
              if (_isEditMode) {
                _selectedButtonNotifier.value = btn.id;
              } else {
                _sendAction(btn, true);
              }
            },
            onPointerUp: (_) => _isEditMode ? null : _sendAction(btn, false),
            onPointerCancel: (_) => _isEditMode ? null : _sendAction(btn, false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _isEditMode
                  ? (details) {
                      setState(() {
                        final index = _buttons.indexWhere((b) => b.id == btn.id);
                        if (index != -1) {
                          _buttons[index] = ControlButton.cached(
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
                  : null,
              child: Container(
                width: btn.size,
                height: btn.size,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.grey[400] : (_isEditMode ? Colors.white24 : Colors.grey[800]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.yellow : (_isEditMode ? Colors.red : Colors.white), 
                    width: isSelected ? 3 : 2
                  ),
                ),
                child: Center(
                  child: Text(
                    btn.label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: btn.size * 0.25, 
                      decoration: TextDecoration.none
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

class TetrIoPage extends StatefulWidget {
  const TetrIoPage({super.key});

  @override
  State<TetrIoPage> createState() => _TetrIoPageState();
}