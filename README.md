# Weather App

A modern Flutter weather application with features like authentication, asset management, statistics, and user profile. The app is designed with a vibrant gradient UI, glassmorphism cards, and a responsive layout for an enhanced user experience.

## Features
- **Login & Sign Up**: Secure authentication with form validation.
- **Home (Asset List)**: View weather assets with temperature and last updated information.
- **Asset Detail**: Detailed weather data including temperature, humidity, rainfall, and wind.
- **Statistics/Chart**: Select asset, attribute, and date range to view charts and download data.
- **Account/Profile**: Manage user information, select language, and log out.
- **Modern UI**: Blue-purple gradients, glassmorphism cards, and responsive design.

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) (3.x recommended)
- Dart SDK

### Installation
1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd <project-folder>
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Packages Used
- `intl` (for date formatting)
- `http` (for API calls)

## Usage

### Fake Login
- Use the following credentials to log in:
  - **Email:** `user@test.com`
  - **Password:** `123456`
- Any other credentials will show an error message.

### Navigation
- The app uses a bottom navigation bar to switch between Home, Asset Detail, Chart, and Account pages.
- Tap on asset cards to view details.
- In the Chart section, tap the date fields to select start and end dates using a calendar picker.

## Screenshots
> Add screenshots of your app here for a visual overview.

| Home (Asset List) | Asset Detail | Chart | Account |
|-------------------|--------------|-------|---------|
| ![Home](screenshots/home.png) | ![Detail](screenshots/detail.png) | ![Chart](screenshots/chart.png) | ![Account](screenshots/account.png) |

## Customization
- Update the fake login logic in `lib/login.dart` for real authentication.
- Replace chart placeholder with a real chart widget (e.g., `fl_chart`).
- Connect to your backend or weather API for live data.

## Troubleshooting

### Common Issues
- **ADB Installation Error**: If you encounter an error during installation, ensure your emulator is running or your device is connected properly. Use `flutter doctor` to diagnose issues.
- **API Errors**: Check the API endpoints and ensure the backend is running.

### Debugging
- Use `flutter run -v` for verbose logs.
- Check the `lib/api_service.dart` file for API-related issues.

## License
This project is for educational/demo purposes. Add your license here if needed.
