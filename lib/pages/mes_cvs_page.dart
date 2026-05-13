// mes_cvs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cv_provider.dart';
import '../providers/auth_provider.dart';
import 'cv_detail_page.dart';   // On va le créer juste après
import 'upload_cv_page.dart'; 
class MesCvsPage extends ConsumerStatefulWidget {
  const MesCvsPage({super.key});

  @override
  ConsumerState<MesCvsPage> createState() => _MesCvsPageState();
}

class _MesCvsPageState extends ConsumerState<MesCvsPage> {
  @override
  void initState() {
    super.initState();
    _loadUserCvs();
  }

  Future<void> _loadUserCvs() async {
    final user = ref.read(authProvider);
    if (user != null) {
      await ref.read(cvProvider.notifier).loadUserCvs(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvs = ref.watch(cvProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes CVs"),
        backgroundColor: Colors.indigo,
      ),
      body: cvs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "Vous n'avez pas encore uploadé de CV",
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text("Appuyez sur le bouton + pour commencer"),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cvs.length,
              itemBuilder: (context, index) {
                final cv = cvs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, 
                               color: Colors.red, size: 50),
                    title: Text(
                      cv.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${cv.uploadDate.day.toString().padLeft(2,'0')}/${cv.uploadDate.month.toString().padLeft(2,'0')}/${cv.uploadDate.year}",
                        ),
                        Text(
                          "${cv.keywords.length} compétences détectées",
                          style: const TextStyle(color: Colors.indigo),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CvDetailPage(cv: cv),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadCvPage()),
          );
        },
        child: const Icon(Icons.upload),
      ),
    );
  }
}