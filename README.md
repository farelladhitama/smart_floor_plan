# SmartFloorPlan

SmartFloorPlan adalah aplikasi mobile berbasis Flutter yang membantu pengguna membuat rancangan awal denah rumah 2D berdasarkan ukuran lahan dan kebutuhan ruangan. Aplikasi ini memiliki fitur generate denah, edit layout ruangan, estimasi RAB sederhana, serta scan sketsa denah menggunakan Computer Vision/OpenCV.

Project ini dibuat untuk kebutuhan Capstone Project dengan fokus utama pada implementasi aplikasi mobile, web service, keamanan API, pengujian perangkat lunak, dan penerapan Computer Vision sederhana.

---

## Deskripsi Aplikasi

SmartFloorPlan dibuat untuk membantu pengguna yang ingin mendapatkan gambaran awal rancangan rumah tanpa harus memiliki kemampuan desain arsitektur. Pengguna dapat mengisi data seperti lebar lahan, panjang lahan, jumlah kamar, material dinding, dan ruang tambahan. Sistem kemudian menampilkan hasil denah rumah 2D dalam bentuk layout sederhana.

Selain generate denah dari input form, aplikasi juga memiliki fitur Scan Sketsa Denah. Fitur ini memungkinkan pengguna memilih gambar sketsa denah, kemudian backend memproses gambar menggunakan OpenCV untuk mendeteksi area ruangan. Hasil deteksi ditampilkan kembali di aplikasi dalam bentuk data ruangan dan dapat dibuka sebagai denah digital sederhana.

---

## Fitur Utama

- Splash Screen responsif tanpa video
- Onboarding aplikasi
- Login manual
- Register manual
- Dashboard utama
- Generate Denah Rumah
- Preview Hasil Denah 2D
- Edit Denah dengan drag dan resize ruangan
- Estimasi RAB sederhana
- Scan Sketsa Denah menggunakan OpenCV
- Riwayat Desain dengan data demo
- Profil pengguna demo
- Logout

---

## Status Fitur Saat Ini

| Fitur | Status | Keterangan |
|---|---|---|
| Splash Screen | Tersedia | Sudah dibuat responsif dan pas dengan mobile |
| Onboarding | Tersedia | Menampilkan pengenalan aplikasi |
| Login Manual | Tersedia | Digunakan sebagai alur utama autentikasi demo |
| Register Manual | Tersedia | Digunakan untuk membuat akun manual |
| Google Login | UI tersedia | Belum menjadi alur utama demo Android karena masih membutuhkan konfigurasi Firebase, SHA fingerprint, Web Client ID, dan serverClientId |
| Dashboard | Tersedia | Menampilkan menu Generate Denah dan Scan Sketsa |
| Generate Denah | Tersedia | Membuat denah 2D berdasarkan input pengguna |
| Hasil Denah | Tersedia | Menampilkan preview denah, ukuran, jumlah ruang, dan tombol aksi |
| Edit Denah | Tersedia | Pengguna dapat drag dan resize ruangan |
| Simpan Hasil Edit | Tersedia | Hasil edit dapat mengubah tampilan denah sementara |
| RAB | Tersedia | Menampilkan estimasi biaya sederhana untuk demo |
| Simpan RAB | Belum tersedia | Belum menjadi fungsi aktif pada versi demo |
| Scan Sketsa | Tersedia | Menggunakan backend Flask dan OpenCV |
| Riwayat Desain | Tersedia sebagai demo | Menampilkan data dummy, belum menyimpan data riwayat aktif dari backend |
| Profil | Tersedia | Menampilkan informasi user demo dan tombol Logout |

---

## Teknologi yang Digunakan

- Flutter
- Dart
- GetX Pattern
- Flask
- SQLite
- OpenCV
- JWT Authentication
- ADB Reverse untuk demo aplikasi di HP
- Postman untuk pengujian API

---

## Struktur Project

```text
smart_floor_plan/
├── android/
├── assets/
│   ├── images/
│   └── videos/
├── backend_smartfloorplan/
│   ├── app.py
│   ├── smartfloorplan.db
│   └── venv/
├── lib/
│   ├── app/
│   │   ├── modules/
│   │   │   ├── splash/
│   │   │   ├── onboarding/
│   │   │   ├── login/
│   │   │   ├── dashboard/
│   │   │   ├── generate_form/
│   │   │   ├── hasil_denah/
│   │   │   ├── edit_denah/
│   │   │   ├── rab/
│   │   │   ├── scan_denah/
│   │   │   ├── riwayat/
│   │   │   └── profile/
│   │   └── routes/
│   ├── models/
│   ├── services/
│   ├── widgets/
│   ├── firebase_options.dart
│   └── main.dart
├── pubspec.yaml
└── README.md


Arsitektur Aplikasi

Aplikasi menggunakan pendekatan modular berbasis GetX Pattern. Setiap fitur utama dipisahkan ke dalam folder module agar struktur project lebih rapi dan mudah dikembangkan.

Struktur umum setiap module:    

module_name/
├── bindings/  → mengatur dependency injection GetX
├── controllers/  → mengatur logic, state, dan aksi pengguna
└── views/ → mengatur tampilan halaman


Folder Widgets
Project memiliki folder widgets untuk menyimpan komponen UI reusable.

lib/widgets/
├── app_card.dart  → komponen card reusable
├── custom_button.dart  → komponen tombol reusable
└── empty_state_widget.dart  → komponen tampilan data kosong
