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
  bool _isGameStarted = false;
  List<ControlButton> _buttons = [];
  double _baseScaleSize = 80.0;
  bool _isEditMode = false;
  final Map<String, bool> _buttonStates = {};
  String? _selectedButtonId;

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

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('control_buttons');
    
    if (saved != null) {
      final decoded = jsonDecode(saved) as List;
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
    final encoded = jsonEncode(_buttons.map((b) => b.toJson()).toList());
    await prefs.setString('control_buttons', encoded);
  }

  void _sendAction(ControlButton btn, bool isDown) {
    if (_webViewController == null) return;

    final currentState = _buttonStates[btn.id] ?? false;
    if (isDown == currentState) return;
    
    // LOG DE DEBUG
    print("Botão ${btn.label} ${isDown ? 'pressionado' : 'liberado'}: ${btn.keyCode} (${btn.key})");
    
    _buttonStates[btn.id] = isDown;

    // Otimização: Usar runJavascript em vez de evaluateJavascript para menor latência
    // evaluateJavascript retorna um Future, enquanto runJavascript não espera resultado
    final jsCode = "window.sendTetrIoKey('${btn.key}', ${btn.keyCode}, '${btn.code}', $isDown);";
    
    // Usar evaluateJavascript (método padrão)
    _webViewController?.evaluateJavascript(source: jsCode);
  }

  void _resetButtons() {
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
    _saveButtons();
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return PointerInterceptor(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: IconButton(
          icon: Icon(icon, size: 24, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildButton(ControlButton btn) {
    final isSelected = _selectedButtonId == btn.id;
    final isPressed = _buttonStates[btn.id] ?? false;

    return Positioned(
      left: btn.x,
      top: btn.y,
      child: Listener(
        onPointerDown: (_) {
          print("Pointer DOWN no botão ${btn.label} (${btn.id}) - Edit Mode: $_isEditMode");
          if (_isEditMode) {
            setState(() => _selectedButtonId = btn.id);
          } else {
            _sendAction(btn, true);
          }
        },
        onPointerUp: (_) {
          print("Pointer UP no botão ${btn.label} (${btn.id})");
          _isEditMode ? null : _sendAction(btn, false);
        },
        onPointerCancel: (_) {
          print("Pointer CANCEL no botão ${btn.label} (${btn.id})");
          _isEditMode ? null : _sendAction(btn, false);
        },
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
          onPanEnd: _isEditMode ? (_) => _saveButtons() : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // InAppWebView como primeiro item (fundo)
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('https://tetr.io')),
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
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
              overScrollMode: OverScrollMode.NEVER,
              useWideViewPort: true,
              loadWithOverviewMode: true,
              safeBrowsingEnabled: true,
              clearSessionCache: false,
              domStorageEnabled: true,
              databaseEnabled: true,
              javaScriptCanOpenWindowsAutomatically: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'gameStarted',
                callback: (args) {
                  print("Game started via JavaScript");
                  setState(() => _isGameStarted = true);
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'gameStopped',
                callback: (args) {
                  print("Game stopped via JavaScript");
                  setState(() => _isGameStarted = false);
                },
              );
            },
            onLoadStart: (controller, url) {
              print("WebView loading: $url");
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              print("WebView loaded: $url");
              setState(() => _isLoading = false);
            },
            onReceivedError: (controller, request, error) {
              print("WebView error: $error");
              setState(() => _isLoading = false);
            },
          ),

          // Overlay de loading
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Botões de controle
          ..._buttons.map(_buildButton).toList(),

          // Barra de ações superior
          if (!_isLoading)
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _buildTopActionButton(
                    icon: Icons.refresh, 
                    onPressed: () {
                      print("Refresh button pressed");
                      _webViewController?.reload();
                    }, 
                    color: Colors.red.withOpacity(0.6)
                  ),
                  const SizedBox(width: 10),
                  _buildTopActionButton(
                    icon: _isEditMode ? Icons.save : Icons.edit,
                    onPressed: () {
                      print("Edit button pressed - Toggling edit mode");
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

          // Slider de redimensionamento (apenas no modo Edit se houver seleção)
          if (_isEditMode && _selectedButtonId != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: PointerInterceptor(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tamanho do Botão',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Slider(
                        value: _buttons.firstWhere((b) => b.id == _selectedButtonId).size,
                        min: 40,
                        max: 120,
                        divisions: 8,
                        label: '${_buttons.firstWhere((b) => b.id == _selectedButtonId).size.round()}',
                        onChanged: (value) {
                          setState(() {
                            final btn = _buttons.firstWhere((b) => b.id == _selectedButtonId);
                            btn.size = value;
                          });
                        },
                        onChangeEnd: (_) => _saveButtons(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}