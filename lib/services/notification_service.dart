import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 1. Initialize and get permission
  Future<void> initNotifications() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }
  }

  // 2. Subscribe donor to their specific blood group topic
  // We replace '+' with '_plus' and '-' with '_minus' because topics can't have '+'
  Future<void> subscribeToBloodGroup(String bloodGroup) async {
    String topic = bloodGroup
        .replaceAll('+', '_plus')
        .replaceAll('-', '_minus');
    await _fcm.subscribeToTopic(topic);
    debugPrint("Subscribed to topic: $topic");
  }

  // 3. Unsubscribe (use this during logout)
  Future<void> unsubscribeFromBloodGroup(String bloodGroup) async {
    String topic = bloodGroup
        .replaceAll('+', '_plus')
        .replaceAll('-', '_minus');
    await _fcm.unsubscribeFromTopic(topic);
  }
}
