import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<ControlButton> _buttons = [];
  bool _isEditMode = false;
  bool _hapticEnabled = true;
  bool _showSettingsMenu = false;
  double _buttonOpacity = 0.4;
  bool _hideButtons = false;
  final Map<String, bool> _buttonStates = {};
  String? _selectedButtonId;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadButtons();
    _loadSettings();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _webViewController?.stopLoading();
    _webViewController = null;
    super.dispose();
  }

  /// Injeção de Eventos com baixa latência e deduplicação de estado
  void _sendAction(ControlButton btn, bool isDown) {
    _sendKeyDirect(btn.key, btn.keyCode, btn.code, isDown, stateId: btn.id);
  }

  void _sendKeyDirect(String key, int keyCode, String code, bool isDown, {String? stateId}) {
    if (_webViewController == null) return;

    if (stateId != null) {
      final currentState = _buttonStates[stateId] ?? false;
      if (isDown == currentState) return;
      _buttonStates[stateId] = isDown;
    }

    final jsCode = "window.sendTetrIoKey('$key', $keyCode, '$code', $isDown);";
    _webViewController?.evaluateJavascript(source: jsCode);

    if (isDown && _hapticEnabled) {
      Future.microtask(() => HapticFeedback.lightImpact());
    }
  }

  // Script injetado: dispatch limpo em alvo cacheado, sem duplicações
  final _userScript = UserScript(
    source: """
      (function() {
        'use strict';
        let cachedTarget = null;
        let lastTargetCheck = 0;
        const TARGET_CHECK_INTERVAL = 3000;
        
        window.sendTetrIoKey = function(key, keyCode, code, isDown) {
          const now = Date.now();
          if (!cachedTarget || !cachedTarget.isConnected || (now - lastTargetCheck) > TARGET_CHECK_INTERVAL) {
            cachedTarget = document.querySelector('canvas') || 
                          document.querySelector('#game_canvas') || 
                          document.querySelector('#game') || 
                          window;
            lastTargetCheck = now;
          }
          const type = isDown ? 'keydown' : 'keyup';
          
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
              view: window,
              composed: true
            });
          } catch (e) {
            event = document.createEvent('KeyboardEvent');
            event.initKeyboardEvent(type, true, true, window, key, 0, '', false, '');
          }
          
          if (['ArrowLeft','ArrowRight','ArrowDown','ArrowUp',' ','z','x','a','c','Escape','r','Enter'].includes(key)) {
            event.preventDefault();
          }
          
          cachedTarget.dispatchEvent(event);
        };
        
        cachedTarget = document.querySelector('canvas') || window;
      })();
    """,
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  /// Captura de Teclado Físico / Gamepad USB ou Bluetooth
  void _handleKeyEvent(KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    if (!isDown && !isUp) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _sendKeyDirect('ArrowLeft', 37, 'ArrowLeft', isDown);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _sendKeyDirect('ArrowRight', 39, 'ArrowRight', isDown);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _sendKeyDirect('ArrowDown', 40, 'ArrowDown', isDown);
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.space) {
      _sendKeyDirect(' ', 32, 'Space', isDown);
    } else if (key == LogicalKeyboardKey.keyZ) {
      _sendKeyDirect('z', 90, 'KeyZ', isDown);
    } else if (key == LogicalKeyboardKey.keyX) {
      _sendKeyDirect('x', 88, 'KeyX', isDown);
    } else if (key == LogicalKeyboardKey.keyA) {
      _sendKeyDirect('a', 65, 'KeyA', isDown);
    } else if (key == LogicalKeyboardKey.keyC) {
      _sendKeyDirect('c', 67, 'KeyC', isDown);
    } else if (key == LogicalKeyboardKey.keyR) {
      _sendKeyDirect('r', 82, 'KeyR', isDown);
    } else if (key == LogicalKeyboardKey.escape) {
      _sendKeyDirect('Escape', 27, 'Escape', isDown);
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.gameButtonSelect) {
      _sendKeyDirect('Enter', 13, 'Enter', isDown);
    }
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
          _injectMissingDefaultButtons();
        } catch (_) {
          _loadDefaultButtons();
        }
      } else {
        _loadDefaultButtons();
      }
    } catch (_) {
      _loadDefaultButtons();
    }
  }

  List<ControlButton> _getDefaultButtonsList() {
    return [
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
    ];
  }

  void _loadDefaultButtons() {
    setState(() {
      _buttons = _getDefaultButtonsList();
    });
  }

  void _injectMissingDefaultButtons() {
    final defaultButtons = _getDefaultButtonsList();
    final loadedIds = _buttons.map((btn) => btn.id).toSet();
    bool changed = false;

    for (final def in defaultButtons) {
      if (!loadedIds.contains(def.id)) {
        _buttons.add(def);
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
      _saveButtons();
    }
  }

  Future<void> _saveButtons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_buttons.map((e) => e.toJson()).toList());
      await prefs.setString('control_buttons_v5', encoded);
      await prefs.setBool('haptic_enabled', _hapticEnabled);
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _buttonOpacity = prefs.getDouble('button_opacity') ?? 0.4;
        _hideButtons = prefs.getBool('hide_buttons') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('button_opacity', _buttonOpacity);
      await prefs.setBool('hide_buttons', _hideButtons);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri("https://tetr.io")),
              initialUserScripts: UnmodifiableListView<UserScript>([_userScript]),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useHybridComposition: true,
                cacheEnabled: true,
                cacheMode: CacheMode.LOAD_DEFAULT,
                supportZoom: false,
                builtInZoomControls: false,
                displayZoomControls: false,
                allowsInlineMediaPlayback: true,
                transparentBackground: false,
                hardwareAcceleration: true,
                mediaPlaybackRequiresUserGesture: false,
                disableVerticalScroll: false,
                disableHorizontalScroll: false,
                disableContextMenu: true,
                incognito: false,
                clearSessionCache: false,
                minimumFontSize: 1,
                textZoom: 100,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              ),
              onLoadStop: (controller, url) {
                setState(() => _isLoading = false);
                _webViewController = controller;
              },
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
                Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),

            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Camada de Botões Touch (só interage e existe se NÃO estiver oculta)
            if (!_hideButtons || _isEditMode)
              Positioned.fill(
                child: Stack(
                  children: _buttons.map((btn) => _buildMovableButton(btn)).toList(),
                ),
              ),

            // Botões de Ação do Topo
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
                    color: Colors.blue.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  _buildTopActionButton(
                    icon: Icons.refresh,
                    onPressed: () => _webViewController?.reload(),
                    color: Colors.red.withValues(alpha: 0.6),
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
                    color: (_isEditMode ? Colors.green : Colors.orange).withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  _buildTopActionButton(
                    icon: Icons.settings,
                    onPressed: () {
                      setState(() {
                        _showSettingsMenu = !_showSettingsMenu;
                      });
                    },
                    color: Colors.purple.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),

            // Slider de Tamanho no Modo Edição
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

            // Menu de Configurações
            if (_showSettingsMenu)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.75,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Cabeçalho
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
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
                                    setState(() => _showSettingsMenu = false);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Conteúdo
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                            setState(() => _buttonOpacity = value);
                                          },
                                          activeColor: Colors.purpleAccent,
                                          inactiveColor: Colors.white30,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${(_buttonOpacity * 100).round()}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Hide Buttons (Touch to game menus)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Switch(
                                        value: _hideButtons,
                                        onChanged: (value) {
                                          setState(() => _hideButtons = value);
                                        },
                                        activeThumbColor: Colors.purpleAccent,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _hideButtons
                                        ? 'Botões desligados. Toques vão direto para o site/menu.'
                                        : 'Botões virtuais ativos na tela.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Exportar e Importar Layout (Backup)
                                  const Text(
                                    'Layout Backup',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final encoded = jsonEncode(_buttons.map((e) => e.toJson()).toList());
                                            await Clipboard.setData(ClipboardData(text: encoded));
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Layout copiado para a área de transferência!'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.copy, color: Colors.blueAccent),
                                          label: const Text('Export Layout', style: TextStyle(color: Colors.blueAccent)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.blueAccent),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                                            final text = data?.text?.trim();
                                            if (text == null || text.isEmpty) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Área de transferência vazia!'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                            try {
                                              final List<dynamic> decoded = jsonDecode(text);
                                              final imported = decoded.map((e) => ControlButton.fromJson(e)).toList();
                                              if (imported.isNotEmpty) {
                                                setState(() {
                                                  _buttons = imported;
                                                });
                                                _injectMissingDefaultButtons();
                                                _saveButtons();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Layout importado e salvo com sucesso!'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (_) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Formato de layout inválido na área de transferência.'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.paste, color: Colors.greenAccent),
                                          label: const Text('Import Layout', style: TextStyle(color: Colors.greenAccent)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.greenAccent),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Botão para resetar posição dos controles
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _loadDefaultButtons();
                                      _saveButtons();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Botões restaurados para o layout padrão!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.restore, color: Colors.orangeAccent),
                                    label: const Text(
                                      'Reset Button Layout',
                                      style: TextStyle(color: Colors.orangeAccent),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.orangeAccent),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() => _showSettingsMenu = false);
                                        _saveSettings();
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMovableButton(ControlButton btn) {
    final isSelected = _selectedButtonId == btn.id;
    final alpha = _isEditMode ? 0.8 : _buttonOpacity;

    final bgColor = isSelected
        ? Colors.grey[400]!.withValues(alpha: alpha)
        : (_isEditMode
            ? Colors.white24.withValues(alpha: alpha)
            : Colors.grey[800]!.withValues(alpha: alpha));

    final borderColor = isSelected
        ? Colors.yellow.withValues(alpha: alpha)
        : (_isEditMode
            ? Colors.red.withValues(alpha: alpha)
            : Colors.white.withValues(alpha: alpha));

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
          child: Container(
            width: btn.size,
            height: btn.size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 3 : 2,
              ),
            ),
            child: Center(
              child: Text(
                btn.label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.black.withValues(alpha: alpha)
                      : Colors.white.withValues(alpha: alpha),
                  fontWeight: FontWeight.bold,
                  fontSize: btn.size * 0.25,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
