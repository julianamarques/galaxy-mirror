# Galaxy Mirror

Espelhe e controle um celular Samsung Galaxy (ou qualquer Android 11+) no macOS, por Wi-Fi ou cabo USB — com uma configuração guiada no estilo do Espelhamento do iPhone.

O app cuida do pareamento (por QR code ou código de seis dígitos), da conexão por Wi-Fi ou cabo USB e da reconexão automática. O espelhamento é nativo: o app envia ao celular o servidor do [scrcpy](https://github.com/Genymobile/scrcpy) (versão fixa, 5.0), recebe o vídeo e o áudio pelo protocolo dele e exibe tudo numa janela própria, com decodificação por hardware (VideoToolbox) e controle por mouse, trackpad e teclado.

## Requisitos

- macOS 14 ou posterior
- Celular com Android 11+ na mesma rede Wi-Fi do Mac (ou conectado por cabo USB)

O app já traz o `adb` e o servidor do scrcpy; não é preciso instalar mais nada.

## Instalar

Abra o `Galaxy Mirror.dmg` e arraste o **Galaxy Mirror** para **Aplicativos**.

O app é assinado apenas localmente. Em outro Mac, o macOS bloqueia a primeira abertura com "não é possível verificar o desenvolvedor": libere em **Ajustes do Sistema › Privacidade e Segurança › Abrir Mesmo Assim**.

## Compilar

```bash
./scripts/build-app.sh          # gera build/Galaxy Mirror.app
./scripts/make-dmg.sh           # gera build/Galaxy Mirror.dmg
```

Para publicar uma nova versão no GitHub (requer o `gh` logado):

```bash
DRY_RUN=1 ./scripts/release.sh 0.2.0-beta.1   # mostra as notas sem alterar nada
./scripts/release.sh 0.2.0-beta.1             # pré-lançamento (alpha, beta ou rc)
./scripts/release.sh 1.0.0                    # versão estável
```

Os scripts de build baixam o `adb` (`scripts/fetch-adb.sh`, platform-tools 37.0.1) e o servidor do scrcpy (`scripts/fetch-server.sh`) com checksum conferido.

Para desenvolvimento, `swift run` também funciona, e `swift test` roda os testes. Em builds de debug, `GALAXY_STEP=pair` (ou `prepare`, `code`, `connecting`, `failed`, `done`, `missing`) abre direto numa etapa da configuração.

## Estrutura

```
Sources/GalaxyMirror/
├── App/          ponto de entrada (GalaxyMirrorApp, AppDelegate)
├── Models/       tipos de dados (PairedDevice, MDNSService, Quality, Codec, SettingsKey…)
├── Services/     integração com adb (ADB, Bonjour, LocalNetwork, Tools)
│   └── Mirror/   cliente nativo do protocolo do scrcpy (servidor, sockets, vídeo, áudio, controle)
├── ViewModels/   estado observável (AppModel, SetupModel)
├── Views/        telas SwiftUI (Setup, Device, Settings), janela de espelhamento (Mirror) e componentes
└── Extensions/   extensões de tipos do sistema
Tests/GalaxyMirrorTests/
Resources/        Info.plist, ícone, scrcpy-server e adb (baixados com checksum pelos scripts)
scripts/          build do .app e do .dmg, download do servidor e do adb, geração do ícone
```

## Como funciona

1. **Preparar o Galaxy** — ativar as Opções do desenvolvedor e a Depuração sem fio.
2. **Parear** — o app mostra um QR code no mesmo formato do Android Studio (`WIFI:T:ADB;S:<nome>;P:<senha>;;`). Ao escaneá-lo, o celular anuncia `_adb-tls-pairing._tcp` via mDNS e o app executa `adb pair`.
3. **Conectar** — o app aguarda o serviço `_adb-tls-connect._tcp` do celular e executa `adb connect`. O identificador do aparelho fica salvo para reconectar automaticamente, mesmo quando a porta muda.
4. **Cabo USB (alternativa)** — sem Wi-Fi em comum, o app também conecta pelo cabo com a Depuração USB. Um Galaxy pareado por Wi-Fi passa a usar o cabo automaticamente quando ele está conectado.
5. **Espelhar** — o app envia o servidor ao celular, abre os sockets de vídeo, áudio e controle por um túnel do adb e mostra o vídeo numa janela própria. Clique e arraste para tocar, use a rolagem do trackpad, digite pelo teclado (inclusive acentos), clique com o botão direito para voltar e use os botões Voltar, Início e Recentes da barra de título. A área de transferência é sincronizada nos dois sentidos (⌘V cola no celular).
6. **Reconectar** — se a conexão cair durante o uso, a janela continua aberta com o aviso "Reconectando…" e o app tenta de novo por até 30 segundos, inclusive passando do cabo para o Wi-Fi. Enquanto o app está aberto, o status acompanha em tempo real se o celular está no cabo, no Wi-Fi ou desconectado.

## Limitações

- A Depuração sem fio exige que o Mac e o celular estejam na mesma rede Wi-Fi; pelo hotspot do próprio celular ela não funciona (o app detecta e sugere o cabo USB).
- A Depuração sem fio do Android pode desligar após reiniciar o celular ou trocar de rede. O pareamento continua válido: basta reativá-la no celular ou conectar o cabo USB uma vez, que o app a liga sozinho.
- Apps com conteúdo protegido (bancos, streaming) aparecem com tela preta.

## Contribuindo

Correções e melhorias são bem-vindas. Veja o [guia de contribuição](CONTRIBUTING.md). Para reportar vulnerabilidades, siga a [política de segurança](SECURITY.md).

## Licença

O Galaxy Mirror é distribuído sob a [licença Apache 2.0](LICENSE). Os créditos e as licenças de terceiros estão em [NOTICE](NOTICE) e acompanham o app em `Contents/Resources/`.

## Créditos

O robô do Android no ícone é reproduzido ou modificado a partir de trabalho criado e compartilhado pelo Google, usado de acordo com os termos da [licença Creative Commons 3.0 Attribution](https://creativecommons.org/licenses/by/3.0/). O servidor de espelhamento é o do [scrcpy](https://github.com/Genymobile/scrcpy), da Genymobile, sob a licença Apache 2.0. O `adb` incluído no app é o do Android SDK Platform-Tools, do Google; os avisos de licença vão em `Contents/Resources/adb-NOTICE.txt`.
