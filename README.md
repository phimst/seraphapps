# SeraphX — Setup Guide

**PENTING:** Flutter SDK **gak bisa** di-install langsung di Termux (bukan
package resmi, dan cara-cara komunitas rawan error). Jadi build APK-nya
dilakuin lewat **GitHub Actions** (server GitHub yang install Flutter &
build-in otomatis) — 100% gratis buat repo publik/privat pribadi, dan gak
butuh instalasi apapun di HP.

## Cara pakai

### 1. Bikin repo baru di GitHub
Buka github.com → New repository → kasih nama misal `seraphx` → biarin
kosong (jangan centang "Add README").

### 2. Push project ini ke repo (dari Termux)

```bash
pkg install git -y
cd ~/seraphx          # folder hasil extract ZIP ini
git init
git add .
git commit -m "Initial commit SeraphX"
git branch -M main
git remote add origin https://github.com/USERNAME/seraphx.git
git push -u origin main
```
Ganti `USERNAME` dengan username GitHub lu. Pas diminta login, pakai
Personal Access Token (bukan password akun) sebagai password —
generate di GitHub → Settings → Developer settings → Personal access
tokens, scope `repo`.

### 3. Trigger build

Setelah push, buka repo di GitHub → tab **Actions** → workflow
"Build APK" bakal otomatis jalan (atau klik "Run workflow" kalau mau
manual trigger). Tunggu ~5-10 menit.

### 4. Download APK

Kalau build sukses (centang hijau), klik run yang selesai → scroll ke
bagian **Artifacts** → download `seraphx-release-apk` → extract ZIP-nya
→ dapet `app-release.apk` → transfer/install ke HP.

### 5. Update fitur baru nanti

Tiap kali ada perubahan code (dari gue atau lu edit sendiri):
```bash
git add .
git commit -m "update fitur X"
git push
```
Actions bakal otomatis build ulang tiap push ke branch `main`. Gak perlu
install apapun tambahan.

## Catatan penting

- **Storage**: semua data (settings.json, hasil download TikTok) disimpen
  di folder khusus app: `Android/data/com.seraph.apps/files/seraphapps/`.
  Ini folder app-specific, jadi TIDAK BUTUH izin "All files access" manual
  lagi (yang sering gagal di HP Xiaomi/Redmi/MIUI) — otomatis kebaca/tulis
  tanpa popup permission apapun. Buat liat isinya manual, pakai file
  manager yang bisa browse folder `Android/data` (contoh: MT Manager,
  Solid Explorer), atau dari Termux: `termux-setup-storage` lalu buka
  `~/storage/shared/Android/data/com.seraph.apps/files/seraphapps/`.
- **AI Chat**: default provider Gemini. Ganti provider + isi API key di
  tab Settings dulu sebelum chat, kalau enggak bakal muncul pesan error
  "API Key belum diisi".
- **Custom REST API** (chat): asumsi format request `{"message": "..."}`
  dan response `{"response": "..."}`. Kalau API custom lu formatnya beda,
  edit bagian `_callCustomRest` di
  `lib/features/chat/ai_chat_service.dart`.
- **GitHub Push (fitur di dalam app)**: token butuh scope `repo`. Ini beda
  dari token yang lu pakai buat push manual di step 2 — boleh sama boleh
  beda token.
- **TikTok Downloader**: link `downloadUrl` dari API ada expiry token,
  jadi harus fetch ulang tiap kali download — sudah dihandle otomatis di
  code.
- **Kalau build di Actions gagal**: buka tab Actions → klik run yang
  merah → baca log error-nya, terus kirim ke gue biar gue perbaiki
  code-nya (bukan lu yang perlu ngoprek manual).
