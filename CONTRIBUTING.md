# Como Contribuir?

Obrigado pelo interesse em contribuir com o Galaxy Mirror. Este guia descreve o fluxo recomendado para propor correções, melhorias e ajustes de documentação.

## Fluxo de Trabalho

- Faça um fork do repositório e clone o projeto.
- Crie uma branch a partir da branch principal.
- Use nomes de branch objetivos, como `feature/nome-da-feature` ou
  `fix/descricao-do-ajuste`.
- Consulte o `README.md` para compilar, empacotar e rodar o app localmente.
- Mantenha pull requests pequenos e focados em uma mudança principal.
- Explique no pull request o problema resolvido, a solução aplicada e como a
  alteração foi validada.

## Commits

Escreva as mensagens em inglês, curtas, no imperativo e com um prefixo que
indique o tipo da mudança ([Conventional Commits](https://www.conventionalcommits.org/)):

```text
feat: add keyboard shortcut to rotate the phone
fix: keep the mirror window inside the screen on rotation
refactor: move adb parsing into ADBOutputParser
test: cover the track-devices parser
docs: update installation instructions
build: bump the bundled scrcpy server
chore: release v0.2.0-beta.1
```

## Padrões de Código

- Siga a organização existente em `App`, `Models`, `Services`,
  `Services/Mirror`, `ViewModels`, `Views` e `Extensions`.
- Mantenha um tipo por arquivo, com o arquivo nomeado como o tipo; extensões
  ficam em `Extensions/` no formato `Tipo+Assunto.swift`.
- Não adicione comentários no código: prefira nomes claros, funções pequenas e
  tipos explícitos.
- O projeto usa o modo de linguagem Swift 6, com verificação estrita de
  concorrência. Não introduza avisos de compilação.
- Lógica que não depende de interface ou de dispositivo (parsing da saída do
  `adb`, protocolo do scrcpy, cálculos de tamanho) deve ficar em funções puras,
  com testes.
- Textos exibidos ao usuário são em português do Brasil.
- Não inclua no controle de versão os binários baixados pelos scripts
  (`Resources/adb`, `Resources/scrcpy-server`) nem credenciais ou dados
  pessoais.
- Ao atualizar o servidor do scrcpy, altere juntos a versão em
  `ScrcpyProtocol.serverVersion` e o checksum em `scripts/fetch-server.sh`, e
  revise o protocolo (o formato pode mudar entre versões).

## Validação

Antes de abrir um pull request, rode as verificações aplicáveis:

```sh
swift build
swift test
./scripts/build-app.sh
```

Também revise se:

- A alteração está limitada ao escopo proposto.
- A compilação não gera avisos e todos os testes passam.
- Novas regras possuem testes quando aplicável.
- O app foi testado com um celular de verdade quando a mudança afeta conexão,
  espelhamento ou controle (cabo USB e Wi-Fi, quando possível).
- Nenhuma credencial, token ou dado pessoal foi versionado.
- A documentação foi atualizada quando a alteração muda o uso do projeto.

## Pull Requests

Ao abrir um pull request, inclua:

- Um resumo curto da alteração.
- O motivo da mudança.
- Os comandos executados para validação.
- O celular, a versão do Android, a versão do macOS e o tipo de conexão
  usados nos testes manuais.
- Observações sobre impactos de compatibilidade, se existirem.

## Issues

Ao abrir uma issue, informe:

- Descrição clara do problema ou melhoria.
- Passos para reproduzir, quando for um bug.
- Comportamento esperado e comportamento atual.
- Versão do Galaxy Mirror, modelo do celular, versão do Android e do One UI,
  versão do macOS e se o Mac é Apple Silicon ou Intel.
- Tipo de conexão: cabo USB, Wi-Fi ou ambos.
- Logs relevantes, que podem ser obtidos com:

```sh
/usr/bin/log show --last 10m --predicate 'subsystem == "com.julianamarques.GalaxyMirror"' --info
```
