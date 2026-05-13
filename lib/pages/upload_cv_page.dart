// upload_cv_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/cv_provider.dart';

class UploadCvPage extends ConsumerStatefulWidget {
  const UploadCvPage({super.key});

  @override
  ConsumerState<UploadCvPage> createState() => _UploadCvPageState();
}

class _UploadCvPageState extends ConsumerState<UploadCvPage> {
  bool isLoading = false;

  Future<void> _pickAndUploadCv() async {
    setState(() => isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,           // ← Important pour Web
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        final user = ref.read(authProvider);

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vous devez être connecté")),
          );
          return;
        }

        String? error;

        if (file.bytes != null) {
          // Web + Mobile (recommandé)
          error = await ref.read(cvProvider.notifier).uploadCvFromBytes(
            file.bytes!,
            file.name,
            user.uid,
          );
        } else if (file.path != null) {
          // Mobile/Desktop sans bytes
          error = await ref.read(cvProvider.notifier).uploadCv(
            file.path!,
            file.name,
            user.uid,
          );
        } else {
          error = "Impossible de lire le fichier";
        }

        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ CV uploadé avec succès !"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $error")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploader mon CV"),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file, size: 120, color: Colors.indigo),
              const SizedBox(height: 30),
              Text(
                "Bonjour ${currentUser?.name ?? 'Utilisateur'}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Sélectionnez votre CV au format PDF",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _pickAndUploadCv,
                  icon: const Icon(Icons.upload),
                  label: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Choisir un fichier PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Formats acceptés : .pdf\nTaille maximale : 10 Mo",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}