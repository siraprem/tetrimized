import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// V3: ESTABILIDADE ABSOLUTA - 60Hz ROCK SOLID
// ============================================================================

/// ControlButton extremamente otimizado
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
  
  factory ControlButton.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Criando ControlButton from JSON: $json');
      return ControlButton(
        id: json['id']?.toString() ?? 'unknown',
        label: json['label']?.toString() ?? '?',
        key: json['key']?.toString() ?? 'Escape',
        keyCode: (json['keyCode'] as num?)?.toInt() ?? 27,
        code: json['code']?.toString() ?? 'Escape',
        x: (json['x'] as num?)?.toDouble() ?? 0.0,
        y: (json['y'] as num?)?.toDouble() ?? 0.0,
        size: (json['size'] as num?)?.toDouble() ?? 80.0,
      );
    } catch (e) {
      print('❌ Erro crítico em ControlButton.fromJson: $e');
      print('❌ JSON problemático: $json');
      // Retorna um botão padrão em caso de erro
      return ControlButton(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        label: 'ERR',
        key: 'Escape',
        keyCode: 27,
        code: 'Escape',
        x: 100.0,
        y: 100.0,
        size: 50.0,
      );
    }
  }
}

/// CustomPainter V3: Cache inteligente apenas no edit mode
class ControlButtonPainterV3 extends CustomPainter {
  final List<ControlButton> buttons;
  final bool isEditMode;
  final String? selectedId;
  final Map<String, bool> buttonStates;
  
