# Auditoria de recuperação

## Estado inicial

Repositório clonado de `siraprem/tetrimized`, sem mudanças locais, em `master` (`a706608`). Branches remotas disponíveis: `master`, `bleeding-edge` e `stability-pro`. A branch de trabalho `maintenance/recovery` foi criada a partir de `master`. O `main.dart` em todas as três branches tem o mesmo ponto de entrada Flutter/WebView; `master` tem a versão declarada mais recente (`1.1.3+11`). Mantida como base, sem substituir por variantes experimentais.

## Mudanças

- Movidos nove documentos e instruções históricos para `docs/archive/`, preservando conteúdo e histórico Git.
- README deixou de afirmar ganho de performance de até 300%, resposta instantânea ou superioridade não comprovados. Corrigida a versão mínima declarada do Flutter/Dart.
- Nenhuma lógica do aplicativo foi modificada.

## Problemas encontrados

- **Confirmado pelo código:** `lib/main.dart` hospeda `https://tetr.io` em `InAppWebView`; os controles são serializados em `SharedPreferences`, com opacidade/visibilidade e há feedback tátil configurável. A injeção de teclas JavaScript e o detector de estado da partida estão no mesmo arquivo.
- **Confirmado pelo código (estado anterior):** `onLoadStop` chama `_setupGameDetection` em cada conclusão de carregamento; o método registrava o handler novamente e criava um `setInterval` sem guardar o ID. Repetições no mesmo documento podiam acumular timers do app. A navegação para novo documento descarta o contexto JavaScript anterior; não se demonstrou timer sobrevivendo entre documentos.
- **Correção nesta etapa:** instalação agora limpa somente o timer próprio identificado em `window.__tetrimizedGameDetectionInterval` antes de criar outro; handler é registrado uma vez por controller e removido do controller que o registrou ao trocar controller ou em `dispose`. Callback valida montagem/argumentos antes de `setState`. Nenhum timer do jogo é alterado.
- **Suspeita que precisa de teste:** degradação de FPS em sessões longas pode envolver WebView/Chromium, jogo, memória, GC ou aquecimento. Nenhuma medição neste trabalho permite atribuir causa ou comprovar otimização; GC Dart/Flutter e GC JavaScript são ambientes distintos.
- **Experimento antigo:** `backups_vibe/` contém variantes e benchmarks; análises em `docs/archive/` são históricas, não evidência de performance reproduzível.
- **Documentação desatualizada:** README promovia ganhos de até 300% e descrevia branches como versões com desempenho e suporte garantidos. As afirmações foram removidas.

## Não resolvido / limitações

O envio de teclas, persistência, comportamento do jogo, renderização e configurações Android não foram alterados. Injeção/dispatch de eventos sintéticos pode depender do comportamento atual do TETR.IO/WebView e requer teste real. Arquivos de benchmark e APK versionado foram preservados. A remoção do handler foi implementada para o controller atual; não foi possível verificar em runtime o ciclo de vida do plugin em troca de controller.

## Verificações

- Comparadas referências do ponto de entrada e dependências nas três branches.
- `git diff --check` passou após a etapa do ciclo de vida. Flutter/Dart/Java não estão disponíveis neste ambiente; CI não foi executado.
- Etapa de validação: não havia workflow em `.github/workflows/`; criado `.github/workflows/android-ci.yml` para Java 17, Flutter stable, `pub get`, `flutter analyze`, `flutter test` e build Android debug. Não foi disparado.
- `pubspec.yaml` requer Dart `^3.11.4`; lockfile fixa `flutter_inappwebview` 6.1.5. Os métodos `addJavaScriptHandler`/`removeJavaScriptHandler` são APIs esperadas dessa versão, mas a compatibilidade não pôde ser confirmada contra o pacote instalado em cache (ausente); compilação local/CI deve confirmar.
- Android declara Java/JVM 17, Gradle wrapper 8.10.2, AGP 8.7.2 no `settings.gradle.kts`; `android/build.gradle` também contém classpath AGP 8.5.0. Há configurações Gradle Groovy e Kotlin duplicadas (`build.gradle` e `.kts` na raiz e app), cuja seleção/interação requer validação por CI antes de qualquer ajuste.
- Ambiente local verificado: Flutter, Dart, Java/Javac, Gradle, adb e sdkmanager ausentes no PATH e não encontrados nas localizações usuais examinadas. Android SDK e cache do plugin/Gradle também ausentes. Não instalar SDK grande sem autorização.
- Existe apenas `test/widget_test.dart`: smoke test que procura texto `Otimizar`; não cobre detector nem persistência e pode depender de plataforma WebView. Não adicionei teste superficial: detector está acoplado à WebView e persistência à UI/SharedPreferences; testar com fidelidade requer separar interfaces ou infraestrutura Flutter disponível.
- Método futuro de comparação, sem resultados alegados: usar o mesmo Android físico, versão de SO/WebView, rede, orientação, configuração de controles, conta/cena e duração; buildar commit original `master` (`a706608`) e recovery em modo/perfil iguais e comparar também Chrome Android. Fazer sessões repetidas e registrar FPS/frame time e stutter via ferramenta de profiling, memória (PSS/RSS) e latência input-ação; coletar ao início e após períodos fixos de sessão longa, além de versão do WebView e condições ambientais. Não comparar sessões/cenas diferentes nem inferir causa de GC sem telemetria específica. Não executado por falta de SDK/dispositivo.

## Próximas prioridades

1. Testar uso prolongado em dispositivo Android, registrando FPS, memória e versão do sistema/WebView com procedimento repetível.
2. Validar navegação/reload e descarte do detector de partida; somente então decidir se timers/handlers precisam de limpeza explícita.
3. Executar análise, testes e build com SDK compatível com `pubspec.yaml`, corrigindo falhas pequenas comprovadas.
