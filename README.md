# JELO Mobile App

Aplikasi mobile Flutter modern yang dilengkapi dengan fitur **Peta Interaktif (OpenStreetMap & OSRM Routing)**, **Pencarian Tempat Sekitar**, **Autentikasi Biometrik (Fingerprint / Face ID)**, **Penyimpanan Lokal (SQLite & Secure Storage)**, serta **Notifikasi Lokal**.

---

## Prasyarat (Prerequisites)

Sebelum mulai, pastikan perangkat kamu sudah terinstal:

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (versi `>= 3.11.5`)
- **[Dart SDK](https://dart.dev/get-dart)** (sudah termasuk dalam paket Flutter)
- **[Android Studio](https://developer.android.com/studio)** / **VS Code** (lengkap dengan ekstensi Flutter & Dart)
- Emulator Android / iOS atau HP Android/iOS langsung (dengan mode USB Debugging aktif)

---

## Cara Setup & Instalasi

Ikuti langkah-langkah simpel berikut untuk menjalankan project ini di komputer kamu:


### 1. Install Dependensi (Packages)
Jalankan perintah ini di terminal untuk mengunduh semua library/package yang dibutuhkan:
```bash
flutter pub get
```

### 2. Cek Perangkat Terhubung
Pastikan emulator atau HP kamu sudah terdeteksi:
```bash
flutter devices
```

### 3. Jalankan Aplikasi! 🎉
Jalankan aplikasi ke emulator atau HP yang terhubung:
```bash
flutter run
```

---

## Stack & Package Utama

| Kategori | Package / Technology |
| :--- | :--- |
| **Framework** | Flutter & Dart |
| **State Management** | `provider` |
| **Database & Cache** | `sqflite`, `shared_preferences`, `flutter_secure_storage` |
| **Map & Location** | `flutter_map`, `geolocator`, `latlong2` |
| **Autentikasi** | `local_auth` (Biometrik / Biometric Security) |
| **Notifikasi** | `flutter_local_notifications`, `timezone` |
| **UI & Icons** | `lucide_icons`, `flutter_svg` |

---

## Troubleshooting Ringkas

- **Mengalami issue package error saat `flutter run`?**
  Jalankan pembersihan cache terlebih dahulu:
  ```bash
  flutter clean
  flutter pub get
  ```

- **Izin Lokasi / Kamera / Biometrik tidak muncul di Android?**
  Pastikan kamu menyetujui (allow) pop-up permission saat aplikasi pertama kali dijalankan di perangkat.

---
