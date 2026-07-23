# TailorConnect — Customer Mobile App (Flutter)

A premium Flutter mobile application for the **Customer** side of the TailorConnect system.

## 🏗️ Architecture Overview

```
lib/
├── main.dart               ← App entry + global colors (AppColors)
├── models/
│   ├── customer_model.dart ← Logged-in customer data
│   ├── tailor_model.dart   ← Tailor shop data (shared with Tailor dashboard)
│   ├── order_model.dart    ← Order + OrderStatus enum + ChatMessage
│   └── scan_result_model.dart ← AI body scan result
├── api/
│   ├── api_config.dart     ← ⚠️ SET YOUR PYTHON SERVER IP HERE
│   └── api_service.dart    ← All backend calls (mock → real via comments)
├── data/
│   └── mock_data.dart      ← Static development data (swap when DB is ready)
├── providers/
│   └── app_provider.dart   ← Central state (ChangeNotifier)
├── screens/
│   ├── main_shell.dart     ← Bottom nav + tab routing
│   ├── home_screen.dart    ← Tab 1: Welcome, stats, nearby tailors
│   ├── orders_screen.dart  ← Tab 2: My orders + create request wizard
│   ├── ai_scan_screen.dart ← Tab 3: AI body measurement scanner
│   ├── chat_screen.dart    ← Tab 4: Messaging with tailors
│   ├── profile_screen.dart ← Tab 5: Customer profile + measurements
│   └── tailor_details_screen.dart ← Full tailor profile overlay
└── widgets/
    ├── tailor_card.dart         ← Reusable tailor list item
    ├── order_card.dart          ← Reusable order list item
    ├── order_detail_sheet.dart  ← Order tracking bottom sheet
    ├── create_order_wizard.dart ← 3-step order creation wizard
    └── toast_banner.dart        ← Floating notification banner
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x installed ([flutter.dev/install](https://flutter.dev/install))
- Android Studio or VS Code with Flutter extension
- An Android or iOS device / emulator

### Run the App
```bash
flutter pub get
flutter run
```

## 🔗 Connecting to the Python Backend

1. Open `lib/api/api_config.dart`
2. Set `baseUrl` to your Python server's IP:
   ```dart
   static const String baseUrl = 'http://YOUR_SERVER_IP:8000';
   ```
3. In `lib/api/api_service.dart`, uncomment the real HTTP code blocks and remove the mock returns.

> **Important:** Both the Customer app (this project) and the **Tailor dashboard** on the other laptop must use the **same** server IP. Both apps share the same Python + MySQL backend.

## 📋 Shared Data Contract with Tailor Dashboard

All JSON field names used in the models match the Python backend schema:

| Flutter Model | Python Table | Key Fields |
|---|---|---|
| `TailorModel` | `tailors` | `tailor_id`, `shop_name`, `rating` |
| `OrderModel` | `orders` | `order_id`, `tailor_id`, `status`, measurements |
| `ChatMessage` | `messages` | `message_id`, `sender_role`, `message_text` |
| `CustomerModel` | `customers` | `customer_id`, `full_name`, `email_address` |
| `ScanResultModel` | `scan_results` | `chest_inches`, `waist_inches`, `recommended_size` |

## 🎨 Design System
- **Primary:** Violet `#7C3AED`
- **Background:** Slate-950 `#0F172A`
- **Surface:** Slate-900 `#1E293B`
- All colors defined in `AppColors` class in `main.dart`
