import 'dart:async'; // <--- THIS WAS THE MISSING PIECE
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

// Global Key for showing SnackBars from anywhere in the app
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

  runApp(const BloodDonetorApp());
}

class BloodDonetorApp extends StatefulWidget {
  const BloodDonetorApp({super.key});

  @override
  State<BloodDonetorApp> createState() => _BloodDonetorAppState();
}

class _BloodDonetorAppState extends State<BloodDonetorApp> {
  // To keep track of the Firestore stream to avoid memory leaks
  StreamSubscription<QuerySnapshot>? _requestSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen for Auth changes with error handling
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        try {
          _startGlobalNotificationListener(user.uid);
        } catch (e) {
          debugPrint("❌ Error starting listener: $e");
        }
      } else {
        _requestSubscription?.cancel();
        _requestSubscription = null;
      }
    }, onError: (error) {
      debugPrint("❌ Auth State Error: $error");
    });
  }

  void _startGlobalNotificationListener(String uid) async {
    try {
      // 1. Get the current user's blood group from 'donor' collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('donor')
          .doc(uid)
          .get();
          
      if (!userDoc.exists) {
        debugPrint("ℹ️ No donor profile found for current user.");
        return;
      }

      String myBloodGroup = userDoc['bloodGroup'] ?? "";
      if (myBloodGroup.isEmpty) return;

      debugPrint("🩸 Listening for $myBloodGroup requests...");

      // 2. Watch for new requests matching that blood group
      await _requestSubscription?.cancel();

      _requestSubscription = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('bloodGroup', isEqualTo: myBloodGroup)
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

                // 3. Extract and format the time
                DateTime requestTime =
                    (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                String formattedTime =
                    "${requestTime.hour.toString().padLeft(2, '0')}:${requestTime.minute.toString().padLeft(2, '0')}";

                // 4. Show the emergency alert
                _showGlobalAlert(
                  data['bloodGroup'] ?? "UNKNOWN",
                  data['hospitalName'] ?? "Unknown Hospital",
                  formattedTime,
                );
              }
            }
          }, onError: (e) {
            debugPrint("❌ Firestore Stream Error: $e");
          });
    } catch (e) {
      debugPrint("❌ Failed to start notification listener: $e");
    }
  }

  void _showGlobalAlert(String group, String hospital, String time) {
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
                  "URGENT: $group NEEDED",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Location: $hospital", style: const TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 20),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: "HELP NOW",
          textColor: Colors.yellowAccent,
          onPressed: () {
            debugPrint("Navigating to help request...");
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Blood Donor BD',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}