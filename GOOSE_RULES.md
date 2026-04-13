# GOOSE RULES

## Regras de Edição de Código

1. **NUNCA use `sed` para lógica de UI complexa**
   - Se precisar alterar o arquivo principal (`lib/main.dart`), reescreva-o por completo
   - Use `write` para criar uma nova versão do arquivo
   - Mantenha a estrutura original, apenas aplicando as correções necessárias

2. **Siga as instruções de correção à risca**
   - Arquitetura: Positioned dentro de Stack para botões reativos
   - InAppWebView: Use `addJavaScriptHandler` no `onWebViewCreated`
   - Ícones: Use apenas `Icons.vibration` ou `Icons.error_outline`
   - Persistência: Salve posições no `onPanEnd`

3. **Verifique o build antes de reportar sucesso**
   - Execute `flutter clean` e `flutter build apk --debug`
   - Confirme que o APK foi gerado em `build/app/outputs/flutter-apk/app-debug.apk`

4. **Teste a instalação**
   - Limpe o pacote: `adb shell pm clear com.ley.tetriomobile.pro`
   - Instale o APK via adb

5. **Mantenha o TODO atualizado**
   - Atualize o progresso em cada fase
   - Marque tarefas como concluídas quando finalizadas

6. **Links de Download no README**
   - Utilize sempre a estrutura de URL estática do GitHub:
     ```
     https://github.com/[USUARIO]/[REPO]/releases/latest/download/[NOME_DO_ARQUIVO].apk
     ```
   - NUNCA coloque a versão da tag (ex: v1.1.2) no link de download
   - Os links devem sempre apontar para a versão mais recente sem necessidade de edição manual
   - Nomes de arquivos padrão:
     - `tetrimized-pro.apk` para versão Pro (estabilidade)
     - `tetrimized-turbo.apk` para versão Turbo (performance)