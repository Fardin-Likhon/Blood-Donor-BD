import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import 'nearby_service_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EmergencyService _emergency = EmergencyService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Services"),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. NATIONAL HELPLINE (Always shows, uses no data)
            _build999Card(_emergency),

            const SizedBox(height: 30),
            const Text(
              "Nearby Facilities (GPS Required)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // 2. GPS SERVICE GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _serviceCard(
                    context,
                    "Hospitals",
                    Icons.local_hospital,
                    Colors.blue,
                    const NearbyServiceScreen(serviceType: "hospitals"),
                  ),
                  _serviceCard(
                    context,
                    "Ambulances",
                    Icons.airport_shuttle,
                    Colors.orange,
                    const NearbyServiceScreen(serviceType: "ambulances"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build999Card(EmergencyService service) {
    return InkWell(
      onTap: () => service.makeCall("999"),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_in_talk, color: Colors.white, size: 45),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CALL 999",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "National Emergency Line",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
