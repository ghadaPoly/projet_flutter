// home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobmatch_ai/pages/matches_pages.dart';

import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'upload_cv_page.dart';
import 'mes_cvs_page.dart';      // ← Import ajouté
import 'jobs_page.dart';         // ← Import ajouté

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("JobMatch AI"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authNotifier.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "JobMatch AI",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Text(
                    currentUser?.email ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text("Uploader mon CV"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadCvPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text("Mes CVs"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MesCvsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text("Voir les Offres"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobsPage()),
                );
              },
            ),
            ListTile(
  leading: const Icon(Icons.psychology),
  title: const Text("Matches IA"),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchesPage()),
    );
  },
),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 120, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              "Bienvenue ${currentUser?.name ?? 'Utilisateur'}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(currentUser?.email ?? ''),
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadCvPage()),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text("Uploader mon CV"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}