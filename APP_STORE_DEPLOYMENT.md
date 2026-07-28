# iOS App Store Deployment Guide

This document tracks the configuration, secrets, and procedures required to successfully deploy the Cinema Eats (Love Cafe) iOS customer app to TestFlight and the App Store.

## 1. Automated GitHub Actions Pipeline

We have configured a fully automated CI/CD pipeline (`.github/workflows/deploy_ios.yml`) that triggers automatically whenever code is pushed to the `main` branch.

### 1.1 GitHub Secrets Required
For the pipeline to authenticate with Apple and sign the code, the following secrets must be present in the GitHub repository settings:

*   **App Environment:**
    *   `SUPABASE_URL`: Your Supabase database URL.
    *   `SUPABASE_ANON_KEY`: Your Supabase anonymous key.
*   **Apple Code Signing:**
    *   `BUILD_CERTIFICATE_BASE64`: A Base64 encoded string of your Apple Distribution Certificate (`.p12` file generated with the `-legacy` flag for macOS compatibility).
    *   `P12_PASSWORD`: The export password you created when generating the `.p12` file.
    *   `BUILD_PROVISION_PROFILE_BASE64`: A Base64 encoded string of your App Store Connect Provisioning Profile (`.mobileprovision`).
    *   `KEYCHAIN_PASSWORD`: A random password used to secure the temporary CI/CD keychain (e.g., `GitHub123!`).
*   **App Store Connect API:**
    *   `APP_STORE_CONNECT_ISSUER_ID`: The Issuer ID (UUID format) from App Store Connect -> Users and Access -> Integrations.
    *   `APP_STORE_CONNECT_KEY_ID`: The Key ID (e.g., `D383SF739`).
    *   `APP_STORE_CONNECT_PRIVATE_KEY`: The actual private key contents from the `.p8` file downloaded from Apple.

### 1.2 Pipeline Architecture Highlights
To bypass common strict Xcode and CocoaPods code-signing errors, the pipeline uses several advanced techniques:
*   **Latest Xcode Enforcement:** Forces the runner to use the latest Xcode version (`latest-stable`) to satisfy Apple's strict minimum SDK requirements (e.g., iOS 26 SDK).
*   **CocoaPods Signing Disabled:** A `post_install` hook in `ios/Podfile` forcefully disables code signing for all 3rd party plugins (like Firebase and Google Sign-In) so Xcode doesn't attempt to sign them with the App Store profile.
*   **Dynamic Identity Extraction:** Instead of hardcoding the Apple `DEVELOPMENT_TEAM`, the pipeline dynamically reads the `.mobileprovision` file, extracts the exact Team ID and UUID, and seamlessly passes them into Xcode to guarantee a 100% match.
*   **Dynamic IPA Resolution:** The pipeline searches the output directory to find the exact name of the compiled `.ipa` file before passing it to the TestFlight upload script, preventing wildcard errors.

## 2. TestFlight Testing Workflow

Once the GitHub Action completes successfully, the `.ipa` is uploaded to Apple's servers.

### Step 1: Processing
*   Go to App Store Connect -> TestFlight -> iOS Builds.
*   The newly uploaded build will say **Processing**. Apple scans the app for malware. This usually takes 10 to 30 minutes.

### Step 2: Export Compliance
*   Once processing finishes, a yellow **"Missing Compliance"** warning will appear.
*   Click **Manage**.
*   Because the app only uses standard HTTPS network requests to Supabase (which relies on Apple's OS-level encryption), select the final option: **"None of the algorithms mentioned above"** and click Save.

### Step 3: Distributing to Testers
*   **Internal Testing:** (Immediate) Click the `+` next to Internal Testing. You can only add users who are officially invited to your Apple Developer Account under "Users and Access". Once added, the app is instantly available on their phone.
*   **External Testing:** (Requires 1-Day Review) Click the `+` next to External Testing. You can type any email address or generate a Public URL to share on WhatsApp. The first time you do this, Apple requires a quick ~24-hour "Beta App Review". Once approved, anyone with the link can download the app via TestFlight.

---
*Note: If your Apple Distribution Certificate expires (usually valid for 1 year), you will need to generate a new `.p12` file and `.mobileprovision` profile and update the Base64 secrets in GitHub.*
