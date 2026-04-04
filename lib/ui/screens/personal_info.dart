import 'package:flutter/material.dart';
import 'package:offline_first_aid_app/ui/screens/home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Step 1
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _gender;

  // Step 2
  String? _bloodType;
  final List<String> _allergies = [];
  final TextEditingController _allergyInput = TextEditingController();
  final TextEditingController _chronicController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  // Step 3
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _contactRelation = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();

  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _allergyInput.dispose();
    _chronicController.dispose();
    _medicationsController.dispose();
    _contactName.dispose();
    _contactRelation.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _next() {
    final valid = _formKeys[_currentStep].currentState?.validate() ?? true;
    if (!valid) return;
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _skipOptional() {
    // Skip optional fields on current step (clears optional controllers)
    if (_currentStep == 1) {
      _medicationsController.clear();
      _chronicController.clear();
      _allergies.clear();
      setState(() {});
    }
  }

  void _addAllergy() {
    final val = _allergyInput.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _allergies.add(val);
      _allergyInput.clear();
    });
  }

  void _removeAllergy(String v) {
    setState(() => _allergies.remove(v));
  }

  void _finish() {
    // validate all forms
    for (var key in _formKeys) {
      if (!(key.currentState?.validate() ?? true)) {
        final idx = _formKeys.indexOf(key);
        setState(() => _currentStep = idx);
        _pageController.jumpToPage(idx);
        return;
      }
    }

    // gather data (for now show in snackbar)
    final data = {
      'name': _nameController.text.trim(),
      'age': _ageController.text.trim(),
      'gender': _gender,
      'bloodType': _bloodType,
      'allergies': _allergies,
      'chronic': _chronicController.text.trim(),
      'medications': _medicationsController.text.trim(),
      'contactName': _contactName.text.trim(),
      'contactRelation': _contactRelation.text.trim(),
      'contactPhone': _contactPhone.text.trim(),
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ደብዳቤ ተያዙ — ${data['name']}')));
    // TODO: persist this data securely (local DB / secure storage)

    // After saving, navigate to home
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1}/3',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            color: const Color(0xFF2E8B57),
            backgroundColor: const Color(0xFFEAF6EE),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeys[0],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'የሙሉ ስም',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 18),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      hintText: 'ዕድሜ',
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 18),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0 || n > 120)
                        return 'Enter a valid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeys[1],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medical Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bloodType,
                decoration: const InputDecoration(
                  labelText: 'Blood type',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                ],
                onChanged: (v) => setState(() => _bloodType = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please select' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Allergies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _allergies)
                    InputChip(
                      label: Text(a),
                      onDeleted: () => _removeAllergy(a),
                    ),
                  SizedBox(
                    width: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _allergyInput,
                            decoration: const InputDecoration(
                              hintText: 'Add allergy',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addAllergy(),
                          ),
                        ),
                        IconButton(
                          onPressed: _addAllergy,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chronicController,
                decoration: const InputDecoration(
                  labelText: 'Chronic conditions',
                  hintText: 'e.g. diabetes, asthma',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 16),
                validator: (v) => null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  labelText: 'Medications (optional)',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 16),
                validator: (v) => null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skipOptional,
                  child: const Text('Skip optional'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeys[2],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactName,
              decoration: const InputDecoration(
                labelText: 'Contact name',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 18),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactRelation,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 18),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 18),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 7) return 'Enter a valid phone';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      appBar: AppBar(
        title: const Text('Register Emergency Info'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF132125),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
            // sticky bottom buttons
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(onPressed: _back, child: const Text('Back'))
                  else
                    const SizedBox(width: 72),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // allow skipping non-critical fields on current step
                      _skipOptional();
                      if (_currentStep < 2) {
                        _next();
                      }
                    },
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      minimumSize: const Size(120, 48),
                    ),
                    child: Text(_currentStep < 2 ? 'Next' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
