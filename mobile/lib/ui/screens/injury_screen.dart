import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_state.dart';

import 'firstaid_guide_screen.dart';

class InjuryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const InjuryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<InjuryScreen> createState() => _InjuryScreenState();
}

class _InjuryScreenState extends State<InjuryScreen> {
  @override
  void initState() {
    super.initState();

    context.read<GuideBloc>().add(LoadInjuriesByCategory(widget.categoryId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: BlocBuilder<GuideBloc, GuideState>(
        builder: (context, state) {
          if (state is GuideLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InjuryLoaded) {
            if (state.injuries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'የህክምና መመሪያዎች አልተገኙም',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.read<GuideBloc>().add(
                        LoadInjuriesByCategory(widget.categoryId),
                      ),
                      child: const Text('እንደገና ይጫኑ'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.injuries.length,
              itemBuilder: (context, index) {
                final injury = state.injuries[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final guideBloc = context.read<GuideBloc>();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: guideBloc,
                            child: FirstAidGuideScreen(
                              injuryId: injury.id,
                              injuryName: injury.title,
                            ),
                          ),
                        ),
                      ).then((_) {
                        guideBloc.add(
                          LoadInjuriesByCategory(widget.categoryId),
                        );
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.shade50,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        injury.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Localized severity label
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: injury.severity == 'severe'
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        injury.severity == 'severe'
                                            ? 'ከባድ'
                                            : 'ቀላል',
                                        style: TextStyle(
                                          color: injury.severity == 'severe'
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (injury.keywords.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: injury.keywords
                                        .take(4)
                                        .map(
                                          (k) => Chip(
                                            label: Text(k),
                                            backgroundColor:
                                                Colors.grey.shade100,
                                          ),
                                        )
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          if (state is GuideError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
