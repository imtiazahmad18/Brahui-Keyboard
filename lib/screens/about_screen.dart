import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Brahui Keyboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/brahui_keyboard_logo.png',
                    width: 168,
                    height: 168,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Brahui Keyboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Version 1.0.0 (Build 1)',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Privacy Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Brahui Keyboard is designed with strict offline-first privacy. It does NOT request internet permissions on Android, does NOT collect keystrokes, and never transmits your passwords, messages, or clipboard data to any external server.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Unicode Preservation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code, color: Color(0xFF5CB4E8)),
                      const SizedBox(width: 8),
                      Text(
                        'Unicode Standards Compliance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The Brahui letter "ڷ" is mapped strictly to Unicode code point U+06B7 (Arabic Letter Lam with Three Dots Above). All 39 characters in the Brahui script and standard Arabic/Urdu combining marks are fully supported.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Open Source
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Open Source & Community',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Dedicated to the preservation and digital empowerment of the Brahui language. Released under the Apache 2.0 License.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
