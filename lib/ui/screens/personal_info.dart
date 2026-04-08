import 'package:flutter/material.dart';
import 'package:offline_first_aid_app/ui/screens/home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();

  int _currentStep = 0;

  // controllers (same as yours)
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;

  String? _bloodType;
  final List<String> _allergies = [];
  final _allergyInput = TextEditingController();

  final _contactName = TextEditingController();
  final _contactRelation = TextEditingController();
  final _contactPhone = TextEditingController();

  void _next() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
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
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
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

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// 🔵 MODERN STEP HEADER
  Widget _stepHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step ${_currentStep + 1} of 3",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔶 CARD WRAPPER
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  /// STEP 1
  Widget _step1() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Basic Info",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: _inputDecoration("Full Name"),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Age"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField(
                  value: _gender,
                  decoration: _inputDecoration("Gender"),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text("Male")),
                    DropdownMenuItem(value: 'female', child: Text("Female")),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// STEP 2 (IMPROVED)
  Widget _step2() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Medical Info",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          DropdownButtonFormField(
            value: _bloodType,
            decoration: _inputDecoration("Blood Type"),
            items: const [
              DropdownMenuItem(value: 'A+', child: Text('A+')),
              DropdownMenuItem(value: 'O+', child: Text('O+')),
              DropdownMenuItem(value: 'B+', child: Text('B+')),
            ],
            onChanged: (v) => setState(() => _bloodType = v),
          ),

          const SizedBox(height: 20),

          const Text("Allergies"),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: _allergies
                .map((e) => Chip(
                      label: Text(e),
                      onDeleted: () =>
                          setState(() => _allergies.remove(e)),
                    ))
                .toList(),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _allergyInput,
                  decoration: _inputDecoration("Add allergy"),
                ),
              ),
              IconButton(
                onPressed: _addAllergy,
                icon: const Icon(Icons.add),
              )
            ],
          ),
        ],
      ),
    );
  }

  /// STEP 3
  Widget _step3() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Emergency Contact",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: _contactName,
            decoration: _inputDecoration("Name"),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _contactRelation,
            decoration: _inputDecoration("Relation"),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration("Phone"),
          ),
        ],
      ),
    );
  }

  /// INPUT STYLE
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔵 MODERN BOTTOM BAR
  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
            ),

          const Spacer(),

          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(_currentStep == 2 ? "Finish" : "Next"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _stepHeader(),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _step1(),
                  _step2(),
                  _step3(),
                ],
              ),
            ),

            _bottomBar(),
          ],
        ),
      ),
    );
  }
}