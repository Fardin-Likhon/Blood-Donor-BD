import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

// Global Key for showing SnackBars across the entire application [cite: 142]
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- SAFETY FIX: PREVENT DUPLICATE INITIALIZATION ---
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase Initialized Successfully");
    }
  } catch (e) {
    debugPrint("⚠️ Firebase initialization check: $e");
  }

  runApp(const BloodDonorApp());
}

class BloodDonorApp extends StatefulWidget {
  const BloodDonorApp({super.key});

  @override
  State<BloodDonorApp> createState() => _BloodDonorAppState();
}

class _BloodDonorAppState extends State<BloodDonorApp> {
  // Subscriptions to avoid memory leaks during testing on Samsung A33
  StreamSubscription<QuerySnapshot>? _emergencySub;
  StreamSubscription<QuerySnapshot>? _preBookingSub;

  @override
  void initState() {
    super.initState();

    // Monitor Auth state to start/stop listeners
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _startTargetedListeners(user.uid);
      } else {
        _cancelSubscriptions();
      }
    }, onError: (error) => debugPrint("❌ Auth State Error: $error"));
  }

  void _cancelSubscriptions() {
    _emergencySub?.cancel();
    _preBookingSub?.cancel();
    _emergencySub = null;
    _preBookingSub = null;
  }

  void _startTargetedListeners(String uid) async {
    try {
      // 1. Fetch current donor's profile [cite: 52]
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('donor')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        debugPrint(
          "ℹ️ Profile missing. Redirecting to registration is required.",
        );
        return;
      }

      String myBloodGroup = userDoc['bloodGroup'] ?? "";
      String myCity = userDoc['city'] ?? "";

      if (myBloodGroup.isEmpty || myCity.isEmpty) return;

      debugPrint("🩸 Listening for $myBloodGroup in $myCity...");

      _cancelSubscriptions();

      // --- 2. EMERGENCY ALERT LISTENER  ---
      _emergencySub = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('bloodGroup', isEqualTo: myBloodGroup)
          .where('city', isEqualTo: myCity)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 10)),
            ),
          )
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                var data = change.doc.data() as Map<String, dynamic>;
                _showGlobalAlert(
                  "URGENT: ${data['bloodGroup']} NEEDED",
                  data['hospitalName'] ?? "Local Hospital",
                  Colors.red.shade900,
                );
              }
            }
          });

      // --- 3. PRE-BOOKING ALERT LISTENER  ---
      _preBookingSub = FirebaseFirestore.instance
          .collection('pre_bookings')
          .where('bloodGroup', isEqualTo: myBloodGroup)
          .where('city', isEqualTo: myCity)
          .where('status', isEqualTo: 'Active')
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                var data = change.doc.data() as Map<String, dynamic>;
                _showGlobalAlert(
                  "SCHEDULED: ${data['bloodGroup']} SUPPORT",
                  "at ${data['hospitalName']}",
                  Colors.blue.shade900,
                );
              }
            }
          });
    } catch (e) {
      debugPrint("❌ Failed to start targeted listeners: $e");
    }
  }

  void _showGlobalAlert(String title, String hospital, Color bgColor) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emergency_share,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Location: $hospital", style: const TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: "DETAILS",
          textColor: Colors.yellowAccent,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Blood Donor BD',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