  ControlButtonPainterV3({
    required this.buttons,
    required this.isEditMode,
    required this.selectedId,
    required this.buttonStates,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Desenha botões apenas no modo jogo (não editável)
    if (!isEditMode) {
      for (final btn in buttons) {
        _drawGameButton(canvas, btn, size);
      }
    }
  }
  
  void _drawGameButton(Canvas canvas, ControlButton btn, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final x = btn.x * size.width / 1000.0;
    final y = btn.y * size.height / 1000.0;
    final radius = btn.size / 2;
    
    canvas.drawCircle(Offset(x, y), radius, paint);
    
    // Texto do botão
    final textPainter = TextPainter(
      text: TextSpan(
        text: btn.label,
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }
  
  @override
  bool shouldRepaint(ControlButtonPainterV3 oldDelegate) {
    return buttons != oldDelegate.buttons ||
           isEditMode != oldDelegate.isEditMode ||
           selectedId != oldDelegate.selectedId;
  }
}

class TetrIoPageV3 extends StatefulWidget {
  const TetrIoPageV3({super.key});

  @override
  State<TetrIoPageV3> createState() => _TetrIoPageV3State();
}

class _TetrIoPageV3State extends State<TetrIoPageV3> {
  // ==========================================================================
  // ESTADO PRINCIPAL
  // ==========================================================================
  late InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isGameStarted = false;
  bool _isEditMode = false;
  bool _hapticEnabled = true;
  String? _selectedButtonId;
  final Map<String, bool> _buttonStates = HashMap();
  List<ControlButton> _buttons = [];
  final ValueNotifier<String?> _selectedButtonNotifier = ValueNotifier(null);

  // ==========================================================================
  // CICLO DE VIDA
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    print('🚀 TetrIoPageV3 iniciando...');
    _loadButtons();
    _selectedButtonNotifier.addListener(() {
      setState(() {
        _selectedButtonId = _selectedButtonNotifier.value;
      });
    });
  }

  @override
  void dispose() {
    _selectedButtonNotifier.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CARREGAMENTO E SALVAMENTO DE BOTÕES (REATIVO)
  // ==========================================================================
  Future<void> _loadButtons() async {
    try {
      print('🚀 Iniciando carregamento de botões...');
      final prefs = await SharedPreferences.getInstance();
      final String? buttonsJson = prefs.getString('control_buttons_v5');
      
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      print('✅ Haptic carregado: $_hapticEnabled');

      if (buttonsJson != null && buttonsJson.isNotEmpty) {
        print('📦 JSON encontrado, tamanho: ${buttonsJson.length} caracteres');
        print('🔍 Primeiros 200 chars: ${buttonsJson.substring(0, buttonsJson.length > 200 ? 200 : buttonsJson.length)}');
        
        try {
          // Usa jsonDecode para parsing seguro
          final List<dynamic> jsonList = jsonDecode(buttonsJson);
          print('🔢 ${jsonList.length} itens decodificados via jsonDecode');
          
          final buttons = <ControlButton>[];
          
          for (var i = 0; i < jsonList.length; i++) {
            try {
              final Map<String, dynamic> jsonMap = jsonList[i] as Map<String, dynamic>;
              final button = ControlButton.fromJson(jsonMap);
              buttons.add(button);
              print('✅ Botão ${i+1} carregado: ${button.id} (x=${button.x}, y=${button.y})');
            } catch (e) {
              print('❌ Erro ao decodificar botão ${i+1}: $e');
              print('❌ Item problemático: ${jsonList[i]}');
            }
          }
          
          if (mounted) {
            setState(() {
              _buttons = buttons;
            });
          }
          print('🎉 Botões carregados com sucesso: ${buttons.length} botões');
        } catch (e) {
          print('❌ Erro ao processar JSON com jsonDecode: $e');
          print('❌ JSON problemático: $buttonsJson');
          _loadDefaultButtons();
        }
      } else {
        print('📭 Nenhum JSON encontrado, carregando botões padrão');
        _loadDefaultButtons();
      }
    } catch (e) {
      print('❌ Erro crítico em _loadButtons(): $e');
      print('❌ Stack trace: ${e.toString()}');
      _loadDefaultButtons();
    }
  }

  void _loadDefaultButtons() {
    print('🔄 Carregando botões padrão...');
    if (mounted) {
      setState(() {
        _buttons = [
          ControlButton(id: 'btn_left', label: '←', key: 'ArrowLeft', keyCode: 37, code: 'ArrowLeft', x: 100.0, y: 500.0, size: 80.0),
          ControlButton(id: 'btn_right', label: '→', key: 'ArrowRight', keyCode: 39, code: 'ArrowRight', x: 300.0, y: 500.0, size: 80.0),
          ControlButton(id: 'btn_soft', label: '↓', key: 'ArrowDown', keyCode: 40, code: 'ArrowDown', x: 200.0, y: 600.0, size: 80.0),
          ControlButton(id: 'btn_hard', label: 'SPACE', key: ' ', keyCode: 32, code: 'Space', x: 200.0, y: 400.0, size: 80.0),
          ControlButton(id: 'btn_rotate_cw', label: 'Z', key: 'z', keyCode: 90, code: 'KeyZ', x: 400.0, y: 500.0, size: 80.0),
          ControlButton(id: 'btn_rotate_ccw', label: 'X', key: 'x', keyCode: 88, code: 'KeyX', x: 500.0, y: 500.0, size: 80.0),
          ControlButton(id: 'btn_hold', label: 'C', key: 'c', keyCode: 67, code: 'KeyC', x: 600.0, y: 500.0, size: 80.0),
          ControlButton(id: 'btn_restart', label: 'R', key: 'r', keyCode: 82, code: 'KeyR', x: 700.0, y: 500.0, size: 80.0),
          ControlButton(id: 'btn_pause', label: 'ESC', key: 'Escape', keyCode: 27, code: 'Escape', x: 800.0, y: 500.0, size: 80.0),
        ];
      });
    }
    print('✅ Botões padrão carregados: 9 botões');
  }

  Future<void> _saveButtons() async {
    try {
      print('💾 Iniciando salvamento de botões...');
      final prefs = await SharedPreferences.getInstance();
      
      // Converte lista de botões para lista de maps
      final List<Map<String, dynamic>> buttonsJson = _buttons.map((btn) => btn.toJson()).toList();
      
      // Usa jsonEncode para serialização segura
      final jsonString = jsonEncode(buttonsJson);
      print('📝 JSON gerado via jsonEncode, tamanho: ${jsonString.length} caracteres');
      print('🔍 Primeiros 200 chars: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
      
      await prefs.setString('control_buttons_v5', jsonString);
      await prefs.setBool('haptic_enabled', _hapticEnabled);
      
      print('✅ Botões salvos com sucesso! ${_buttons.length} botões');
      print('✅ Haptic salvo: $_hapticEnabled');
    } catch (e) {
      print('❌ Erro ao salvar botões: $e');
      print('❌ Stack trace: ${e.toString()}');
    }
  }

  Future<void> _resetLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('control_buttons_v5');
      await _loadDefaultButtons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Layout resetado para padrão')),
        );
      }
    } catch (e) {
      print('❌ Erro ao resetar layout: $e');
    }
  }

