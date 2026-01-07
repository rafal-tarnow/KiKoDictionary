import 'package:flutter/material.dart';
import 'widgets/server_monitor_tile.dart';
import '../../core/widgets/main_drawer.dart';

class ServicesHealthPage extends StatelessWidget {
  const ServicesHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      //backgroundColor: const Color(0xFFFFFFFF),

      body: SingleChildScrollView(
        // Odpowiednik ScrollablePage
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DEV SERVERS ---
            _buildSectionHeader("Dev servers"),
            const ServerMonitorTile(
              serviceName: "captcha-microservice",
              serverUrl: "http://127.0.0.1:8001",
            ),
            const ServerMonitorTile(
              serviceName: "users-microservice",
              serverUrl: "http://127.0.0.1:8002",
            ),
            const ServerMonitorTile(
              serviceName: "sentences-microservice",
              //serverUrl: "http://10.139.19.47:8003",
              serverUrl: "https://dev-sentences.rafal-kruszyna.org",
            ),

            const SizedBox(height: 24),

            // --- PRODUCTION ---
            _buildSectionHeader("Production"),
            const ServerMonitorTile(
              serviceName: "captcha-microservice",
              serverUrl:
                  "https://maia-captcha.rafal-kruszyna.org", // port 443 jest domyślny dla https
            ),
            const ServerMonitorTile(
              serviceName: "users-microservice",
              serverUrl: "https://maia-users.rafal-kruszyna.org",
            ),
            const ServerMonitorTile(
              serviceName: "sentences-microservice",
              serverUrl: "https://maia-sentences.rafal-kruszyna.org",
            ),

            const SizedBox(height: 24),

            // --- PRODUCTION LOCAL ---
            _buildSectionHeader("Production local"),
            const ServerMonitorTile(
              serviceName: "captcha-microservice",
              serverUrl: "http://192.168.0.102:8001",
            ),
            const ServerMonitorTile(
              serviceName: "users-microservice",
              serverUrl: "http://192.168.0.102:8002",
            ),
            const ServerMonitorTile(
              serviceName: "sentences-microservice",
              serverUrl: "http://192.168.0.102:8003",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18, // pointSize 15 w QML to mniej więcej 18-20 w Flutter
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
