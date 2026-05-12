import 'package:flutter/material.dart';
import 'package:offline_first_aid_app/ui/screens/onboarding_screen.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _goNext() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await StorageService.instance.setHasSeenWelcome();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 86,
                    width: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.healing,
                      size: 42,
                      color: Color(0xFFE14949),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'እንኳን ደህና መጡ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ይህ መተግበሪያ የመጀመሪያ እርዳታ መረጃን በፍጥነት ለማግኘት ይረዳዎታል።',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5F6B6D),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEDE7E2)),
                    ),
                    child: Column(
                      children: [
                        _rowItem(theme, 'መጀመሪያ እርዳታ መመሪያዎች', Icons.favorite),
                        const SizedBox(height: 10),
                        _rowItem(theme, 'የአደጋ ጊዜ መረጃ እና ቁጥሮች', Icons.call),
                        const SizedBox(height: 10),
                        _rowItem(theme, 'ቀላል መፍትሄዎች በፍጥነት', Icons.flash_on),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3D8CC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'አስፈላጊ ማስታወሻ',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ይህ መተግበሪያ ሙሉ የሕክምና ምክርን አይተካም። ከባድ ጉዳት ወይም ህመም ካለ፣ ወዲያውኑ የህክምና ባለሙያ ያግኙ።',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF7A4E3A),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _goNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('መዝለል'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _rowItem(ThemeData theme, String text, IconData icon) {
  return Row(
    children: [
      Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2E9B59)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4A585A),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}
