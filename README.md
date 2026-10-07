# Galaxy Mirror

Espelhe e controle um celular Samsung Galaxy (ou qualquer Android 11+) no macOS, sem fio — com uma configuração guiada no estilo do Espelhamento do iPhone.

O app cuida do pareamento (por QR code ou código de seis dígitos), da descoberta do celular na rede e da reconexão automática. O espelhamento é nativo: o app envia ao celular o servidor do [scrcpy](https://github.com/Genymobile/scrcpy) (versão fixa, 5.0), recebe o vídeo e o áudio pelo protocolo dele e exibe tudo numa janela própria, com decodificação por hardware (VideoToolbox) e controle por mouse, trackpad e teclado.

## Requisitos

- macOS 14 ou posterior
- `adb`: `brew install android-platform-tools`
- Celular com Android 11+ na mesma rede Wi-Fi do Mac

## Compilar

```bash
./scripts/build-app.sh          # gera build/Galaxy Mirror.app
open "build/Galaxy Mirror.app"
```

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
Resources/        Info.plist, ícone e scrcpy-server (baixado com checksum por scripts/fetch-server.sh)
scripts/          build do .app, download do servidor e geração do ícone
```

## Como funciona

1. **Preparar o Galaxy** — ativar as Opções do desenvolvedor e a Depuração sem fio.
2. **Parear** — o app mostra um QR code no mesmo formato do Android Studio (`WIFI:T:ADB;S:<nome>;P:<senha>;;`). Ao escaneá-lo, o celular anuncia `_adb-tls-pairing._tcp` via mDNS e o app executa `adb pair`.
3. **Conectar** — o app aguarda o serviço `_adb-tls-connect._tcp` do celular e executa `adb connect`. O identificador do aparelho fica salvo para reconectar automaticamente, mesmo quando a porta muda.
4. **Cabo USB (alternativa)** — sem Wi-Fi em comum, o app também conecta pelo cabo com a Depuração USB. Um Galaxy pareado por Wi-Fi passa a usar o cabo automaticamente quando ele está conectado.
5. **Espelhar** — o app envia o servidor ao celular, abre os sockets de vídeo, áudio e controle por um túnel do adb e mostra o vídeo numa janela própria. Clique e arraste para tocar, use a rolagem do trackpad, digite pelo teclado (inclusive acentos), clique com o botão direito para voltar e use os botões Voltar, Início e Recentes da barra de título. A área de transferência é sincronizada nos dois sentidos (⌘V cola no celular).

## Limitações

- A Depuração sem fio exige que o Mac e o celular estejam na mesma rede Wi-Fi; pelo hotspot do próprio celular ela não funciona (o app detecta e sugere o cabo USB).
- A Depuração sem fio do Android desliga após reiniciar o celular ou trocar de rede; é preciso reativá-la (o pareamento continua válido).
- Apps com conteúdo protegido (bancos, streaming) aparecem com tela preta.
- A janela de espelhamento é a do scrcpy; um renderizador nativo (VideoToolbox + Metal) é um próximo passo possível.

## Créditos

O robô do Android no ícone é reproduzido ou modificado a partir de trabalho criado e compartilhado pelo Google, usado de acordo com os termos da [licença Creative Commons 3.0 Attribution](https://creativecommons.org/licenses/by/3.0/). O servidor de espelhamento é o do [scrcpy](https://github.com/Genymobile/scrcpy), da Genymobile, sob a licença Apache 2.0.