  // ==========================================================================
  // LÓGICA DE DETECÇÃO DE JOGO
  // ==========================================================================
  void _setupGameDetection() {
    const js = """
(function() {
  let checkScheduled = false;
  
  function checkGameState() {
    checkScheduled = false;
    
    // Detecta se o jogo está rodando
    const gameRunning = document.querySelector('.game-container') !== null ||
                       document.querySelector('#game') !== null ||
                       document.querySelector('canvas') !== null;
    
    if (gameRunning) {
      window.flutter_inappwebview.callHandler('gameStarted');
    } else {
      window.flutter_inappwebview.callHandler('gameStopped');
    }
  }
  
  function scheduleCheck() {
    if (!checkScheduled) {
      checkScheduled = true;
      setTimeout(checkGameState, 100);
    }
  }
  
  const observer = new MutationObserver(scheduleCheck);
  observer.observe(document.body, { 
    childList: true, 
    subtree: true,
    attributes: false,
    characterData: false
  });
  
  setTimeout(checkGameState, 1000);
})();
""";
    _webViewController?.evaluateJavascript(source: js);
  }

  // ==========================================================================
  // LÓGICA DE INTERAÇÃO COM BOTÕES (REATIVA)
  // ==========================================================================
  ControlButton? _findButtonAt(Offset position) {
    for (final btn in _buttons) {
      final dx = position.dx - btn.x;
      final dy = position.dy - btn.y;
      final distance = dx * dx + dy * dy;
      if (distance <= btn.size * btn.size / 4) {
        return btn;
      }
    }
    return null;
  }

  void _onButtonPressed(ControlButton btn) {
    if (_isEditMode) {
      // No modo edição, seleciona o botão
      _selectedButtonNotifier.value = btn.id;
      print('🎯 Botão selecionado para edição: ${btn.id}');
    } else {
      // No modo jogo, envia o keycode
      if (_hapticEnabled) {
        HapticFeedback.lightImpact();
      }
      _webViewController?.evaluateJavascript(source: '''
        const event = new KeyboardEvent('keydown', {
          key: '${btn.key}',
          code: '${btn.code}',
          keyCode: ${btn.keyCode},
          which: ${btn.keyCode},
          bubbles: true
        });
        document.dispatchEvent(event);
        
        setTimeout(() => {
          const eventUp = new KeyboardEvent('keyup', {
            key: '${btn.key}',
            code: '${btn.code}',
            keyCode: ${btn.keyCode},
            which: ${btn.keyCode},
            bubbles: true
          });
          document.dispatchEvent(eventUp);
        }, 100);
      ''');
      print('🎮 Botão pressionado: ${btn.label} (${btn.keyCode})');
    }
  }

