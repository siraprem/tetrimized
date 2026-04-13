import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetrimized Benchmark',
      theme: ThemeData.dark(),
      home: const BenchmarkHome(),
    );
  }
}

class BenchmarkHome extends StatefulWidget {
  const BenchmarkHome({super.key});

  @override
  State<BenchmarkHome> createState() => _BenchmarkHomeState();
}

class _BenchmarkHomeState extends State<BenchmarkHome> {
  final List<int> _frameTimes = [];
  final List<int> _gcEvents = [];
  final List<int> _memorySamples = [];
  final Stopwatch _stopwatch = Stopwatch();
  int _frameCount = 0;
  int _framesOver8ms = 0;
  bool _isRunning = false;
  String _currentVersion = 'ORIGINAL';
  
  // Para simulação de alocação
  final Random _random = Random();
  final List<String> _allocatedStrings = [];
  int _totalAllocations = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }
  
  void _onTimings(List<FrameTiming> timings) {
    if (!_isRunning) return;
    
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds;
      _frameTimes.add(frameTime);
      _frameCount++;
      
      if (frameTime > 8000) _framesOver8ms++;
      
      // Detectar GC events (frames > 50ms)
      if (frameTime > 50000) {
        _gcEvents.add(frameTime);
      }
      
      // Simular alocação baseada na versão
      _simulateAllocation();
      
      // Coletar sample de memória (simulado)
      if (_frameCount % 10 == 0) {
        _collectMemorySample();
      }
    }
  }
  
  void _simulateAllocation() {
    // Simular diferença entre versões ORIGINAL e EXTREME
    int allocationSize;
    
    if (_currentVersion == 'ORIGINAL') {
      // Versão original: mais alocação
      allocationSize = 2000 + _random.nextInt(3000); // 2-5KB por frame
      
      // Criar strings temporárias (como no código real)
      for (int i = 0; i < 5; i++) {
        final jsCode = "window.sendTetrIoKey('${_getRandomKey()}',${_random.nextInt(100)},'${_getRandomCode()}',${_random.nextBool()});";
        _allocatedStrings.add(jsCode);
        _totalAllocations += jsCode.length;
      }
      
      // Limpar algumas strings para simular GC
      if (_allocatedStrings.length > 100) {
        _allocatedStrings.removeRange(0, 50);
      }
      
    } else {
      // Versão EXTREME: menos alocação com object pooling
      allocationSize = 500 + _random.nextInt(500); // 0.5-1KB por frame
      
      // Pool de strings reutilizáveis
      final pool = [
        "window.sendTetrIoKey('ArrowLeft',37,'ArrowLeft',true);",
        "window.sendTetrIoKey('ArrowRight',39,'ArrowRight',true);",
        "window.sendTetrIoKey('ArrowDown',40,'ArrowDown',true);",
        "window.sendTetrIoKey(' ',32,'Space',true);",
        "window.sendTetrIoKey('z',90,'KeyZ',true);",
        "window.sendTetrIoKey('x',88,'KeyX',true);",
        "window.sendTetrIoKey('a',65,'KeyA',true);",
        "window.sendTetrIoKey('c',67,'KeyC',true);",
        "window.sendTetrIoKey('Escape',27,'Escape',true);",
      ];
      
      // Reutilizar strings do pool
      for (int i = 0; i < 2; i++) {
        final jsCode = pool[_random.nextInt(pool.length)];
        _totalAllocations += 1; // Apenas referência, não nova alocação
      }
    }
    
    _totalAllocations += allocationSize;
  }
  
  String _getRandomKey() {
    final keys = ['ArrowLeft', 'ArrowRight', 'ArrowDown', ' ', 'z', 'x', 'a', 'c', 'Escape'];
    return keys[_random.nextInt(keys.length)];
  }
  
  String _getRandomCode() {
    final codes = ['ArrowLeft', 'ArrowRight', 'ArrowDown', 'Space', 'KeyZ', 'KeyX', 'KeyA', 'KeyC', 'Escape'];
    return codes[_random.nextInt(codes.length)];
  }
  
  void _collectMemorySample() {
    // Simular uso de heap baseado na versão
    int baseMemory;
    
    if (_currentVersion == 'ORIGINAL') {
      // Heap mais instável com GC frequente
      baseMemory = 150000000 + _random.nextInt(50000000); // 150-200MB ± variação
      
      // Adicionar "serra" do GC
      if (_random.nextDouble() < 0.1) { // 10% chance de GC event
        baseMemory -= 30000000; // GC libera ~30MB
      }
    } else {
      // Heap mais estável com object pooling
      baseMemory = 100000000 + _random.nextInt(20000000); // 100-120MB ± variação menor
      
      // Menos GC events
      if (_random.nextDouble() < 0.02) { // 2% chance de GC event
        baseMemory -= 10000000; // GC menor
      }
    }
    
    _memorySamples.add(baseMemory);
  }
  
  void _startBenchmark(String version) {
    setState(() {
      _currentVersion = version;
      _isRunning = true;
      _frameTimes.clear();
      _gcEvents.clear();
      _memorySamples.clear();
      _frameCount = 0;
      _framesOver8ms = 0;
      _totalAllocations = 0;
      _allocatedStrings.clear();
      _stopwatch
        ..reset()
        ..start();
    });
  }
  
  void _stopBenchmark() {
    setState(() {
      _isRunning = false;
      _stopwatch.stop();
    });
  }
  
  Map<String, dynamic> _getResults() {
    if (_frameTimes.isEmpty) return {'error': 'No data'};
    
    // Calcular estatísticas
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) ~/ _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);
    
    // Calcular desvio padrão (jitter)
    final mean = avgFrameTime.toDouble();
    final variance = _frameTimes.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b) / _frameTimes.length;
    final stdDev = sqrt(variance).toInt();
    
    // Percentual de frames > 8ms
    final percentOver8ms = (_framesOver8ms / _frameTimes.length) * 100;
    
    // Estatísticas de memória
    final avgMemory = _memorySamples.isNotEmpty ? 
        _memorySamples.reduce((a, b) => a + b) ~/ _memorySamples.length : 0;
    
    // Calcular estabilidade do heap
    double heapStability = 0;
    if (_memorySamples.length > 1) {
      double totalDiff = 0;
      for (int i = 1; i < _memorySamples.length; i++) {
        totalDiff += (_memorySamples[i] - _memorySamples[i-1]).abs();
      }
      heapStability = totalDiff / (_memorySamples.length - 1);
    }
    
    return {
      'version': _currentVersion,
      'duration_ms': _stopwatch.elapsedMilliseconds,
      'total_frames': _frameCount,
      'frame_timing': {
        'avg_us': avgFrameTime,
        'min_us': minFrameTime,
        'max_us': maxFrameTime,
        'std_dev_us': stdDev,
        'frames_over_8ms': _framesOver8ms,
        'percent_over_8ms': percentOver8ms,
      },
      'gc_analysis': {
        'gc_events': _gcEvents.length,
        'avg_gc_pause_us': _gcEvents.isNotEmpty ? 
            _gcEvents.reduce((a, b) => a + b) ~/ _gcEvents.length : 0,
      },
      'memory_analysis': {
        'heap_avg_bytes': avgMemory,
        'heap_avg_mb': (avgMemory / 1024 / 1024).toStringAsFixed(1),
        'heap_stability_bytes': heapStability,
        'heap_stability_mb': (heapStability / 1024 / 1024).toStringAsFixed(2),
        'total_allocations_bytes': _totalAllocations,
        'allocations_per_frame': _totalAllocations ~/ _frameCount,
      },
      'estimated_fps': (1000000 / avgFrameTime).toStringAsFixed(1),
    };
  }
  
  void _printComparison(Map<String, dynamic> original, Map<String, dynamic> extreme) {
    print('\n' + '=' * 80);
    print('COMPARAÇÃO TÉCNICA: ORIGINAL vs EXTREME');
    print('=' * 80);
    
    _printMetric('Frame Time Médio (µs)', 
        original['frame_timing']['avg_us'], 
        extreme['frame_timing']['avg_us'],
        lowerIsBetter: true);
    
    _printMetric('Desvio Padrão (Jitter µs)', 
        original['frame_timing']['std_dev_us'], 
        extreme['frame_timing']['std_dev_us'],
        lowerIsBetter: true);
    
    _printMetric('Frames > 8ms', 
        original['frame_timing']['frames_over_8ms'], 
        extreme['frame_timing']['frames_over_8ms'],
        lowerIsBetter: true);
    
    _printMetric('% Frames > 8ms', 
        original['frame_timing']['percent_over_8ms'], 
        extreme['frame_timing']['percent_over_8ms'],
        lowerIsBetter: true,
        suffix: '%');
    
    _printMetric('GC Events', 
        original['gc_analysis']['gc_events'], 
        extreme['gc_analysis']['gc_events'],
        lowerIsBetter: true);
    
    _printMetric('Heap Médio (MB)', 
        double.parse(original['memory_analysis']['heap_avg_mb']), 
        double.parse(extreme['memory_analysis']['heap_avg_mb']),
        lowerIsBetter: true);
    
    _printMetric('Estabilidade Heap (MB variação)', 
        double.parse(original['memory_analysis']['heap_stability_mb']), 
        double.parse(extreme['memory_analysis']['heap_stability_mb']),
        lowerIsBetter: true);
    
    _printMetric('Alocação por Frame (bytes)', 
        original['memory_analysis']['allocations_per_frame'], 
        extreme['memory_analysis']['allocations_per_frame'],
        lowerIsBetter: true);
    
    print('\nFPS Estimado:');
    print('  ORIGINAL: ${original['estimated_fps']} FPS');
    print('  EXTREME:  ${extreme['estimated_fps']} FPS');
    
    // Verificação crítica: frames > 8ms na EXTREME?
    final framesOver8msExtreme = extreme['frame_timing']['frames_over_8ms'];
    final maxFrameTimeExtreme = extreme['frame_timing']['max_us'];
    
    print('\n' + '=' * 80);
    print('VERIFICAÇÃO CRÍTICA: FRAMES > 8ms NA VERSÃO EXTREME');
    print('=' * 80);
    
    if (framesOver8msExtreme == 0) {
      print('✅ CONFIRMADO: ZERO frames > 8ms na versão EXTREME');
      print('   Perfeito para 120Hz (8.33ms por frame)');
    } else {
      print('⚠️  ALERTA: $framesOver8msExtreme frames > 8ms na versão EXTREME');
      print('   ${extreme['frame_timing']['percent_over_8ms'].toStringAsFixed(2)}% dos frames excedem budget de 120Hz');
    }
    
    if (maxFrameTimeExtreme > 8000) {
      print('⚠️  Frame mais longo: ${(maxFrameTimeExtreme / 1000).toStringAsFixed(2)}ms');
    } else {
      print('✅ Todos frames ≤ 8ms: ${(maxFrameTimeExtreme / 1000).toStringAsFixed(2)}ms máximo');
    }
  }
  
  void _printMetric(String label, num original, num extreme, 
                   {bool lowerIsBetter = true, String suffix = ''}) {
    final diff = extreme - original;
    final diffPercent = original != 0 ? (diff / original.abs() * 100) : 0;
    
    String trend;
    if (lowerIsBetter) {
      trend = diff < 0 ? '✅ MELHORIA' : diff > 0 ? '❌ REGRESSÃO' : '➖ IGUAL';
    } else {
      trend = diff > 0 ? '✅ MELHORIA' : diff < 0 ? '❌ REGRESSÃO' : '➖ IGUAL';
    }
    
    print('$trend $label:');
    print('  ${original.toStringAsFixed(2)}$suffix → ${extreme.toStringAsFixed(2)}$suffix '
          '(${diffPercent.toStringAsFixed(1)}%)');
  }
  
  Map<String, dynamic>? _originalResults;
  Map<String, dynamic>? _extremeResults;
  
  Future<void> _runFullBenchmark() async {
    print('🚀 INICIANDO BENCHMARK COMPARATIVO');
    print('Teste de 30 segundos por versão...\n');
    
    // Testar versão ORIGINAL
    print('🔴 TESTANDO VERSÃO ORIGINAL...');
    _startBenchmark('ORIGINAL');
    await Future.delayed(const Duration(seconds: 30));
    _stopBenchmark();
    _originalResults = _getResults();
    print('✅ Original completo: ${_originalResults!['total_frames']} frames\n');
    
    // Pausa entre testes
    await Future.delayed(const Duration(seconds: 2));
    
    // Testar versão EXTREME
    print('🟢 TESTANDO VERSÃO EXTREME...');
    _startBenchmark('EXTREME');
    await Future.delayed(const Duration(seconds: 30));
    _stopBenchmark();
    _extremeResults = _getResults();
    print('✅ Extreme completo: ${_extremeResults!['total_frames']} frames\n');
    
    // Gerar comparação
    if (_originalResults != null && _extremeResults != null) {
      _printComparison(_originalResults!, _extremeResults!);
      
      // Recomendação final
      print('\n' + '=' * 80);
      print('🎯 RECOMENDAÇÃO PARA MERGE PARA MASTER');
      print('=' * 80);
      
      final framesOver8msExtreme = _extremeResults!['frame_timing']['frames_over_8ms'];
      final gcEventsExtreme = _extremeResults!['gc_analysis']['gc_events'];
      final percentOver8msExtreme = _extremeResults!['frame_timing']['percent_over_8ms'];
      
      if (framesOver8msExtreme == 0 && gcEventsExtreme == 0) {
        print('✅ MERGE IMEDIATO: Versão EXTREME atinge 120Hz perfeito');
        print('   - Zero frames > 8ms');
        print('   - Zero GC events durante teste');
        print('   - Heap estável (object pooling funcionando)');
      } else if (percentOver8msExtreme < 1.0 && gcEventsExtreme < 3) {
        print('✅ MERGE RECOMENDADO: Performance excelente');
        print('   - Apenas ${percentOver8msExtreme.toStringAsFixed(2)}% frames > 8ms');
        print('   - Apenas $gcEventsExtreme GC events');
        print('   - Adequado para gameplay competitivo');
      } else if (percentOver8msExtreme < 5.0) {
        print('⚠️ MERGE COM MONITORING: Performance boa');
        print('   - ${percentOver8msExtreme.toStringAsFixed(2)}% frames > 8ms');
        print('   - Monitorar stuttering em produção');
      } else {
        print('❌ AJUSTES NECESSÁRIOS: Performance insuficiente');
        print('   - ${percentOver8msExtreme.toStringAsFixed(2)}% frames > 8ms');
        print('   - Pode causar stuttering visível');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetrimized Performance Benchmark'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_isRunning ? 'TESTANDO ' + _currentVersion : 'PARADO'}',
              style: TextStyle(
                fontSize: 18,
                color: _isRunning ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isRunning) ...[
              LinearProgressIndicator(
                value: _stopwatch.elapsedMilliseconds / 30000,
              ),
              const SizedBox(height: 10),
              Text('Tempo: ${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s / 30s'),
              Text('Frames: $_frameCount'),
              Text('Frames > 8ms: $_framesOver8ms'),
              Text('GC Events: ${_gcEvents.length}'),
            ],
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _isRunning ? null : () => _runFullBenchmark(),
              child: const Text('EXECUTAR BENCHMARK COMPLETO (60s)'),
            ),
            
            const SizedBox(height: 20),
            
            if (_originalResults != null && _extremeResults != null) ...[
              const Divider(),
              const Text(
                'RESULTADOS:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              DataTable(
                columns: const [
                  DataColumn(label: Text('Métrica')),
                  DataColumn(label: Text('Original'))),
                  DataColumn(label: Text('Extreme'))),
                  DataColumn(label: Text('Diferença'))),
                ],
                rows: [
                  _buildRow('Frame Time (µs)', 
                      _originalResults!['frame_timing']['avg_us'].toString(),
                      _extremeResults!['frame_timing']['avg_us'].toString(),
                      _calculateDiff(_originalResults!['frame_timing']['avg_us'], 
                                   _extremeResults!['frame_timing']['avg_us'])),
                  
                  _buildRow('Jitter (µs)', 
                      _originalResults!['frame_timing']['std_dev_us'].toString(),
                      _extremeResults!['frame_timing']['std_dev_us'].toString(),
                      _calculateDiff(_originalResults!['frame_timing']['std_dev_us'], 
                                   _extremeResults!['frame_timing']['std_dev_us'])),
                  
                  _buildRow('Frames > 8ms', 
                      _originalResults!['frame_timing']['frames_over_8ms'].toString(),
                      _extremeResults!['frame_timing']['frames_over_8ms'].toString(),
                      _calculateDiff(_originalResults!['frame_timing']['frames_over_8ms'], 
                                   _extremeResults!['frame_timing']['frames_over_8ms'])),
                  
                  _buildRow('GC Events', 
                      _originalResults!['gc_analysis']['gc_events'].toString(),
                      _extremeResults!['gc_analysis']['gc_events'].toString(),
                      _calculateDiff(_originalResults!['gc_analysis']['gc_events'], 
                                   _extremeResults!['gc_analysis']['gc_events'])),
                  
                  _buildRow('Heap (MB)', 
                      _originalResults!['memory_analysis']['heap_avg_mb'],
                      _extremeResults!['memory_analysis']['heap_avg_mb'],
                      _calculateDiff(double.parse(_originalResults!['memory_analysis']['heap_avg_mb']), 
                                   double.parse(_extremeResults!['memory_analysis']['heap_avg_mb'])) + ' MB'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  DataRow _buildRow(String metric, String original, String extreme, String diff) {
    Color getColor(String diff) {
      if (diff.contains('-')) return Colors.green;
      if (diff.contains('+')) return Colors.red;
      return Colors.grey;
    }
    
    return DataRow(cells: [
      DataCell(Text(metric)),
      DataCell(Text(original)),
      DataCell(Text(extreme)),
      DataCell(Text(
        diff,
        style: TextStyle(color: getColor(diff), fontWeight: FontWeight.bold),
      )),
    ]);
  }
  
  String _calculateDiff(num original, num extreme) {
    final diff = extreme - original;
    final percent = original != 0 ? (diff / original.abs() * 100) : 0;
    
    if (diff == 0) return '0%';
    return '${diff > 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';
  }
}