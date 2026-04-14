import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

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

class ControlButton {
  String id;
  String label;
  String key;
  int keyCode;
  String code;
  double x;
  double y;
  double size;

  ControlButton({
    required this.id,
    required this.label,
    required this.key,
    required this.keyCode,
    required this.code,
    required this.x,
    required this.y,
    this.size = 80.0,
  });

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

  factory ControlButton.fromJson(Map<String, dynamic> json) => ControlButton(
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

class TetrIoPage extends StatefulWidget {
  const TetrIoPage({super.key});

  @override
  State<TetrIoPage> createState() => _TetrIoPageState();
}

class _TetrIoPageState extends State<TetrIoPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isGameStarted = false; // Camada 1: Interceptação condicional
  List<ControlButton> _buttons = [];
  double _baseScaleSize = 80.0;
  bool _isEditMode = false;
  bool _hapticEnabled = true;
  final Map<String, bool> _buttonStates = {};
  String? _selectedButtonId;

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  @override
  void dispose() {
    // Limpa o controlador da WebView para evitar memory leaks
    _webViewController?.stopLoading();
    _webViewController = null;
    super.dispose();
  }

  /// CAMADA 2 & 3: Injeção de Eventos de Baixa Latência Otimizada
  void _sendAction(ControlButton btn, bool isDown) {
    if (_webViewController == null) return;

    final currentState = _buttonStates[btn.id] ?? false;
    if (isDown == currentState) return;
    _buttonStates[btn.id] = isDown;

    // Otimização: Usar runJavascript em vez de evaluateJavascript para menor latência
    // evaluateJavascript retorna um Future, enquanto runJavascript não espera resultado
    final jsCode = "window.sendTetrIoKey('${btn.key}', ${btn.keyCode}, '${btn.code}', $isDown);";
    
    // Usar evaluateJavascript (método padrão)
    _webViewController?.evaluateJavascript(source: jsCode);

    // Otimização: Agendar feedback tátil em microtask para não bloquear o thread principal
    if (isDown && _hapticEnabled) {
      Future.microtask(() => HapticFeedback.lightImpact());
    }
  }

  // Script de injeção única otimizado: Cache do Canvas e criação da função global
  final _userScript = UserScript(
    source: """
      (function() {
        'use strict';
        let cachedTarget = null;
        let lastTargetCheck = 0;
        const TARGET_CHECK_INTERVAL = 5000; // Verificar a cada 5 segundos
        
        window.sendTetrIoKey = function(key, keyCode, code, isDown) {
          const now = Date.now();
          // Verificar periodicamente se o target ainda é válido (sem verificar a cada evento)
          if (!cachedTarget || !cachedTarget.isConnected || (now - lastTargetCheck) > TARGET_CHECK_INTERVAL) {
            cachedTarget = document.querySelector('canvas') || 
                          document.querySelector('#game_canvas') || 
                          document.querySelector('#game') || 
                          document;
            lastTargetCheck = now;
          }
          const type = isDown ? 'keydown' : 'keyup';
          
          // Criar evento otimizado para performance
          let event;
          try {
            event = new KeyboardEvent(type, {
              key: key,
              keyCode: keyCode,
              which: keyCode,
              code: code,
              bubbles: true,
              cancelable: true,
              repeat: false,
              // Adicionar propriedades padrão para compatibilidade
              view: window,
              composed: true
            });
          } catch (e) {
            // Fallback para método mais compatível
            event = document.createEvent('KeyboardEvent');
            event.initKeyboardEvent(type, true, true, window, key, 0, '', false, '');
          }
          
          // Dispatch otimizado: primeiro no target cacheado, depois no window se necessário
          cachedTarget.dispatchEvent(event);
          
          // Tetr.io escuta eventos no window também
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
      })();
    """,
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  // Monitora se a partida começou via DOM/JS
  void _setupGameDetection() {
    _webViewController?.addJavaScriptHandler(handlerName: 'onGameStateChange', callback: (args) {
      setState(() {
        _isGameStarted = args[0] as bool;
      });
    });

    const js = """
      (function() {
        let lastState = false;
        setInterval(() => {
          const isGame = !!document.querySelector('#game_canvas') || !!document.querySelector('.game_board');
          if (isGame !== lastState) {
            lastState = isGame;
            window.flutter_inappwebview.callHandler('onGameStateChange', isGame);
          }
        }, 1000);
      })();
    """;
    _webViewController?.evaluateJavascript(source: js);
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buttonsJson = prefs.getString('control_buttons_v5');
    setState(() {
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    });

    if (buttonsJson != null) {
      final List<dynamic> decoded = jsonDecode(buttonsJson);
      setState(() {
        _buttons = decoded.map((e) => ControlButton.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _buttons = [
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
              javaScriptEnabled: true,
              useHybridComposition: true, // Essencial para hardware acceleration no Android
              cacheEnabled: true,
              cacheMode: CacheMode.LOAD_DEFAULT, // Otimiza uso de cache
              supportZoom: false,
              builtInZoomControls: false,
              displayZoomControls: false,
              allowsInlineMediaPlayback: true,
              transparentBackground: false, // Desabilitado para melhor performance com WebGL
              hardwareAcceleration: true, // Força hardware acceleration
              mediaPlaybackRequiresUserGesture: false, // Permite autoplay de áudio do jogo
              // Configurações específicas para WebGL
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
              disableContextMenu: true,
              // Otimizações de renderização
              incognito: false,
              clearSessionCache: false,
              // Configurações de performance
              minimumFontSize: 1,
              textZoom: 100,
              // Suporte a WebGL
              // Previne bloqueio de conteúdo misto
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
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

            // Botões de Controle protegidos por PointerInterceptor
            PointerInterceptor(
            intercepting: _isGameStarted || _isEditMode, 
            child: Stack(
              children: [
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
                        color: Colors.blue.withOpacity(0.6),
                      ),
                      const SizedBox(width: 10),
                      _buildTopActionButton(
                        icon: Icons.refresh, 
                        onPressed: () => _webViewController?.reload(), 
                        color: Colors.red.withOpacity(0.6)
                      ),
                      const SizedBox(width: 10),
                      _buildTopActionButton(
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
                        color: (_isEditMode ? Colors.green : Colors.orange).withOpacity(0.6),
                      ),
                    ],
                  ),
                ),

                // Slider de Redimensionamento (apenas no modo Edit se houver seleção)
                if (_isEditMode && _selectedButtonId != null)
                  Positioned(
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
                              value: _buttons.firstWhere((b) => b.id == _selectedButtonId).size,
                              min: 40.0,
                              max: 200.0,
                              onChanged: (val) {
                                setState(() {
                                  _buttons.firstWhere((b) => b.id == _selectedButtonId).size = val;
                                });
                              },
                            ),
                          ),
                          const Icon(Icons.photo_size_select_large, color: Colors.white),
                        ],
                      ),
                    ),
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
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onPressed),
    );
  }

  Widget _buildMovableButton(ControlButton btn) {
    final isSelected = _selectedButtonId == btn.id;
    return Positioned(
      left: btn.x,
      top: btn.y,
      child: Listener(
        onPointerDown: (_) {
          if (_isEditMode) {
            setState(() => _selectedButtonId = btn.id);
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
                    btn.x += details.delta.dx;
                    btn.y += details.delta.dy;
                  });
                }
              : null,
          child: Opacity(
            opacity: _isEditMode ? 0.8 : 0.4,
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
      ),
    );
  }
}
