# Google Play Store Deployment Guide

This document tracks the deployment and testing progress for the Android version of the Cinema Eats (Love Cafe) app on the Google Play Console.

## Current Status: Closed Testing Phase
**Progress:** The Android App Bundle (`.aab`) has been successfully generated and manually uploaded to the Google Play Console under the **Closed testing - Alpha** track (Release 1.0.2).

## Google Play Testing Requirements (14-Day Rule)
Because this is a new personal Google Play Developer account, Google enforces a strict testing policy before the app can be published to the public Play Store (Production).

### The Requirements:
1. **12 Opted-in Testers:** You must invite exactly 12 (or more) people with Android devices to test the app.
2. **14 Days of Continuous Testing:** Those 12 people must download the app and keep it installed on their physical Android devices for **14 consecutive days**.

### Tester Enrollment Checklist:
- [ ] Gather 12 Gmail addresses from friends, family, or colleagues who own Android devices.
- [ ] Go to Google Play Console -> **Test and release** -> **Closed testing**.
- [ ] Click **Manage track** on the Alpha track.
- [ ] Go to the **Testers** tab and add the 12 emails to the "Tester List".
- [ ] Save the changes.
- [ ] Scroll down to "How testers join your test" and copy the **"Join on Android"** link.
- [ ] Send this link to the 12 testers.
- [ ] Ensure all 12 testers actually click the link, accept the invite, and download the app. (Google tracks this active installation data to prevent fraud).

## Next Steps (After 14 Days)
Once the 14-day timer finishes (and assuming all 12 testers kept the app installed), the Google Play Console dashboard will automatically unlock the **Apply for Production** button.

At that point, you will:
1. Fill out a short questionnaire from Google about how you ran your closed test.
2. Submit the app for final Production review.
3. Once approved, the app will be live on the Google Play Store!
