# CLAUDE.md — Matchaboy POS

Aplikasi kasir (POS) mobile untuk kedai **Matchaboy AAR**. Kasir mengarahkan
kamera ke *tray* berisi *cup* matcha, aplikasi mendeteksi varian & jumlahnya
dengan model YOLOv8 (on-device), menghitung total dari harga di basis data
lokal, lalu menyimpan transaksi. Semua berjalan **offline**.

Nama package/project: `matchaboy_pos`. Target utama: **Android**.

---

## Stack Teknologi

- **Flutter** (Dart), target Android (bisa lanjut ke iOS karena Flutter).
- **ultralytics_yolo** (^0.6.8) — inferensi model YOLOv8 di device (API
  `YOLOView`/`YOLOResult`).
- **camera** (^0.11) — live preview + ambil foto (mode Scan berbasis *capture*).
- **sqflite** (^2.4) + **path** (^1.9) — basis data SQLite lokal.
- **permission_handler** (^12) — izin kamera.
- **intl** (^0.20) — format tanggal & mata uang Rupiah.

Editor: VS Code / Android Studio. `minSdk = 26` (Android 8.0, sesuai NFR
kompatibilitas di Bab 3) — sudah diset di `android/app/build.gradle.kts`.

> **Build di Windows:** Flutter butuh dukungan *symlink* untuk plugin, jadi
> aktifkan **Developer Mode** (`start ms-settings:developers`) sebelum
> `flutter run`/`flutter build`, kalau tidak build akan gagal.

---

## Model Deteksi — JANGAN DIUBAH

- File: `assets/models/matcha.tflite` (format LiteRT/TFLite, NHWC,
  input `[1, 640, 640, 3]`, output `[1, 10, 8400]`, float32).
- Label tertanam di metadata, **6 kelas** (urutan indeks tetap):
  `0=choko, 1=og, 2=pistachio, 3=red_velvet, 4=taro, 5=vanilla`.
- Task: `detect`. Ambang keyakinan default: **0.5** (bisa diatur user).
- Jangan mengubah, mengganti nama, atau me-*re-export* file `.tflite` ini.
- Hanya 6 varian ini yang dapat dideteksi. Varian lain (Sereal, Cookies,
  Biscoff) BELUM ada di model — jangan berasumsi bisa terdeteksi.

Pemetaan label model → nama tampilan (dan `product_code` di DB):

| Label model | Nama tampilan | product_code |
|---|---|---|
| og | Original | og |
| vanilla | Vanilla | vanilla |
| choko | Choco | choko |
| taro | Taro | taro |
| pistachio | Pistachio | pistachio |
| red_velvet | Red Velvet | red_velvet |

**Aturan kunci:** hubungkan hasil deteksi ke produk lewat `product_code`
yang nilainya sama persis dengan label kelas model (huruf kecil).

---

## Basis Data (SQLite)

Tiga tabel berelasi. `transactions` 1—* `transaction_items` *—1 `products`.

### products
| Kolom | Tipe | Constraint |
|---|---|---|
| product_id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| product_name | TEXT | NOT NULL, UNIQUE |
| product_code | TEXT | NOT NULL, UNIQUE (= label kelas model) |
| price | INTEGER | NOT NULL (Rupiah) |
| description | TEXT | NULLABLE |
| is_active | INTEGER | NOT NULL, DEFAULT 1 |
| created_at | DATETIME | NOT NULL |
| updated_at | DATETIME | NOT NULL |

### transactions
| Kolom | Tipe | Constraint |
|---|---|---|
| transaction_id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| transaction_code | TEXT | NOT NULL, UNIQUE (mis. TRX-20260101-001) |
| transaction_date | DATETIME | NOT NULL |
| total_items | INTEGER | NOT NULL |
| total_amount | INTEGER | NOT NULL (Rupiah) |
| payment_status | TEXT | NOT NULL, DEFAULT 'completed' |
| notes | TEXT | NULLABLE |
| created_at | DATETIME | NOT NULL |

### transaction_items
| Kolom | Tipe | Constraint |
|---|---|---|
| item_id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| transaction_id | INTEGER | NOT NULL, FOREIGN KEY → transactions |
| product_id | INTEGER | NOT NULL, FOREIGN KEY → products |
| quantity | INTEGER | NOT NULL |
| unit_price | INTEGER | NOT NULL (harga saat transaksi) |
| subtotal | INTEGER | NOT NULL (quantity × unit_price) |
| confidence_score | REAL | NULLABLE (keyakinan deteksi, untuk audit) |

