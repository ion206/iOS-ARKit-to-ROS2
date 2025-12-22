---

## 📘 Guide: Deploying Your iOS App to a Personal Device

**Author:** Ayan Syed

**Topic:** Free Personal Deployment via Xcode

---

### 1. Prerequisites

Before starting, ensure you have the following:

* **A Mac** running a recent version of macOS.
* **Xcode** installed (available for free on the Mac App Store).
* **An Apple ID** (your standard iCloud login).
* **A USB-to-Lightning or USB-C cable** (though wireless deployment is possible after the first sync).

---

### 2. Step 1: Add your Apple ID to Xcode

Xcode needs to "sign" your app to prove it is safe to run on your device.

1. Open **Xcode**.
2. In the menu bar, go to **Xcode > Settings** (or `Cmd + ,`).
3. Click the **Accounts** tab.
4. Click the **+ (plus)** icon in the bottom left and select **Apple ID**.
5. Sign in with your Apple credentials.

---

### 3. Step 2: Configure "Signing & Capabilities"

Every iOS app requires a "Team" and a "Bundle Identifier" to be deployed.

1. Open your project in Xcode.
2. In the **Project Navigator** (left sidebar), click on the blue project icon at the top.
3. Select your app under the **Targets** list.
4. Click the **Signing & Capabilities** tab at the top.
5. Check **Automatically manage signing**.
6. In the **Team** dropdown, select your name (e.g., `"Your Name (Personal Team)"`).

---

### 4. Step 3: Prepare the iPhone (Developer Mode)

With iOS 16 and later, you must manually enable "Developer Mode" on the phone itself for security.

1. On your iPhone, go to **Settings > Privacy & Security**.
2. Scroll to the bottom and tap **Developer Mode**.
3. Toggle the switch **On**.
4. Your phone will prompt you to **Restart**. After restarting, tap **Turn On** and enter your passcode.

---

### 5. Step 4: Physical Connection and Deployment

1. Connect your iPhone to your Mac via cable.
2. If prompted on the phone, tap **Trust This Computer**.
3. In the top toolbar of Xcode, click the **Device Selector** (next to the Play button) and choose your physical iPhone from the list.
4. Press the **Run (Play button)** or `Cmd + R`.

---

### 6. Step 5: Trust the Developer Profile

The first time you deploy, the app will install but refuse to open, showing an "Untrusted Developer" error.

1. On your iPhone, go to **Settings > General**.
2. Tap **VPN & Device Management** (or **Profiles & Device Management**).
3. Under "Developer App," tap on your **Apple ID**.
4. Tap **Trust [Your Apple ID]** and confirm.

---

### 💡 Important Limitations of the Free Tier

* **7-Day Expiration:** Apps installed with a free account expire after **7 days**. After this, the app will crash on launch. To fix it, simply plug your phone back into your Mac and hit **Run** in Xcode again.
* **3-App Limit:** You can only have **3** self-developed apps installed on your device at one time using a free account.
* **No Push Notifications/iCloud:** Advanced features like Push Notifications and certain iCloud containers require the paid $99/year program.

---

### 🚀 Troubleshooting

* **"Preparing System for Development":** Xcode may take 5–10 minutes the first time it sees your phone to download support files. Look at the status bar at the top of Xcode.
* **"Communication Error":** Ensure your Mac and iPhone are on the same Wi-Fi network and that the cable is high-quality.

