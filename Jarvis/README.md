# JARVIS — Local AI Assistant for iOS

Voice-activated personal AI assistant powered by a **local on-device LLM**, built with SwiftUI and targeting iOS 17+.

## Features

- **Text and voice input**: Type or tap-to-talk; streaming STT via Apple Speech framework
- **Streaming LLM responses**: Token-by-token display with optional TTS (AVSpeechSynthesizer)
- **Dark sci-fi UI**: Orb, waveform, message bubbles, glassmorphism
- **Settings**: Model selection, voice, temperature, max tokens, auto-listen, show/hide text
- **Onboarding**: First-launch flow and permissions (microphone, speech recognition)

## Project structure

- **App**: `JarvisApp.swift`, `AppState.swift`
- **Core/LLM**: `LLMEngine` (stub; ready for llama.cpp), `LLMConfiguration`, `ModelManager`, `PromptFormatter`
- **Core/Speech**: `SpeechRecognizer`, `SpeechSynthesizer`, `AudioSessionManager`
- **Core/Assistant**: `AssistantController`, `ConversationManager`, `SystemPrompt`
- **Models**: `Message`, `Conversation`, `AssistantSettings`
- **Views**: `MainView`, `ChatView`, `OrbView`, `WaveformView`, `SettingsView`, `OnboardingView`, plus components
- **Extensions**: `Color+Theme`, `View+Animations`
- **Utilities**: `HapticManager`, `PermissionsManager`
- **Tests**: `JarvisTests` (unit), `JarvisUITests` (UI)

## Running the app

1. Open `Jarvis.xcodeproj` in Xcode.
2. Select an iOS Simulator or device (iOS 17+).
3. Build and run (⌘R).

On first run you’ll see onboarding; tap **Get started**, then use the main screen to type a message or **Tap to talk** for voice (grant mic and speech recognition when prompted).

## LLM (llama.cpp) integration

The app currently uses a **stub** `LLMEngine` that returns a fixed response so it runs without a native LLM. To use a real GGUF model:

1. **Add a Swift package** (in Xcode: File → Add Package Dependencies):
   - **Option A**: [llama.swift](https://github.com/mattt/llama.swift) — `https://github.com/mattt/llama.swift` (semantic version, e.g. from 2.8175.0)
   - **Option B**: Use the official [llama.cpp](https://github.com/ggerganov/llama.cpp) XCFramework build and link it manually.

2. **Replace or extend** `Core/LLM/LLMEngine.swift` to call the llama C API:
   - `llama_model_load` / `llama_context_init` in `loadModel(at:config:)`
   - Tokenize prompt, then `llama_decode` + sampling loop in `generate(prompt:)`, yielding each token via the `AsyncStream` continuation.
   - Keep all llama calls on a single thread/actor (llama.cpp is not thread-safe).

3. **Models**: Place `.gguf` files in the app’s **Documents/Models** directory (or add them to the target’s **Resources/Models**). Recommended: Llama 3.2 3B Instruct Q4_K_M (~1.8 GB).

## Permissions

The project is configured with:

- **Microphone**: “JARVIS uses the microphone for voice commands.”
- **Speech recognition**: “JARVIS uses speech recognition to understand your requests.”

## Tests

- **Unit tests**: `JarvisTests` — `PromptFormatter`, `Message`, `ConversationManager`, `LLMEngine` (stub).
- **UI tests**: `JarvisUITests` — launch and presence of “JARVIS” or “Get started”.

Run tests in Xcode with ⌘U.
