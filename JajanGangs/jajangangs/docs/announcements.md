# Manual announcement notifications (Spark)

Topic: `jajan_announcements` (without backticks or quotation marks).

Android and iOS members are subscribed after verified sign-in and profile completion, when the home map appears. Existing members are subscribed when they next open this updated app. The English/Indonesian explanation precedes the OS notification permission request, once per installation. Declining does not block the app. Users can enable notifications later in device settings; the app retries on resume. Subscription failures are retried and logged as `[Announcements]`, without blocking sign-in. Token refresh also triggers subscription reconciliation.

Sign-out requests unsubscription. Offline unsubscription may be delayed until connectivity returns, so the topic must only contain public announcements, never personal or private event information. FCM subscriptions belong to installations, not Firestore users. There is no backend job to subscribe users who have not opened the updated app.

## Send from Firebase Console

1. Rebuild and install the updated native app. Sign in, complete the profile, and allow notifications. The console log should say `[Announcements] Subscribed: jajan_announcements`.
2. Open the Firebase project, then Messaging (under Engage / Run, depending on Console layout).
3. Create a Firebase notification campaign. Enter the notification title and body.
4. Choose **Topic** as the target and enter `jajan_announcements`. The topic picker may take time to show a newly subscribed topic.
5. Choose the schedule and publish/send. Enable sound in the campaign's additional options if wanted. Android's default channel is `jajan_announcements`, configured with high importance; users control its final sound/banner settings.

Use a notification campaign, not a data-only payload. The SDK/OS displays background notification messages without a Dart background handler. Tapping opens the app's normal authentication/home flow. In the foreground, the app displays the title/body in a dismissible banner and uses the existing in-app chime preference. Announcements are not stored in the Firestore notification inbox. The in-app sound toggle does not change OS notification sound settings.

The single topic sends the same Console-authored text to everyone; enter bilingual announcement copy if you want both languages. App-owned permission/channel text is localized. Web preview is intentionally excluded.

## iOS setup required outside this repository

The project contains the Push Notifications entitlement and background notification modes. On a Mac, ensure the Runner signing team and provisioning profile support Push Notifications. Xcode sets the appropriate APNs environment when signing/exporting for distribution.

In Apple Developer, create an APNs authentication key. Upload its `.p8` file, key ID and team ID in Firebase **Project settings → Cloud Messaging → Apple app configuration**. Keep the private key out of the repository. Apple signing/developer requirements are separate from Firebase Spark. Without valid signing/APNs configuration, iOS cannot receive these announcements.

No Blaze, Cloud Functions, Firestore rules, indexes, or token collection is needed. Automatic chat/join push notifications remain deferred. Native dependency/config changes require a fresh build; hot reload is insufficient. Tests, analyzer, builds and device runs were not performed, per the project instructions.

References: https://firebase.google.com/docs/cloud-messaging/flutter/get-started and https://firebase.google.com/docs/cloud-messaging/topic-messaging
