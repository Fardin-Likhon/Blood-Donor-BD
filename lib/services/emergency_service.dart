import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  // Logic to trigger the phone dialer
  Future<void> makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print("Could not launch $phoneNumber");
      }
    } catch (e) {
      print("Error launching dialer: $e");
    }
  }
}
