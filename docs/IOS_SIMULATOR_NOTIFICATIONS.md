# iOS Simulator Notifications

Local simulator-only APNs payload:

```bash
xcrun simctl push booted com.aliabdelnaser.amomy debug/ios/amomy_test_push.apns
```

This command is for local iOS Simulator notification UI and routing checks only.
It does not validate Firebase-to-APNs delivery, production APNs credentials, FCM
tokens, Supabase device-token sync, or physical-device delivery.

Keep `NotificationService.debugDisableIosPushStartup` enabled while this
temporary iOS push startup investigation is active.
