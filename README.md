# Tetrimized - Um Wrapper Mobile para o Tetr.io

Um app mobile feito em Flutter para jogar o Tetr.io no celular. Basicamente é um wrapper que roda o site do Tetr.io dentro de um WebView, mas com algumas adaptações pra ficar mais legal no mobile.

## O que é isso?

Sabe o Tetr.io, aquele jogo de Tetris online que todo mundo joga no navegador? Pois é, esse projeto é uma tentativa de fazer um app mobile pra poder jogar no celular de um jeito mais nativo.

## Funcionalidades

- Roda o Tetr.io direto no celular
- Interface adaptada pra touch (melhor que abrir no navegador)
- Funciona tanto no Android quanto no iOS
- Também roda na web e desktop, porque Flutter é isso aí

## Plataformas suportadas

- Android 5.0+ (SDK 21 pra cima)
- iOS 11.0+
- Web (se quiser testar no navegador)
- Windows, macOS e Linux (se tiver paciência pra configurar)

## Como rodar

### Pré-requisitos

- Flutter SDK instalado (versão 3.0 ou mais nova)
- Android Studio ou Xcode, dependendo da plataforma
- Git (óbvio)

### Passo a passo

1. **Baixa o código**
   ```bash
   git clone https://github.com/siraprem/tetrimized.git
   cd tetrimized
   ```

2. **Instala as dependências**
   ```bash
   flutter pub get
   ```

3. **Roda o app**
   ```bash
   # No Android
   flutter run -d android
   
   # No iOS (se tiver Mac)
   flutter run -d ios
   
   # Na web
   flutter run -d chrome
   ```

### Se quiser buildar

## Qual versão baixar?

Temos duas versões disponíveis, cada uma com seu foco. Você pode instalar as duas ao mesmo tempo para testar qual funciona melhor no seu celular.

### Versão Turbo (Recomendada)

É a versão mais rápida e fluida. Ideal para quem quer a melhor resposta ao toque e movimentos suaves. 

**Características:**
- Melhor performance geral
- Resposta mais rápida aos comandos
- Movimentos mais fluidos

**Nota:** Em casos raros, pode apresentar pequenos engasgos em celulares que aquecem muito durante jogos intensos.

### Versão Pro (Estabilidade)

É a versão "tanque de guerra". Ela é um pouco menos fluida, mas é extremamente estável.

**Características:**
- Maior estabilidade em celulares mais antigos
- Menos problemas de fechamento inesperado
- Performance mais consistente

**Recomendada se:**
- A versão Turbo fechar sozinha no seu celular
- Seu celular for mais antigo ou tiver problemas de aquecimento
- Você prefere estabilidade acima de tudo

### Como Baixar
Para baixar o aplicativo, acesse nossa página de lançamentos no link abaixo:

[Clique aqui para ver todas as versões (Releases)](https://github.com/siraprem/tetrimized/releases)

#### Qual versão escolher?

**Versão PRO:** Focada em estabilidade e compatibilidade. Se você quer que o jogo funcione sem erros, escolha esta.

**Versão TURBO:** Focada em máxima performance. Pode ser instável em alguns aparelhos, mas é a mais rápida.

Na página, basta procurar o arquivo que termina em .apk na versão desejada e clicar nele para baixar. Lembrando de usar a logica de a versao com numero maior, tipo se tem 1.1.0 e 1.1.2 vc baixa a 1.1.2 a 1.1.0 é LOGICAMENTE a antiga e tambem pensar se vc quer a pro ou turbo cada uma ta bem separada para melhor organização, é só usar o bom senso.


```bash
# APK pra Android
flutter build apk

# App Bundle pra Play Store
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web
```

## Estrutura do projeto

```
tetrimized/
├── android/          # Coisas específicas do Android
├── ios/             # Coisas específicas do iOS
├── lib/             # Código principal em Dart
│   └── main.dart    # Onde tudo começa
├── web/             # Configurações pra web
├── windows/         # Suporte pra Windows
├── macos/           # Suporte pra macOS
├── linux/           # Suporte pra Linux
├── pubspec.yaml     # Dependências do Flutter
└── README.md        # Esse arquivo aqui
```

## Detalhes técnicos

- Feito com Flutter 3.0+
- Usa o pacote `webview_flutter` pra mostrar o Tetr.io
- Gerenciamento de estado com Provider (simples e funciona)
- Layout responsivo pra diferentes tamanhos de tela

## Licença

MIT - basicamente pode fazer o que quiser com o código, só não me processa se der merda.

## Contribuindo

Se quiser ajudar, fique à vontade! O projeto é open source justamente pra isso.

1. Faz um fork do repositório
2. Cria uma branch pra sua feature (`git checkout -b minha-feature-incrivel`)
3. Commita suas mudanças (`git commit -m 'Adiciona coisa legal'`)
4. Dá push pra sua branch (`git push origin minha-feature-incrivel`)
5. Abre um Pull Request

## Dúvidas ou problemas?

- Abre uma [Issue](https://github.com/siraprem/tetrimized/issues) no GitHub
- Ou dá uma olhada nas [Discussions](https://github.com/siraprem/tetrimized/discussions)

## Agradecimentos

- [Tetr.io](https://tetr.io) - O jogo em si, que é muito bom
- [Flutter](https://flutter.dev) - O framework que torna isso possível
- Todo mundo que testar, usar ou contribuir

---

**Aviso legal**: Isso aqui é um projeto não-oficial. O Tetr.io é dos criadores originais. Esse app não tem nenhuma afiliação com a equipe do Tetr.io, é só um wrapper feito por fã pra fã.
