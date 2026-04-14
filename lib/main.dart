import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
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
  bool _showSettingsMenu = false;
  double _buttonOpacity = 0.4;
  bool _hideButtons = false;
  final Map<String, bool> _buttonStates = {};
  String? _selectedButtonId;

  @override
  void initState() {
    super.initState();
    print('🚀 TetrIoPage iniciando...');
    _loadButtons();
    _loadSettings();
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
          
          // Lógica especial para a tecla Enter (abrir chat)
          if (key === 'Enter') {
            const settings = {
              key: 'Enter',
              code: 'Enter',
              keyCode: 13,
              which: 13,
              bubbles: true,
              cancelable: true,
              view: window
            };
            
            // Disparar a sequência completa de eventos de teclado
            document.dispatchEvent(new KeyboardEvent('keydown', settings));
            document.dispatchEvent(new KeyboardEvent('keypress', settings));
            document.dispatchEvent(new KeyboardEvent('keyup', settings));
            
            // Prevenir comportamento padrão
            return;
          }
          
          // Criar evento otimizado para performance (para outras teclas)
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
          if (['ArrowLeft','ArrowRight','ArrowDown',' ','z','x','a','c','Escape','r','Enter'].includes(key)) {
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? buttonsJson = prefs.getString('control_buttons_v5');
      setState(() {
        _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      });

      if (buttonsJson != null && buttonsJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(buttonsJson);
          setState(() {
            _buttons = decoded.map((e) => ControlButton.fromJson(e)).toList();
          });
          print('✅ Botões carregados com sucesso: ${_buttons.length} botões');
          
          // Verificar e injetar botões padrão faltantes
          _injectMissingDefaultButtons();
        } catch (e) {
          print('❌ Erro ao decodificar JSON: $e');
          print('❌ JSON recebido: $buttonsJson');
          _loadDefaultButtons();
        }
      } else {
        print('ℹ️ Nenhum JSON salvo, carregando botões padrão');
        _loadDefaultButtons();
      }
    } catch (e) {
      print('❌ Erro crítico em _loadButtons: $e');
      _loadDefaultButtons();
    }
  }

  void _loadDefaultButtons() {
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
        ControlButton(id: 'reset', label: 'R', key: 'r', keyCode: 82, code: 'KeyR', x: 80, y: 20, size: 50),
        ControlButton(id: 'chat', label: 'ENTER', key: 'Enter', keyCode: 13, code: 'Enter', x: 140, y: 20, size: 50),
      ];
    });
    print('✅ Botões padrão carregados: ${_buttons.length} botões');
  }

  void _injectMissingDefaultButtons() {
    // Lista de IDs de botões padrão obrigatórios
    final defaultButtonIds = [
      'left', 'right', 'soft', 'hard', 'rotL', 'rotR', 'rot180', 'hold', 'pause', 'reset', 'chat'
    ];
    
    // IDs dos botões atualmente carregados
    final loadedIds = _buttons.map((btn) => btn.id).toList();
    
    // Encontrar IDs faltantes
    final missingIds = defaultButtonIds.where((id) => !loadedIds.contains(id)).toList();
    
    if (missingIds.isNotEmpty) {
      print('⚠️ Botões padrão faltantes detectados: $missingIds');
      print('🔄 Injetando botões faltantes automaticamente...');
      
      setState(() {
        // Adicionar botões padrão faltantes
        for (final id in missingIds) {
          ControlButton? defaultButton;
          
          // Definir o botão padrão baseado no ID
          switch (id) {
            case 'left':
              defaultButton = ControlButton(id: 'left', label: '←', key: 'ArrowLeft', keyCode: 37, code: 'ArrowLeft', x: 20, y: 250);
              break;
            case 'right':
              defaultButton = ControlButton(id: 'right', label: '→', key: 'ArrowRight', keyCode: 39, code: 'ArrowRight', x: 140, y: 250);
              break;
            case 'soft':
              defaultButton = ControlButton(id: 'soft', label: '↓', key: 'ArrowDown', keyCode: 40, code: 'ArrowDown', x: 80, y: 330);
              break;
            case 'hard':
              defaultButton = ControlButton(id: 'hard', label: 'SPACE', key: ' ', keyCode: 32, code: 'Space', x: 80, y: 170);
              break;
            case 'rotL':
              defaultButton = ControlButton(id: 'rotL', label: 'Z', key: 'z', keyCode: 90, code: 'KeyZ', x: 550, y: 250);
              break;
            case 'rotR':
              defaultButton = ControlButton(id: 'rotR', label: 'X', key: 'x', keyCode: 88, code: 'KeyX', x: 670, y: 250);
              break;
            case 'rot180':
              defaultButton = ControlButton(id: 'rot180', label: 'A', key: 'a', keyCode: 65, code: 'KeyA', x: 610, y: 330);
              break;
            case 'hold':
              defaultButton = ControlButton(id: 'hold', label: 'C', key: 'c', keyCode: 67, code: 'KeyC', x: 610, y: 140);
              break;
            case 'pause':
              defaultButton = ControlButton(id: 'pause', label: 'ESC', key: 'Escape', keyCode: 27, code: 'Escape', x: 20, y: 20, size: 50);
              break;
            case 'reset':
              defaultButton = ControlButton(id: 'reset', label: 'R', key: 'r', keyCode: 82, code: 'KeyR', x: 80, y: 20, size: 50);
              break;
            case 'chat':
              defaultButton = ControlButton(id: 'chat', label: 'ENTER', key: 'Enter', keyCode: 13, code: 'Enter', x: 140, y: 20, size: 50);
              break;
          }
          
          if (defaultButton != null) {
            _buttons.add(defaultButton);
            print('   ✅ Injetado: $id (${defaultButton.label})');
          }
        }
      });
      
      // Salvar a lista atualizada
      _saveButtons();
      print('✅ Injeção concluída. Total de botões: ${_buttons.length}');
    } else {
      print('✅ Todos os botões padrão estão presentes na lista carregada.');
    }
  }

  Future<void> _saveButtons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_buttons.map((e) => e.toJson()).toList());
      await prefs.setString('control_buttons_v5', encoded);
      await prefs.setBool('haptic_enabled', _hapticEnabled);
      print('✅ Botões salvos com sucesso: ${_buttons.length} botões');
      print('✅ JSON salvo: ${encoded.length} caracteres');
    } catch (e) {
      print('❌ Erro ao salvar botões: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _buttonOpacity = prefs.getDouble('button_opacity') ?? 0.4;
        _hideButtons = prefs.getBool('hide_buttons') ?? false;
      });
      print('✅ Settings loaded: Opacity=$_buttonOpacity, Hide=$_hideButtons');
    } catch (e) {
      print('❌ Erro ao carregar configurações: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('button_opacity', _buttonOpacity);
      await prefs.setBool('hide_buttons', _hideButtons);
      print('✅ Settings saved: Opacity=$_buttonOpacity, Hide=$_hideButtons');
    } catch (e) {
      print('❌ Erro ao salvar configurações: $e');
    }
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
              disableVerticalScroll: false,
              disableHorizontalScroll: false,
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
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
              Factory<HorizontalDragGestureRecognizer>(
                () => HorizontalDragGestureRecognizer(),
              ),
              Factory<EagerGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
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
                      const SizedBox(width: 10),
                      _buildTopActionButton(
                        icon: Icons.settings,
                        onPressed: () {
                          setState(() {
                            _showSettingsMenu = !_showSettingsMenu;
                          });
                        },
                        color: Colors.purple.withOpacity(0.6),
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

                // Menu de Configurações (Glassmorphism)
                if (_showSettingsMenu)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.height * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.srcOver,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Cabeçalho do Menu
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Tetrimized Settings',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _showSettingsMenu = false;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Conteúdo do Menu
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Slider de Transparência dos Botões
                                            const Text(
                                              'Button Opacity',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.opacity, color: Colors.white70, size: 20),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Slider(
                                                    value: _buttonOpacity,
                                                    min: 0.1,
                                                    max: 0.8,
                                                    divisions: 7,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _buttonOpacity = value;
                                                      });
                                                    },
                                                    activeColor: Colors.purpleAccent,
                                                    inactiveColor: Colors.white30,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  '${(_buttonOpacity * 100).round()}%',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Toggle para Esconder Botões
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Hide Buttons',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Switch(
                                                  value: _hideButtons,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _hideButtons = value;
                                                    });
                                                  },
                                                  activeThumbColor: Colors.purpleAccent,
                                                  activeTrackColor: Colors.purpleAccent.withOpacity(0.5),
                                                  inactiveTrackColor: Colors.grey,
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 10),
                                            Text(
                                              _hideButtons 
                                                ? 'Os botões estão ocultos. Toque na tela para mostrar temporariamente.'
                                                : 'Os botões estão visíveis.',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            
                                            const Spacer(),
                                            
                                            // Botão de Aplicar
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _showSettingsMenu = false;
                                                    _saveSettings();
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purpleAccent,
                                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Apply Settings',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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
            opacity: _hideButtons ? 0.0 : (_isEditMode ? 0.8 : _buttonOpacity),
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
