import 'package:flutter/material.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';
import 'package:offline_first_aid_app/ui/screens/home_screen.dart';
import 'package:offline_first_aid_app/core/services/sync_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final medicalController = TextEditingController();

  String bloodType = 'O+';
  bool isLoading = false;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final profile = {
      "name": nameController.text.trim(),
      "age": ageController.text.trim(),
      "bloodType": bloodType,
      "medical": medicalController.text.trim(),
      "createdAt": DateTime.now().toIso8601String(),
      "isSynced": false,
    };

    await StorageService.instance.saveUserProfile(profile);

    // 🔥 TRY SYNC
    final syncService = SyncService();
    await syncService.syncUser();

    setState(() => isLoading = false);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                      child: const Text("ዝለል"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Image.asset('assets/logo.png', height: 90),

                const SizedBox(height: 20),

                Text(
                  'መረጃዎን ያስገቡ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// NAME
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "ስም",
                    hintText: "ሙሉ ስም",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "እባክዎ ስምዎን ያስገቡ" : null,
                ),

                const SizedBox(height: 16),

                /// AGE
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "እድሜ",
                    hintText: "እድሜዎን ቁጥር ያስገቡ",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "እባክዎ እድሜዎን ያስገቡ" : null,
                ),

                const SizedBox(height: 16),

                /// BLOOD TYPE
                DropdownButtonFormField<String>(
                  value: bloodType,
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => bloodType = v!),
                  decoration: const InputDecoration(
                    labelText: "የደም አይነት",
                    hintText: "አይነት ይምረጡ",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                /// MEDICAL INFO
                TextFormField(
                  controller: medicalController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "የሕክምና ሁኔታ",
                    hintText: "ካለዎት ልዩ ሁኔታ ያስገቡ",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ቀጥል"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
