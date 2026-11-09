# Auditoria de recuperação

## Estado inicial

Repositório clonado de `siraprem/tetrimized`, sem mudanças locais, em `master` (`a706608`). Branches remotas disponíveis: `master`, `bleeding-edge` e `stability-pro`. A branch de trabalho `maintenance/recovery` foi criada a partir de `master`. O `main.dart` em todas as três branches tem o mesmo ponto de entrada Flutter/WebView; `master` tem a versão declarada mais recente (`1.1.3+11`). Mantida como base, sem substituir por variantes experimentais.

## Mudanças

- Movidos nove documentos e instruções históricos para `docs/archive/`, preservando conteúdo e histórico Git.
- README deixou de afirmar ganho de performance de até 300%, resposta instantânea ou superioridade não comprovados. Corrigida a versão mínima declarada do Flutter/Dart.
- Commits posteriores da branch também alteraram `lib/main.dart`: adicionaram captura de teclado/gamepad, exportação/importação do layout por clipboard e removem a camada de controles touch quando ela está oculta.

## Problemas encontrados

- **Confirmado pelo código:** `lib/main.dart` hospeda `https://tetr.io` em `InAppWebView`; os controles são serializados em `SharedPreferences`, com opacidade/visibilidade e há feedback tátil configurável. A injeção de teclas JavaScript e o tratamento das teclas físicas/gamepad estão no mesmo arquivo.
- **Problema no estado anterior à recuperação:** `onLoadStop` chamava `_setupGameDetection` em cada conclusão de carregamento; o método registrava o handler novamente e criava um `setInterval` sem guardar o ID. Repetições no mesmo documento podiam acumular timers do app.
- **Estado final desta branch:** o detector de estado e seu handler foram removidos. O app não instala esse timer nem acompanha estado de partida; assim, a correção descrita nas notas anteriores de ciclo de vida não está presente no código final e não deve ser considerada funcionalidade entregue.
- **Suspeita que precisa de teste:** degradação de FPS em sessões longas pode envolver WebView/Chromium, jogo, memória, GC ou aquecimento. Nenhuma medição neste trabalho permite atribuir causa ou comprovar otimização; GC Dart/Flutter e GC JavaScript são ambientes distintos.
- **Experimento antigo:** `backups_vibe/` contém variantes e benchmarks; análises em `docs/archive/` são históricas, não evidência de performance reproduzível.
- **Documentação desatualizada:** README promovia ganhos de até 300% e descrevia branches como versões com desempenho e suporte garantidos. As afirmações foram removidas.

## Não resolvido / limitações

O envio de teclas, interação do gamepad, persistência e importação/exportação por clipboard não foram exercitados em dispositivo Android. Injeção/dispatch de eventos sintéticos pode depender do comportamento atual do TETR.IO/WebView e requer teste real. A compilação confirma a configuração Android, mas não valida interação de teclado/foco com a WebView em runtime.

## Verificações

- Comparadas referências do ponto de entrada e dependências nas três branches.
- A versão final removeu os arquivos Gradle Groovy duplicados e usa Kotlin DSL; o wrapper está em Gradle 8.14 e o AGP em 8.7.2. O build local release confirmou essa configuração.
- O workflow atual usa Java 17 e Flutter stable, executa `pub get`, `flutter analyze`, `flutter test`, build release e upload do APK.
- `pubspec.yaml` requer Dart `^3.11.4`; `flutter_inappwebview` está fixado em 6.1.5. A análise, teste e compilação Android foram executados localmente com Flutter 3.47.9 / Dart 3.13.7.
- O ambiente desta revisão tinha Java 17 e 25 instalados, além de Android SDK. O build com Java 25 falhou antes da compilação; o build com Java 17 passou.
- O único teste automatizado é `test/widget_test.dart`, que verifica inicialização do app usando fake de `InAppWebViewPlatform`. Não cobre navegação WebView, gamepad/teclado, persistência nem importação/exportação.
- Método futuro de comparação, sem resultados alegados: usar o mesmo Android físico, versão de SO/WebView, rede, orientação, configuração de controles, conta/cena e duração; buildar commit original `master` (`a706608`) e recovery em modo/perfil iguais e comparar também Chrome Android. Fazer sessões repetidas e registrar FPS/frame time e stutter via ferramenta de profiling, memória (PSS/RSS) e latência input-ação; coletar ao início e após períodos fixos de sessão longa, além de versão do WebView e condições ambientais. Não comparar sessões/cenas diferentes nem inferir causa de GC sem telemetria específica. Não executado por falta de SDK/dispositivo.

## Revisão de merge-readiness (2026-11-08)

- O smoke test agora instala um fake leve de `InAppWebViewPlatform`, mantendo o teste de inicialização sem exigir runtime Android. `flutter analyze` e `flutter test` passaram localmente.
- O workflow Android agora executa análise e testes antes do build. A execução do PR `#1` no commit `9dbff07` passou em todas as etapas, incluindo build e upload do APK.
- O APK release também foi gerado localmente com Java 17. A compilação com o Java 25 padrão do ambiente falhou antes da compilação Kotlin/Android, por incompatibilidade da versão de Java selecionada.
- Não foi feito teste interativo num dispositivo Android; teclado/gamepad, navegação WebView e importação de layouts ainda requerem validação manual em dispositivo.

## Próximas prioridades

1. Testar uso prolongado em dispositivo Android, registrando FPS, memória e versão do sistema/WebView com procedimento repetível.
2. Validar teclado/gamepad, foco com WebView e importação/exportação de layout num dispositivo Android.
