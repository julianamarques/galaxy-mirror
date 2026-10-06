# Espelhamento do Galaxy

Espelhe e controle um celular Samsung Galaxy (ou qualquer Android 11+) no macOS, sem fio — com uma configuração guiada no estilo do Espelhamento do iPhone.

O app cuida do pareamento (por QR code ou código de seis dígitos), da descoberta do celular na rede e da reconexão automática. A transmissão de vídeo, áudio e controle é feita pelo [scrcpy](https://github.com/Genymobile/scrcpy).

## Requisitos

- macOS 14 ou posterior
- `adb` e `scrcpy`: `brew install scrcpy android-platform-tools`
- Celular com Android 11+ na mesma rede Wi-Fi do Mac

## Compilar

```bash
./scripts/build-app.sh          # gera build/Espelhamento do Galaxy.app
open "build/Espelhamento do Galaxy.app"
```

Para desenvolvimento, `swift run` também funciona, e `swift test` roda os testes. Em builds de debug, `GALAXY_STEP=pair` (ou `prepare`, `code`, `connecting`, `failed`, `done`, `missing`) abre direto numa etapa da configuração.

## Estrutura

```
Sources/GalaxyMirror/
├── App/          ponto de entrada (GalaxyMirrorApp, AppDelegate)
├── Models/       tipos de dados (PairedDevice, MDNSService, Quality, Codec, SettingsKey…)
├── Services/     integração com adb e scrcpy (ADB, ADBOutputParser, Scrcpy, MirrorArguments, Tools)
├── ViewModels/   estado observável (AppModel, SetupModel)
├── Views/        telas SwiftUI (Setup, Device, Settings) e componentes reutilizáveis
└── Extensions/   extensões de tipos do sistema
Tests/GalaxyMirrorTests/
Resources/        Info.plist e ícone usados ao empacotar o .app
scripts/          build do .app e geração do ícone
```

## Como funciona

1. **Preparar o Galaxy** — ativar as Opções do desenvolvedor e a Depuração sem fio.
2. **Parear** — o app mostra um QR code no mesmo formato do Android Studio (`WIFI:T:ADB;S:<nome>;P:<senha>;;`). Ao escaneá-lo, o celular anuncia `_adb-tls-pairing._tcp` via mDNS e o app executa `adb pair`.
3. **Conectar** — o app aguarda o serviço `_adb-tls-connect._tcp` do celular e executa `adb connect`. O identificador do aparelho fica salvo para reconectar automaticamente, mesmo quando a porta muda.
4. **Cabo USB (alternativa)** — sem Wi-Fi em comum, o app também conecta pelo cabo com a Depuração USB. Um Galaxy pareado por Wi-Fi passa a usar o cabo automaticamente quando ele está conectado.
5. **Espelhar** — o `scrcpy` é aberto com as opções escolhidas em Ajustes (qualidade, codec, áudio, apagar a tela do celular etc.).

## Limitações

- A Depuração sem fio exige que o Mac e o celular estejam na mesma rede Wi-Fi; pelo hotspot do próprio celular ela não funciona (o app detecta e sugere o cabo USB).
- A Depuração sem fio do Android desliga após reiniciar o celular ou trocar de rede; é preciso reativá-la (o pareamento continua válido).
- Apps com conteúdo protegido (bancos, streaming) aparecem com tela preta.
- A janela de espelhamento é a do scrcpy; um renderizador nativo (VideoToolbox + Metal) é um próximo passo possível.