  // ==========================================================================
  // WIDGETS DE BOTÕES REATIVOS
  // ==========================================================================
  Widget _buildMovableButton(ControlButton btn) {
    final isSelected = _selectedButtonId == btn.id;
    
    return Positioned(
      left: btn.x - btn.size / 2,
      top: btn.y - btn.size / 2,
      child: GestureDetector(
        onPanDown: (details) {
          if (_isEditMode) {
            _selectedButtonNotifier.value = btn.id;
          }
        },
        onPanUpdate: _isEditMode ? (details) {
          // ATUALIZAÇÃO REATIVA: setState envolve a atualização direta da lista
          setState(() {
            final index = _buttons.indexWhere((b) => b.id == btn.id);
            if (index != -1) {
              final newX = (btn.x + details.delta.dx).clamp(0.0, 1000.0);
              final newY = (btn.y + details.delta.dy).clamp(0.0, 1000.0);
              
              _buttons[index] = ControlButton(
                id: btn.id,
                label: btn.label,
                key: btn.key,
                keyCode: btn.keyCode,
                code: btn.code,
                x: newX,
                y: newY,
                size: btn.size,
              );
              
              print('📐 Botão ${btn.id} movido para: x=$newX, y=$newY');
            }
          });
        } : null,
        onPanEnd: _isEditMode ? (details) {
          _saveButtons();
        } : null,
        onTap: () => _onButtonPressed(btn),
        child: Container(
          width: btn.size,
          height: btn.size,
          decoration: BoxDecoration(
            color: _isEditMode 
                ? (isSelected ? Colors.orange.withOpacity(0.8) : Colors.blue.withOpacity(0.7))
                : Colors.blue.withOpacity(0.7),
            borderRadius: BorderRadius.circular(btn.size / 2),
            border: _isEditMode && isSelected
                ? Border.all(color: Colors.white, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              btn.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: btn.size * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD PRINCIPAL (UI REATIVA)
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1ª CAMADA: WebView com gestureRecognizers
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('https://tetr.io')),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: false,
              disableVerticalScroll: false,
              disableHorizontalScroll: false,
              useHybridComposition: true,
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onLoadStop: (controller, url) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
              _webViewController = controller;
              _setupGameDetection();
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('🌐 WebView: ${consoleMessage.message}');
            },
            onLoadError: (controller, url, code, message) {
              print('❌ Erro ao carregar: $message ($code)');
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            javascriptHandlers: {
              JavascriptHandler(
                handlerName: 'gameStarted',
                callback: (args) {
                  if (mounted) {
                    setState(() => _isGameStarted = true);
                  }
                  print('🎮 Jogo iniciado detectado');
                },
              ),
              JavascriptHandler(
                handlerName: 'gameStopped',
                callback: (args) {
                  if (mounted) {
                    setState(() => _isGameStarted = false);
                  }
                  print('⏸️ Jogo parado detectado');
                },
              ),
            },
          ),

          // Indicador de Loading
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // BOTÕES REATIVOS (renderizados como Positioned widgets)
          ..._buttons.map((btn) => _buildMovableButton(btn)),

          // Botões de ação (canto superior direito)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.restart_alt,
                  color: Colors.deepPurple,
                  onPressed: _resetLayout,
                  tooltip: 'Reset Layout',
                ),
                _buildActionButton(
                  icon: Icons.refresh,
                  color: Colors.green,
                  onPressed: () {
                    _webViewController?.reload();
                    if (_hapticEnabled) HapticFeedback.lightImpact();
                  },
                  tooltip: 'Recarregar',
                ),
                _buildActionButton(
                  icon: _isEditMode ? Icons.save : Icons.edit,
                  color: _isEditMode ? Colors.orange : Colors.blue,
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                      if (!_isEditMode) {
                        _selectedButtonId = null;
                        _saveButtons();
                      }
                    });
                    if (_hapticEnabled) HapticFeedback.lightImpact();
                  },
                  tooltip: _isEditMode ? 'Salvar' : 'Editar',
                ),
                _buildActionButton(
                  icon: _hapticEnabled ? Icons.vibration : Icons.vibration_off,
                  color: Colors.purple,
                  onPressed: () {
                    setState(() {
                      _hapticEnabled = !_hapticEnabled;
                    });
                    _saveButtons();
                    if (_hapticEnabled) HapticFeedback.lightImpact();
                  },
                  tooltip: _hapticEnabled ? 'Desativar Haptic' : 'Ativar Haptic',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}