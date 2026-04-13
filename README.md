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
