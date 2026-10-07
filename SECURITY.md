# Política de Segurança

## Versões Suportadas

O Galaxy Mirror está em beta. Apenas a versão mais recente publicada em
[Releases](https://github.com/julianamarques/galaxy-mirror/releases) recebe
correções de segurança.

| Versão                 | Suportada |
| ---------------------- | --------- |
| Mais recente (0.1.x)   | Sim       |
| Anteriores             | Não       |

## Como Reportar uma Vulnerabilidade

Não abra uma issue pública para relatar vulnerabilidades.

Use o reporte privado do GitHub: na aba **Security** do repositório, clique em
**Report a vulnerability**. O relato fica visível apenas para a mantenedora até
que uma correção seja publicada.

Inclua, sempre que possível:

- Descrição do problema e do impacto.
- Passos para reproduzir ou uma prova de conceito.
- Versão do Galaxy Mirror, versão do macOS, modelo do celular e versão do
  Android.
- Tipo de conexão envolvido: cabo USB, Wi-Fi ou ambos.
- Sugestão de correção, se houver.

## O Que Esperar

- Confirmação do recebimento em até 7 dias.
- Avaliação inicial e retorno sobre a gravidade em até 14 dias.
- Correção publicada em uma nova versão, com crédito a quem reportou, se
  desejado.

Por ser um projeto mantido por uma pessoa, os prazos podem variar; o relato
será acompanhado até a conclusão.

## Escopo

Estão no escopo:

- O código do app: pareamento, descoberta na rede, conexão por cabo e Wi-Fi,
  implementação do protocolo do scrcpy, envio de toques e teclas e
  sincronização da área de transferência.
- Os scripts de build e empacotamento, incluindo a verificação de checksum
  dos componentes baixados.

Fora do escopo (reporte diretamente aos projetos de origem):

- Vulnerabilidades no servidor do scrcpy:
  [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy).
- Vulnerabilidades no `adb` ou no Android:
  [Android Security](https://source.android.com/docs/security/overview/updates-resources).
- Ataques que exigem acesso físico ao Mac desbloqueado ou ao celular
  desbloqueado.
- O aviso do Gatekeeper na primeira abertura, causado pela assinatura local do
  app (comportamento conhecido e documentado no README).

## Considerações de Segurança para Usuários

- A Depuração USB e a Depuração sem fio do Android dão ao computador pareado
  controle total do celular. Pareie apenas Macs de sua confiança e revogue os
  que não usa mais em **Opções do desenvolvedor › Depuração sem fio ›
  Dispositivos pareados**.
- Ao espelhar pelo cabo um celular que já foi pareado por Wi-Fi, o app liga a
  Depuração sem fio automaticamente, para permitir a troca do cabo para o
  Wi-Fi. Desligue-a nas Opções do desenvolvedor quando estiver em redes que
  não são de sua confiança.
- Use o espelhamento sem fio apenas em redes confiáveis. A conexão do `adb` é
  criptografada, mas o celular fica visível na rede enquanto a Depuração sem
  fio estiver ativa.
- A área de transferência é sincronizada entre o Mac e o celular durante o
  espelhamento: evite copiar senhas ou dados sensíveis nesse período se não
  quiser que passem para o outro aparelho.
- Baixe o app apenas pela página de Releases deste repositório.
