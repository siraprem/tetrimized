[English version available here](./README_EN.md)

# Tetrimized - Um Wrapper Mobile para o Tetr.io

Um app mobile feito em Flutter para jogar o Tetr.io no celular. Basicamente é um wrapper que roda o site do Tetr.io dentro de um WebView, mas com algumas adaptações pra ficar mais legal no mobile.

## O que é isso?

Sabe o Tetr.io, aquele jogo de Tetris online que todo mundo joga no navegador? Pois é, esse projeto é uma tentativa de fazer um app mobile pra poder jogar no celular de um jeito mais nativo.

## Funcionalidades

- Roda o Tetr.io direto no celular
- Interface adaptada pra touch (melhor que abrir no navegador)
- Opacidade customizável dos botões (pra não tapar o jogo)
- Menu rápido para esconder/mostrar UI
- Tecla 'R' integrada pra reset rápido

## Qual versão baixar?

As branches `master`, `bleeding-edge` e `stability-pro` contêm históricos distintos. Consulte a página de releases para versões distribuídas; não há garantia de desempenho relativo entre branches.

### Como Baixar
Para baixar o aplicativo, acesse nossa página de lançamentos:

**[Clique aqui para ver todas as versões (Releases)](https://github.com/siraprem/tetrimized/releases)**

**Dica de ouro:** Use o bom senso. Se tem a versão 1.1.2 e a 1.1.0, a 1.1.2 é LOGICAMENTE a mais nova. Escolha entre a Pro ou a Turbo e seja feliz.

## Como rodar e buildar

### Pré-requisitos
- Flutter SDK compatível com Dart `^3.11.4`, conforme `pubspec.yaml`
- Android Studio ou Xcode
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

3. **Buildar o APK (Android)**
   ```bash
   # Gerar o APK pra instalar direto
   flutter build apk --release

   # Se for subir pra algum lugar, gera o bundle
   flutter build appbundle
   ```

## Estrutura do projeto

Relatórios e instruções históricos foram preservados em [`docs/archive/`](docs/archive/). Eles registram experimentos e avaliações antigas; não comprovam ganhos de desempenho.

```
tetrimized/
├── android/          # Coisas específicas do Android
├── lib/             # Código principal em Dart (Onde a mágica acontece)
├── pubspec.yaml     # Dependências do Flutter
└── README.md        # Esse arquivo aqui
```

## Licença

**MIT** - basicamente pode fazer o que quiser com o código, só não me processa se der merda, recomendo ler o LICENSE.md ne

## Observação sobre anúncios e performance

O TETR.IO exibe anúncios e, como o app é um wrapper, eles aparecem. Se quiser filtrar, use um DNS privado (como o `dns.adguard.com`) nas configs do seu Android. Mas ó, o osk (dev do jogo) precisa disso pra manter os servidores, então se puder, apoia o cara lá no site oficial!

## Desenvolvimento Assistido

O Tetrimized utiliza um fluxo de desenvolvimento AI-Augmented (Desenvolvimento Aumentado por IA). Isso permite que eu, como estudante, foque na arquitetura e na experiência do usuário, enquanto utilizo modelos de linguagem avançados para otimizar a implementação e acelerar a resolução de bugs.

## Aviso legal

**Isso aqui é um projeto não-oficial.** O Tetr.io é dos criadores originais. Esse app não tem nenhuma afiliação com a equipe do Tetr.io, é só um wrapper feito por fã pra fã. Não me deem strike, eu amo o jogo.
