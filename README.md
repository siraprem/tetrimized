[English version available here](./README_EN.md)

# Tetrimized - Um Wrapper Mobile para o Tetr.io

Um app mobile feito em Flutter para jogar o Tetr.io no celular. Basicamente é um wrapper que roda o site do Tetr.io dentro de um WebView, mas com algumas adaptações pra ficar mais legal no mobile.

## O que é isso?

Sabe o Tetr.io, aquele jogo de Tetris online que todo mundo joga no navegador? Pois é, esse projeto é uma tentativa de fazer um app mobile pra poder jogar no celular de um jeito mais nativo.

## Funcionalidades

- Roda o Tetr.io direto no celular
- Performance absurdamente melhor (até 300% melhor que o normal)
- Interface adaptada pra touch (melhor que abrir no navegador)
- Opacidade customizável dos botões (pra não tapar o jogo)
- Menu rápido para esconder/mostrar UI
- Tecla 'R' integrada pra reset rápido

## Qual versão baixar?

A gente tem duas branches principais agora. O projeto evoluiu e a estrutura mudou bastante, então se liga na diferença:

### Versão Turbo (O Futuro) - **RECOMENDADA**
Essa é a versão onde a mágica acontece. Ela usa toda a tecnologia nova e de ponta que implementamos (como o sistema de otimizações de performance). 

- **Foco:** Máxima performance, resposta ao toque instantânea e funcionalidades novas.
- **Atualizações:** Essa é a versão que vai receber tudo de novo primeiro. É o meu foco principal de desenvolvimento.

### Versão Pro (Legacy / Estabilidade)
Essa versão é o nosso "tanque de guerra" antigo. A estrutura dela é bem diferente e muito mais difícil de mexer/manter na branch de estabilidade.

- **Foco:** Estabilidade bruta para celulares que não aguentam o Turbo.
- **Atualizações:** Ela entrou em modo **Legacy**. Só vou mexer nela se algo quebrar completamente, se o app parar de abrir ou se tiver alguma vulnerabilidade bizarra. Se você quer as novidades, vá de Turbo.

**Peço desculpas por isso mas tá realmente impossível mexer nessa branch.**

### Como Baixar
Para baixar o aplicativo, acesse nossa página de lançamentos:

**[Clique aqui para ver todas as versões (Releases)](https://github.com/siraprem/tetrimized/releases)**

**Dica de ouro:** Use o bom senso. Se tem a versão 1.1.2 e a 1.1.0, a 1.1.2 é LOGICAMENTE a mais nova. Escolha entre a Pro ou a Turbo e seja feliz.

## Como rodar e buildar

### Pré-requisitos
- Flutter SDK instalado (versão 3.0 ou mais nova)
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
