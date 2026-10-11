> **Talkify TW：給台灣工程師的 fork**
>
> 這是 [tornikegomareli/Talkify](https://github.com/tornikegomareli/Talkify) 的 fork。講話時的即時草稿仍然用 Apple 的語音辨識，放開按鍵後整段錄音會交給聯發科研究院的 [Breeze ASR 25](https://huggingface.co/MediaTek-Research/Breeze-ASR-25) 再聽一次，最後貼上的是 Breeze 的結果。Apple 的引擎在中文句子裡會把 deploy 聽成「thepoy」、Kubernetes 聽成「Cubernatis」，Breeze 不會。中英之間會自動留空白，也可以說「逗號」「句號」「換行」「刪掉」。
>
> 沒有簽章過的發行版，要在自己的 Mac 上編譯：裝好 Xcode 之後執行 `brew install rust cmake`，再 `./build-local.sh`。它會編譯、裝到 `/Applications/Talkify TW.app`，並下載 1 GB 的模型。之後在 Settings → Language 選「中文（台灣）」。語音模型和文字規則與 Linux 版共用，來自 [omarchy-talkify-tw](https://github.com/Unayung/omarchy-talkify-tw)。詞庫是 `~/.config/talkify/words.txt`。
>
> **Talkify TW, a fork for Taiwanese engineers.** Apple Speech still draws the live draft; on release the recording is heard again by [Breeze ASR 25](https://huggingface.co/MediaTek-Research/Breeze-ASR-25) (MediaTek Research, Apache 2.0), and its text is what lands. Build it on your own Mac with `./build-local.sh`; there are no signed releases. The rest of this page is upstream's.

<p align="center">
  <img src="docs/assets/app-icon.png" width="96" alt="Talkify icon" />
  <h1 align="center">Talkify</h1>
</p>

<h3 align="center">Fast, private voice dictation for macOS, right from the notch</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6-orange.svg" />
  <img src="https://img.shields.io/badge/macOS-26+-blue.svg" />
  <img src="https://img.shields.io/badge/Apple%20Silicon-arm64-lightgrey.svg" />
  <img src="https://github.com/tornikegomareli/Talkify/actions/workflows/ci.yml/badge.svg" />
</p>

<p align="center">
  <a href="https://trendshift.io/repositories/158302?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-158302" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/158302/daily?language=Swift" alt="tornikegomareli%2FTalkify | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/158302?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-158302" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/158302/weekly?language=Swift" alt="tornikegomareli%2FTalkify | Trendshift" width="250" height="55"/></a>
</p>

## Showcase


<p align="center">
  <img src="docs/assets/showreel.gif" width="90%" alt="Talkify's six voice visuals playing together: Edge Glow in Sunset, Aurora, Spectrum and Ocean, Compact captions, and the Siri-style waveform" />
</p>

<p align="center">
  <img src="docs/assets/settings-appearance.jpg" width="45%" alt="Settings: Appearance, with a live HUD preview" />
  <img src="docs/assets/settings-insights.jpg" width="45%" alt="Settings: Insights, computed and stored locally" />
</p>

## Privacy

Everything is on-device: Apple's `SpeechAnalyzer`/`SpeechTranscriber` for recognition, `AVSpeechSynthesizer` for Read Aloud, `Translation` for translation, and `FoundationModels` for prompt shaping. That last one is a language model, and it is Apple's, running here: there is no key, no account, and no request. Talkify makes no network requests, stores no audio, and keeps no history beyond the local usage metrics you can see in Insights.

Two caveats. Read Aloud reads a selection through Accessibility where it can,
and by copying it where it cannot, which is any web page: the selection passes
through the clipboard and the previous clipboard is put back afterwards.

And dictated text is inserted by pasting it, so it passes through the system clipboard for up to about half a second before your previous clipboard is put back. A clipboard manager or Universal Clipboard can see it during that window.

## Requirements

- macOS 26 (Tahoe) on Apple Silicon

## Install

With Homebrew:

```bash
brew install --cask tornikegomareli/talkify/talkify
```

The full name is what makes it one line. Homebrew 6 will not load anything from
a third-party tap until you trust it, but installing by full name adds the tap
and trusts this one cask on its own — nothing else in the tap, and no separate
`brew trust`. [Read the cask](Casks/talkify.rb) first if you would rather see
what it does.

Or grab [**Talkify.dmg**](https://github.com/tornikegomareli/Talkify/releases/latest/download/Talkify.dmg) from the latest release.

Build from source:

```bash
git clone https://github.com/tornikegomareli/Talkify.git
cd Talkify
open Talkify.xcodeproj   # ⌘R
```

Or headless:

```bash
xcodebuild -project Talkify.xcodeproj -scheme Talkify -configuration Debug build
```

Run the tests the same way CI does:

```bash
xcodebuild test -project Talkify.xcodeproj -scheme Talkify -destination 'platform=macOS'
```

## Using it

| Action | Gesture |
|---|---|
| Dictate | Hold **fn**, speak, release |
| Hands-free session | Quick-tap **fn**, speak, tap again to finish |
| Dictate in your second language | Hold **right ⌥** instead |
| Dictate and translate | Hold **right ⌘** instead |
| Transcribe a file | Drag audio or video at the notch and drop it |
| Cancel mid-session | **Esc** |
| Shape what you dictate | Turn it on in **Settings → Prompt Shaping** |
| Pick the shaping prompt mid-session | **←** / **→** while dictating, with shaping on |
| Read selected text aloud | **⌥ ⎋** (toggles; also in the menu) |
| Read it aloud translated | Same key, with **Translate before speaking** on |
| Everything else | Menu bar ghost → Settings |

The trigger and the Read Aloud shortcut are rebindable in **Settings → Shortcuts**.
Direct Dictation can use a keyboard key, Middle Click by pressing the scroll
wheel, or another auxiliary mouse button. A bound button keeps its usual action
unless the exact combination you bound is pressed, so binding ⌥ + Middle Click
leaves plain middle click alone.

## Drop a file on the notch

<p align="center">
  <img src="docs/assets/drop-transcription.gif" width="90%" alt="A transcript card in the notch being dragged out and dropped into another app" />
</p>

Drag an audio or video file to the top of the screen and the island opens to
take it. It transcribes in the background, so **fn** keeps working, and the menu
bar ghost shows progress.

When it finishes the island comes back holding the transcript. Drag it to a
folder for the `.txt`, or to a text field for the words. Click to copy. Leave it
and after five seconds it saves next to the source file, or into a folder you set
in **Settings → Drop Transcription**. Hovering pauses that timer.

With a second dictation language configured, the target splits in two and the
half you drop on picks the language. **Transcribe File…** in the menu does the
same with a picker.

## Speak one language, insert another

Pick a language in **Settings → Language** and the Translate key writes in it.
Hold **right ⌘**, say it in English, and Spanish lands in the document. The key
does not change when the language does, so there is one shortcut to remember.

Translation runs on your Mac through Apple's Translation framework, and the notch
shows the pair before you speak. If it fails, nothing is pasted and your words go
to the clipboard.

It works the other way too. Turn on **Translate before speaking** in
**Settings → Read Aloud**, select text in a language you do not read, and the
Read Aloud key speaks it in your voice's language. The voice is the target, so
there is nothing else to set.

## Shape what you dictate (beta)

Turn on **Shape dictation with a prompt** in **Settings → Prompt Shaping** and
the prompt you pick rewrites finished dictation through Apple's on-device model
before it is inserted. Three prompts are built in, tighten grammar, bullet
lists and remove filler words, and the library shows each one's instruction
under its name so you pick by reading rather than by remembering.

Edit any of them, or write your own. The instruction is the whole prompt for
most of them; a closing instruction and a worked example are there under
**Advanced** when you want them. You can also try a prompt before you use it:
type a sample sentence, press **Try**, and see what the model does with it. It
runs the same on-device model a real session runs, so what you see is what you
will get. The framing that keeps the model rewriting your words instead of
answering them is fixed and not editable.

While you dictate, a caption under the notch names the prompt the session will
shape with, colored from your Edge Glow palette and moving with your voice, and
the bare arrow keys cycle through your prompts — or **None**, to insert the
words exactly as spoken. After you release, the island stays up and the same
caption names the prompt while the rewrite runs. Shaping is a beta and fails
safe: any error, or an answer slower than ten seconds, inserts your raw words
unchanged, history keeps what you actually said, and nothing leaves your Mac.

## Two languages, two triggers

Pick a second language in **Settings → Language** and it gets its own trigger. Hold
**fn** for English, hold **right ⌥** for German, with no setting to change in
between. Both triggers are rebindable, and either can use a keyboard key or a
supported mouse button.

## Architecture

Code is organized into folders, callbacks only flow one way from the main wiring point, and a pure reducer handles the state.

- `App/`: composition root, settings store, status item
- `Input/`: the global key event tap and recorded bindings
- `Dictation/`: the session machine (`DictationSessionMachine`, a pure tested reducer), the speech/insertion services, and the HUD surface and voice visuals only dictation draws
- `Translation/`: the coordinator both callers talk to, the rules, and the two files that import Apple's Translation framework
- Prompt shaping lives in `Dictation/`: the prompt model, the service that races the on-device model against a timeout, and the caption the HUD draws
- `DropTranscription/`: the drag gesture, the file transcription service, where a transcript is staged and lands, and its own HUD surfaces
- `CoreHUD/`: what both features share: `HUDStage` owns the single panel and decides who holds the shape, plus the geometry seams and Metal shaders
- `ReadAloud/`, `Settings/`, `Insights/`

`CONTEXT.md` is the domain doc, decisions live in `docs/adr/`, and
[`CONTRIBUTING.md`](CONTRIBUTING.md) is the contract for changing any of it

## Roadmap

- **Live Captions & Meeting Transcripts**. Ephemeral captions from a selected app's audio (Chrome, YouTube, meeting apps), and the saved, timestamped transcript as a separate action. The domain design already lives in `CONTEXT.md`; the recognition pipeline is ready for non-microphone audio.
- **Text cleanup**. Shipping as the prompt shaping beta above — on-device rewriting of finished dictation, off by default. Per-application profiles and a benchmarked default remain future work; with shaping off, Talkify still inserts exactly what you said.
- **Snippets**. Saved text blocks inserted by a spoken trigger word: say your trigger mid-dictation and the whole block lands instead.

## Contributing

Read [**CONTRIBUTING.md**](CONTRIBUTING.md) first. It covers the issue-first
flow, branch and pull request naming, code style, the AI policy, and what a bug
report needs to contain to be actionable.

Start from an issue. A pull request that arrives without one behind it may be
closed, however good the code is, because design belongs in the issue where it is
still cheap to change.

## License
[MIT](LICENSE)
