# RyAI Configuration

## Getting Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key

## Setup

Replace `YOUR_GEMINI_API_KEY` in `lib/gemini_service.dart` with your actual API key.

```dart
static const String _apiKey = 'your_actual_api_key_here';
```

## Usage

In any chat, type:
- `@RyAI What is Flutter?`
- `@RyAI Explain quantum physics`
- `@RyAI Help me with coding`

RyAI will respond with intelligent answers!
