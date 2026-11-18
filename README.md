# TT1 Keyboard — iOS (No-Mac Installation Guide)

This package contains the full native iOS Swift/SwiftUI TT1 Keyboard project, with **automated cloud build** and **Windows-to-iPhone sideloading** support so you **never need a physical Mac or paid Apple Developer account**.

---

## 🚀 How to Install on iPhone (No Mac Required)

Apple requires all iPhone apps to be compiled into an `.ipa` file using macOS. Because Windows cannot compile iOS apps locally, we use a **free cloud Mac (GitHub Actions)** to generate your `.ipa` file in 2 minutes, then install it to your iPhone directly from your Windows PC using **Sideloadly**.

---

### Step 1: Generate the `.ipa` File in Cloud (2 Minutes, Free)

1. Go to [github.com](https://github.com) (create a free account if you don't have one).
2. Click **New Repository** (make it Public or Private, e.g. `tt1-keyboard-ios`).
3. Upload all files from this folder (`TT1-iOS`) into the repository.
   *(Make sure the `.github/workflows/build-ipa.yml` file is included).*
4. Click on the **Actions** tab at the top of your GitHub repository.
5. The **"Build iOS IPA (No-Mac Cloud Build)"** workflow will automatically run on a free Apple Mac in the cloud.
6. When it finishes (green checkmark, ~2 minutes), click on the completed run and download the **`TT1App-iOS`** artifact — this is your installable `TT1App.ipa` file!

---

### Step 2: Install the `.ipa` onto your iPhone from Windows

1. On your Windows PC, download and install **Sideloadly** (100% free):
   👉 [https://sideloadly.io](https://sideloadly.io)
2. Plug your iPhone into your Windows PC using a standard USB/Lightning cable.
3. Open **Sideloadly** on Windows:
   - Your iPhone will appear in the **iDevice** box.
   - Drag and drop your downloaded `TT1App.ipa` into Sideloadly.
   - In the **Apple ID** box, enter your regular free Apple ID (the personal iCloud email you already use on your iPhone).
   - Click **Start**.
4. Sideloadly will automatically sign the app and install TT1 Keyboard straight onto your iPhone!

---

### Step 3: Enable the Keyboard on iPhone

1. On your iPhone, go to:
   **Settings → General → VPN & Device Management**
   Tap your Apple ID and tap **Trust**.
2. Go to:
   **Settings → General → Keyboard → Keyboards → Add New Keyboard...**
3. Select **TT1 Keyboard**.
4. Open any app (TikTok, WhatsApp, Messages), tap a text box, tap the globe 🌐 icon to switch to **TT1 Keyboard**, and start typing!

---

## ⚡ Features Included

- **18-Mode Auto Last Digit Generator & Sender**:
  - Type 17 digits manually.
  - Automatically appends digits 1 through 9 sequentially.
  - Sequentially submits each number using native Send without Enter/newline.
  - Settle buffer between submissions to prevent spam blocks on TikTok/WhatsApp.
- **Floating Control Bar**:
  - Tap `[ 18 | Auto Gen ▾ ]` pill to expand.
  - Shows live status (`Idle`, `Armed (X/17)`, `Sending (N/9)...`, `Done`).
  - **Start** (Green), **Stop** (Red), and **✕** (Close).
- **Modes 4, 5, 6 & 18** with instant auto-send.
- **Slide Input**: Adjacent-key dragging with zero lag.
- **Comma/Dot toggle** for Mode 18.
- **Full QWERTY layout** with Shift and layout toggle (`🔁` / `Abc` / `123`).
