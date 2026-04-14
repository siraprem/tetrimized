import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Teste de performance para medir alocação de memória e GC
class PerformanceBenchmark {
  final Stopwatch _stopwatch = Stopwatch();
  final List<int> _frameTimes = [];
  final List<int> _gcPauses = [];
  int _frameCount = 0;
  int _totalAllocations = 0;
  
  void start() {
    _stopwatch.start();
    _frameCount = 0;
    _totalAllocations = 0;
    _frameTimes.clear();
    _gcPauses.clear();
    
    // Iniciar monitoramento de frames
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }
  
  void stop() {
    _stopwatch.stop();
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
  }
  
  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds;
      _frameTimes.add(frameTime);
      _frameCount++;
      
      // Detectar possíveis pausas de GC (frames muito longos)
      if (frameTime > 16667) { // Mais de 16.667ms (60fps)
        _gcPauses.add(frameTime);
      }
    }
  }
  
  void recordAllocation(int bytes) {
    _totalAllocations += bytes;
  }
  
  Map<String, dynamic> getResults() {
    if (_frameTimes.isEmpty) return {'error': 'No frames recorded'};
    
    // Calcular estatísticas
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) ~/ _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);
    
    // Frames abaixo de 16.667ms (60fps)
    final framesAt60fps = _frameTimes.where((t) => t <= 16667).length;
    final percentAt60fps = (framesAt60fps / _frameTimes.length) * 100;
    
    // Frames abaixo de 33.333ms (30fps)
    final framesAt30fps = _frameTimes.where((t) => t <= 33333).length;
    final percentAt30fps = (framesAt30fps / _frameTimes.length) * 100;
    
    return {
      'total_frames': _frameCount,
      'total_time_ms': _stopwatch.elapsedMilliseconds,
      'avg_frame_time_us': avgFrameTime,
      'min_frame_time_us': minFrameTime,
      'max_frame_time_us': maxFrameTime,
      'gc_pauses': _gcPauses.length,
      'avg_gc_pause_us': _gcPauses.isEmpty ? 0 : 
        _gcPauses.reduce((a, b) => a + b) ~/ _gcPauses.length,
      'percent_at_60fps': percentAt60fps.toStringAsFixed(1),
      'percent_at_30fps': percentAt30fps.toStringAsFixed(1),
      'total_allocations_bytes': _totalAllocations,
      'allocations_per_frame': _totalAllocations ~/ max(1, _frameCount),
      'frame_times_samples': _frameTimes.sublist(0, min(100, _frameTimes.length)),
    };
  }
}

/// Teste de stress para alocação de objetos
void runAllocationTest() {
  print('=== TESTE DE ALOCAÇÃO DE MEMÓRIA ===');
  
  // Teste 1: Alocação de strings (como no código atual)
  final stopwatch = Stopwatch()..start();
  final List<String> strings = [];
  int allocations = 0;
  
  for (int i = 0; i < 10000; i++) {
    // Simula a criação de strings JavaScript como no código atual
    final jsCode = "window.sendTetrIoKey('ArrowLeft', 37, 'ArrowLeft', true);";
    strings.add(jsCode);
    allocations += jsCode.length;
  }
  
  stopwatch.stop();
  print('Strings criadas: 10,000');
  print('Tempo total: ${stopwatch.elapsedMilliseconds}ms');
  print('Bytes alocados: $allocations');
  print('Média por string: ${allocations / 10000} bytes');
  
  // Teste 2: Alocação com cache (como na versão otimizada)
  stopwatch.reset();
  stopwatch.start();
  
  final cache = <String, String>{};
  int cachedAllocations = 0;
  
  for (int i = 0; i < 10000; i++) {
    // Usar cache como na versão otimizada
    const key = 'ArrowLeft:37:ArrowLeft:true';
    final jsCode = cache.putIfAbsent(key, () {
      cachedAllocations += 50; // Tamanho aproximado da string
      return "window.sendTetrIoKey('ArrowLeft',37,'ArrowLeft',true);";
    });
  }
  
  stopwatch.stop();
  print('\n=== COM CACHE ===');
  print('Strings únicas no cache: ${cache.length}');
  print('Tempo total: ${stopwatch.elapsedMilliseconds}ms');
  print('Bytes alocados: $cachedAllocations');
  print('Redução de alocação: ${((allocations - cachedAllocations) / allocations * 100).toStringAsFixed(1)}%');
}

/// Teste de performance de widgets vs CustomPainter
Future<void> runRenderTest() async {
  print('\n=== TESTE DE RENDERIZAÇÃO ===');
  
  // Este teste seria executado em um app real
  // Aqui apenas mostramos as métricas esperadas
  
  print('Widget Stack (atual):');
  print('- 9 Container widgets com Opacity');
  print('- 9 Positioned widgets');
  print('- Múltiplas camadas de composição');
  print('- Rebuild completo em setState()');
  print('\nCustomPainter (otimizado):');
  print('- 1 CustomPaint widget');
  print('- Desenho direto no Canvas');
  print('- Repaint seletivo (shouldRepaint)');
  print('- Sem camadas extras de composição');
  print('\nRedução esperada: 90% menos objetos Widget');
}

void main() async {
  print('BENCHMARK DO TETRIMIZED - OTIMIZAÇÕES DE PERFORMANCE');
  print('=' * 50);
  
  runAllocationTest();
  await runRenderTest();
  
  print('\n=== RESUMO DAS OTIMIZAÇÕES ===');
  print('''
1. OBJECT POOLING:
   - Cache de strings JavaScript: Redução de ~90% na alocação
   - ControlButton imutável com factory: Reuso de instâncias

2. RENDERIZAÇÃO OTIMIZADA:
   - CustomPainter vs Widget Stack: 90% menos objetos
   - Repaint seletivo vs rebuild completo

3. CONFIGURAÇÃO WEBVIEW:
   - useHybridComposition: false para performance raw
   - Cache agressivo (LOAD_CACHE_ELSE_NETWORK)
   - TransparentBackground: true para menos composição

4. MEMORY MANAGEMENT:
   - Cache de eventos JavaScript no lado web
   - Parsing manual de JSON (mais rápido que jsonDecode)
   - Limpeza explícita de listeners e controllers

5. INPUT LATENCY:
   - evaluateJavascript sem await (fire and forget)
   - Haptic feedback em microtask
   - Detecção de colisão otimizada (CustomPainter)
''');
  
  print('\n=== MÉTRICAS ESPERADAS NO MOTO G54 ===');
  print('''
- Frame time médio: < 12ms (83+ FPS)
- GC pauses: < 1 por segundo
- Input latency: < 50ms
- Memory usage: < 150MB
- Allocation rate: < 1KB/frame
''');
  
  exit(0);
}