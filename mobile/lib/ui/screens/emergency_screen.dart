import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_first_aid_app/features/hospitals/data/models/emergency_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<EmergencyModel> _numbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/emergency_numbers.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      final List list = data['emergency_numbers'];

      setState(() {
        _numbers = list.map((e) => EmergencyModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callNumber(String number) async {
    final url = 'tel:$number';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ድንገተኛ ጥሪ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _numbers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _numbers[index];
                return ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item.category),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.number,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => _callNumber(item.number),
                );
              },
            ),
    );
  }
}
