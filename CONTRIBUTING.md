# How to Contribute

Thank you for your interest in contributing to Galaxy Mirror. This guide describes the recommended workflow for proposing fixes, improvements and documentation changes.

## Workflow

- Fork the repository and clone the project.
- Create a branch from the main branch.
- Use descriptive branch names, such as `feature/feature-name` or
  `fix/short-description`.
- See `README.md` to build, package and run the app locally.
- Keep pull requests small and focused on one main change.
- In the pull request, explain the problem solved, the solution applied and how
  the change was validated.

## Commits

Write messages in English, short, in the imperative mood and with a prefix that
indicates the type of change ([Conventional Commits](https://www.conventionalcommits.org/)):

```text
feat: add keyboard shortcut to rotate the phone
fix: keep the mirror window inside the screen on rotation
refactor: move adb parsing into ADBOutputParser
test: cover the track-devices parser
docs: update installation instructions
build: bump the bundled scrcpy server
chore: release v0.2.0-beta.1
```

## Code Standards

- Follow the existing organization in `App`, `Models`, `Services`,
  `Services/Mirror`, `ViewModels`, `Views` and `Extensions`.
- Keep one type per file, with the file named after the type; extensions go
  in `Extensions/` in the `Type+Topic.swift` format.
- Do not add comments to the code: prefer clear names, small functions and
  explicit types.
- The project uses the Swift 6 language mode, with strict concurrency
  checking. Do not introduce compiler warnings.
- Logic that does not depend on the UI or on a device (parsing `adb` output,
  the scrcpy protocol, size calculations) should live in pure functions, with
  tests.
- User-facing strings are written in Brazilian Portuguese in the code and
  translated to English in `Resources/Localizable.xcstrings`. After adding or
  changing strings, run `scripts/sync-strings.sh` and fill in the translation;
  `swift test` fails while any string is untranslated or has placeholders
  that differ from the original.
- Do not commit the binaries downloaded by the scripts
  (`Resources/adb`, `Resources/scrcpy-server`), credentials or personal
  data.
- When updating the scrcpy server, change the version in
  `ScrcpyProtocol.serverVersion` and the checksum in `scripts/fetch-server.sh`
  together, and review the protocol (the format may change between versions).

## Validation

Before opening a pull request, run the applicable checks:

```sh
swift build
swift test
./scripts/build-app.sh
```

Also check that:

- The change is limited to the proposed scope.
- The build has no warnings and all tests pass.
- New rules have tests when applicable.
- New strings show up correctly in Portuguese and in English.
- The app was tested with a real phone when the change affects connection,
  mirroring or control (USB cable and Wi-Fi, when possible).
- No credentials, tokens or personal data were committed.
- The documentation was updated when the change affects how the project is
  used.

## Pull Requests

When opening a pull request, include:

- A short summary of the change.
- The reason for the change.
- The commands run for validation.
- The phone, Android version, macOS version and type of connection used in
  manual testing.
- Notes on compatibility impacts, if any.

## Issues

When opening an issue, include:

- A clear description of the problem or improvement.
- Steps to reproduce, for a bug.
- Expected behavior and current behavior.
- The Galaxy Mirror version, phone model, Android and One UI versions,
  macOS version and whether the Mac is Apple Silicon or Intel.
- The type of connection: USB cable, Wi-Fi or both.
- Relevant logs, which can be collected with:

```sh
/usr/bin/log show --last 10m --predicate 'subsystem == "com.julianamarques.GalaxyMirror"' --info
```
