import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_state.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';
import 'package:offline_first_aid_app/ui/screens/firstaid_guide_screen.dart';
import 'package:offline_first_aid_app/ui/screens/injury_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    // Dispatch search when screen opens
    context.read<GuideBloc>().add(SearchQuery(query));

    return Scaffold(
      appBar: AppBar(title: Text('Search: "' + query + '"')),
      body: BlocBuilder<GuideBloc, GuideState>(
        builder: (context, state) {
          if (state is SearchLoading || state is GuideLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SearchLoaded) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (state.categories.isNotEmpty) ...[
                  const Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final c in state.categories)
                    ListTile(
                      title: Text(c.name),
                      leading: const Icon(Icons.folder),
                      onTap: () {
                        // Navigate to injuries of that category
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<GuideBloc>(),
                              child: InjuryScreen(
                                categoryId: c.id,
                                categoryName: c.name,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const Divider(),
                ],

                if (state.injuries.isNotEmpty) ...[
                  const Text(
                    'Injuries',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final i in state.injuries)
                    ListTile(
                      title: Text(i.title),
                      subtitle: Text('Severity: ${i.severity}'),
                      leading: const Icon(Icons.healing),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<GuideBloc>(),
                              child: FirstAidGuideScreen(
                                injuryId: i.id,
                                injuryName: i.title,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const Divider(),
                ],

                if (state.guides.isNotEmpty) ...[
                  const Text(
                    'Guides',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final g in state.guides)
                    ListTile(
                      title: Text(g.title),
                      subtitle: Text(
                        g.explanation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.menu_book),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<GuideBloc>(),
                              child: FirstAidGuideScreen(
                                injuryId: g.injuryId,
                                injuryName: g.title,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],

                if (state.categories.isEmpty &&
                    state.injuries.isEmpty &&
                    state.guides.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Text(
                        'No results found',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            );
          }

          if (state is GuideError) return Center(child: Text(state.message));

          return const SizedBox();
        },
      ),
    );
  }
}
