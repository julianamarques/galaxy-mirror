# Security Policy

## Supported Versions

Galaxy Mirror is in beta. Only the latest version published on
[Releases](https://github.com/julianamarques/galaxy-mirror/releases) receives
security fixes.

| Version                | Supported |
| ---------------------- | --------- |
| Latest (0.1.x)         | Yes       |
| Earlier                | No        |

## Reporting a Vulnerability

Do not open a public issue to report vulnerabilities.

Use GitHub's private reporting: in the repository's **Security** tab, click
**Report a vulnerability**. The report is visible only to the maintainer until
a fix is published.

Whenever possible, include:

- A description of the problem and its impact.
- Steps to reproduce or a proof of concept.
- The Galaxy Mirror version, macOS version, phone model and Android
  version.
- The type of connection involved: USB cable, Wi-Fi or both.
- A suggested fix, if any.

## What to Expect

- Acknowledgment of the report within 7 days.
- An initial assessment and feedback on severity within 14 days.
- A fix published in a new version, crediting the reporter if they wish.

Since the project is maintained by one person, these timelines may vary; the
report will be followed through to the end.

## Scope

In scope:

- The app's code: pairing, network discovery, cable and Wi-Fi connections,
  the scrcpy protocol implementation, sending touches and keys, and clipboard
  syncing.
- The build and packaging scripts, including the checksum verification of
  downloaded components.

Out of scope (report directly to the upstream projects):

- Vulnerabilities in the scrcpy server:
  [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy).
- Vulnerabilities in `adb` or Android, including the lack of verification of
  the phone's identity on wireless connections:
  [Android Security](https://source.android.com/docs/security/overview/updates-resources).
- Attacks that require physical access to the unlocked Mac or the unlocked
  phone.
- The Gatekeeper warning on first launch, caused by the app's local signature
  (known behavior, documented in the README).

## Security Considerations for Users

- Android's USB debugging and Wireless debugging give the paired computer full
  control of the phone. Pair only Macs you trust and revoke the ones you no
  longer use in **Developer options › Wireless debugging › Paired devices**.
- When mirroring over the cable a phone that was already paired over Wi-Fi,
  the app turns on Wireless debugging automatically, so it can switch from the
  cable to Wi-Fi. Turn it off in Developer options when you are on networks you
  do not trust.
- Wi-Fi mode trusts the local network, just like `adb` itself. The connection
  is encrypted, but `adb` does not check the phone's identity on wireless
  connections: another device on the same network could impersonate your
  Galaxy. If that happened, it could see what you type in the mirror window,
  receive what you paste into it, change the Mac's clipboard and show a fake
  screen. Use wireless mirroring only on trusted networks (such as your home
  network) and prefer the USB cable on public or shared networks. The phone
  is also visible on the network while Wireless debugging is on.
- The clipboard is synced between the Mac and the phone while mirroring: avoid
  copying passwords or sensitive data during that time if you do not want them
  to reach the other device.
- Download the app only from this repository's Releases page.