`unit_price` disimpan di `transaction_items` agar transaksi lama tetap
konsisten walau harga produk berubah. `confidence_score` menyimpan
keyakinan deteksi tiap item.

Kolom bertipe `DATETIME` disimpan sebagai string **ISO8601** (SQLite tidak
punya tipe tanggal asli). Format ini terurut sama dengan urutan waktu,
sehingga bisa dipakai langsung untuk `ORDER BY` dan filter rentang tanggal.

### Seed data produk (harga PLACEHOLDER — ganti dengan harga asli kedai)
| product_name | product_code | price |
|---|---|---|
| Original | og | 18000 |
| Vanilla | vanilla | 20000 |
| Choco | choko | 20000 |
| Taro | taro | 20000 |
| Pistachio | pistachio | 22000 |
| Red Velvet | red_velvet | 22000 |

---

## Halaman & Alur (8 halaman utama + Tentang)

Setelah splash singkat (model dimuat di *background*), langsung ke Dashboard.

**Alur utama kasir (maksimal 4 langkah, NFR-02):**
`Dashboard → Scan → Hasil Deteksi → Konfirmasi → Transaksi Sukses`

1. **Dashboard** — pusat navigasi. *Header* logo Matchaboy + sapaan.
   Ringkasan harian: jumlah transaksi hari ini & total pendapatan harian.
   Empat tombol: **Scan (paling besar/menonjol)**, Riwayat Transaksi,
   Manajemen Produk, Tentang Aplikasi.

2. **Scan (Mode Kasir)** — *live camera preview* (`YOLOView`) dengan deteksi
   **real-time**: kotak + label digambar langsung di atas preview tiap frame
   begitu ada cup matcha terlihat (bukan menunggu jepret). Deteksi live juga
   meng-*gate* tombol jepret. Kotak *viewfinder* di tengah, tombol bantuan
   (kanan atas) & kembali (kiri atas). Ambang keyakinan tetap 0.5 (tidak
   diatur user). Tombol *capture* besar **hanya aktif saat ada cup
   terdeteksi**; menekannya membekukan frame → Hasil Deteksi (kotak deteksi
   digambar ulang di sana). Tak ada cup → tombol nonaktif.

3. **Hasil Deteksi** — snapshot frame dengan bounding box + label per varian
   (digambar overlay aplikasi, warna per varian agar selalu terbaca) di atas.
   Di bawahnya daftar varian sebagai *card* (nama, jumlah, harga satuan,
   subtotal). Total transaksi di bagian bawah + tombol **"Ulangi"** dan
   **"Lanjutkan"**.

4. **Konfirmasi Transaksi** — verifikasi akhir. Ringkasan varian, jumlah,
   total, waktu. User bisa **menyesuaikan manual** (tambah/kurang/hapus
   item) bila deteksi keliru — "Tambah item" ada di AppBar. Tombol **"Simpan"**
   dan **"Batalkan"**.

5. **Transaksi Sukses** — ikon centang hijau, pesan sukses, kode transaksi,
   total. Tombol **"Transaksi Baru"** (→ Scan) dan **"Kembali ke Beranda"**.

6. **Riwayat Transaksi** — daftar semua transaksi (terbaru di atas), tiap
   item: kode, tanggal-waktu, jumlah item, total. *Filter* tanggal di atas.
   Tap item → Detail Transaksi.

7. **Detail Transaksi** — rincian satu transaksi: kode, tanggal-waktu,
   daftar varian + jumlah + subtotal, total keseluruhan. Tombol kembali.

8. **Manajemen Produk** — daftar 6 produk sebagai *card* (nama, kode, harga)
   + tombol edit tiap card. Fokus pada 6 varian: tanpa toggle aktif & tanpa
   tombol tambah produk. Form Edit Produk.

**Tentang Aplikasi** — info aplikasi, versi, deskripsi, kredit pengembang.

---

## Alur Deteksi (teknis)

Mode Scan menjalankan deteksi **real-time** via `YOLOView`: kotak digambar
langsung di preview tiap frame, dan deteksi live juga meng-*gate* tombol
jepret. Saat dijepret, frame + deteksi terakhir diteruskan ke Hasil Deteksi.

1. `YOLOView` (`ultralytics_yolo`) menampilkan preview + menjalankan YOLOv8
   tiap frame → callback `onStreamingData` memberi daftar deteksi (className +
   confidence + bounding box) beserta `imageWidth`/`imageHeight`, disaring
   dengan ambang tetap 0.5. Overlay bawaan plugin **dimatikan**
   (`setShowOverlays(false)`); sebagai gantinya aplikasi menggambar kotak
   sendiri lewat `DetectionOverlay` (`BoxFit.cover`) agar warna & label per
   varian selalu terbaca. Deteksi live ini sekaligus mengaktifkan tombol jepret.
