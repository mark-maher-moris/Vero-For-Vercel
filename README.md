# Vero For Vercel

A secure, open-source Flutter application for managing your Vercel projects, deployments, and teams directly from your mobile device.

<p align="center">
  <img src="assets/logo.png" alt="Vero Logo" width="120"/>
</p>

## 🔒 Security & Privacy First

**Your data belongs to you. Period.**

| Feature | Status |
|---------|--------|
| **No Backend Server** | ✅ This app connects DIRECTLY to Vercel's API from your device |
| **No Data Collection** | ✅ Zero telemetry, zero analytics, zero tracking |
| **No Data Sharing** | ✅ Nothing leaves your device except API calls to Vercel |
| **Secure Storage** | ✅ Tokens stored in platform-native secure storage (iOS Keychain / Android Keystore) |
| **Open Source** | ✅ 100% transparent. Audit every line of code |
| **No Third-Party Services** | ✅ No Firebase, no Google Analytics, no crash reporting |

**What this means:**
- We literally cannot see your projects, deployments, or any data
- We cannot track your usage or behavior
- We cannot sell or share your information (we don't have it)
- Your tokens are encrypted and stored only on your device
- No cloud services, no databases, no logs on our end

---

## Features

- **Projects Dashboard** - View and manage all your Vercel projects with real-time status updates
- **Deployments** - Track deployment history, view build logs, and monitor deployment status
- **Team Management** - Manage team access, invite members, and control permissions
- **Environment Variables** - Securely view, add, edit, and delete project environment variables
- **Domains & DNS** - Manage custom domains, configure DNS settings, and verify domain ownership
- **Usage & Billing** - Monitor bandwidth, builds, and team usage analytics
- **Activity Feed** - Stay updated with real-time project activity and notifications
- **Secure OAuth** - Authenticate securely with Vercel using OAuth 2.0 PKCE flow

## Security & Privacy

- **No Backend Server** - This app is entirely client-side. It connects directly to Vercel's official API from your device
- **No Data Collection** - We do not collect, store, or share any of your data. All information stays on your device
- **Secure Storage** - Authentication tokens are stored securely using platform-native secure storage (Keychain/Keystore)
- **Direct API Connection** - All requests go directly to `api.vercel.com` - no intermediary servers
- **Open Source** - Full transparency. You can audit every line of code that handles your data

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Vercel REST API** - Official Vercel API integration
- **OAuth 2.0 + PKCE** - Secure authentication flow
- **Provider** - State management
- **Shared Preferences** - Local secure storage

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.7)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- A Vercel account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/vero.git
cd vero
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure your Vercel OAuth app credentials in `lib/services/auth_service.dart`:
```dart
static const String clientId = 'YOUR_CLIENT_ID';
static const String clientSecret = 'YOUR_CLIENT_SECRET';
static const String redirectUri = 'YOUR_REDIRECT_URI';
```

4. Run the app:
```bash
flutter run
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

See the [LICENSE](LICENSE) file for full details.

### Why AGPL-3.0?

This license ensures that:
- The software remains free and open source forever
- Any modifications must be shared under the same license
- No one can make this project closed source and profit from it without contributing back
- Commercial use requires sharing source code
- Protects against proprietary forks

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Disclaimer

This is an unofficial third-party application. "Vercel" is a trademark of Vercel, Inc. This app is not affiliated with, endorsed by, or sponsored by Vercel, Inc.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.

---

<p align="center">
  Made with ❤️ for the Vercel community
</p>