2. Tombol *capture* aktif hanya bila ada deteksi. Saat ditekan: ambil
   snapshot frame mentah (`capturePhoto(withOverlays: false)`) + daftar deteksi
   terakhir; overlay kotak digambar di Hasil Deteksi.
3. **Agregasi** (`DetectionService.buildResult`): hitung jumlah *cup* per
   `className` (varian).
4. **Lookup harga**: untuk tiap varian, ambil `price` dari tabel `products`
   via `product_code == className` (`getProductByCode`).
5. Hitung subtotal per varian & total keseluruhan → tampilkan di Hasil
   Deteksi; `DetectionOverlay` menggambar kotak + label di atas snapshot.
6. Simpan `confidence_score` (rata-rata per varian) untuk audit.

Inferensi live harus lancar & responsif (NFR-01).

---

## Kebutuhan Fungsional (acuan fitur)

FR-01 akses kamera & ambil citra · FR-02 deteksi cup (YOLOv8 on-device) ·
FR-03 klasifikasi varian · FR-04 hitung jumlah per varian · FR-05 lookup
harga dari DB · FR-06 kalkulasi total · FR-07 verifikasi & konfirmasi
transaksi · FR-08 simpan transaksi ke DB · FR-09 riwayat transaksi ·
FR-10 manajemen produk (CRUD).

## Kebutuhan Non-Fungsional (batasan)

- **Offline penuh** (NFR-05): deteksi & kalkulasi tanpa internet.
- **Performa** (NFR-01): < 3 detik per deteksi.
- **Usability** (NFR-02): alur transaksi ≤ 4 langkah, sederhana.
- **Reliability** (NFR-03): tidak boleh *crash* saat operasional.
- **Kompatibilitas** (NFR-06): Android 8.0+ (API 26+), RAM 4 GB.
- **Keamanan** (NFR-08): data tersimpan di penyimpanan privat aplikasi.
- **Maintainability** (NFR-09): kode modular & terdokumentasi.

---

## Struktur Kode (disarankan)

```
lib/
  main.dart                 # tema hijau matcha + init locale id + SplashScreen
  models/
    product.dart            # Product
    transaction.dart        # Transaction
    transaction_item.dart   # TransactionItem (+ factory forProduct)
    detection.dart          # Detection (kotak ternormalisasi)
  services/
    database_service.dart   # SQLite: init, seed, CRUD, query
    detection_service.dart  # load model sekali + predict + agregasi + lookup
  screens/
    splash_screen.dart          # splash singkat → Dashboard
    dashboard_screen.dart
    scan_screen.dart            # deteksi live (YOLOView) + jepret ter-gate
    detection_result_screen.dart
    confirm_transaction_screen.dart
    transaction_success_screen.dart
    history_screen.dart
    transaction_detail_screen.dart
    product_management_screen.dart
    product_form_screen.dart    # form Tambah/Edit produk
    about_screen.dart
  widgets/
    matcha_cup_icon.dart        # ikon cup es matcha (dashboard/splash/tentang)
    detection_overlay.dart      # kotak + label deteksi (warna per varian)
  utils/
    formatters.dart             # Rupiah & tanggal lokal id
assets/
  models/matcha.tflite
```

---

## Gaya Visual

- Tema **hijau matcha** (mis. seed color hijau ~ `#6C8C3C`), Material 3.
- Bersih, kartu (*card*) dengan sudut membulat, ikon jelas, teks besar
  agar mudah dibaca saat operasional cepat.
- Tombol Scan paling menonjol di Dashboard.
- Format harga Rupiah (mis. "Rp 20.000") dan tanggal lokal Indonesia.

---

## Aturan Penting

**Lakukan:**
- Hubungkan deteksi → produk lewat `product_code` = label kelas model.
- Simpan `unit_price` di `transaction_items` (bukan hanya di `products`).
- Buat kode transaksi unik berformat `TRX-YYYYMMDD-NNN`.
- Muat model sekali & pakai ulang (jangan reload tiap deteksi).
- Tangani izin kamera dengan `permission_handler`.

**Jangan:**
- Jangan ubah/rename/re-export `matcha.tflite`.
- Jangan ubah urutan atau nama label kelas model.
- Jangan asumsikan varian Sereal/Cookies/Biscoff bisa dideteksi.
- Jangan butuhkan koneksi internet untuk fitur inti.
- Jangan pakai path project/SDK yang mengandung spasi.
