import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_state.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';
import 'package:offline_first_aid_app/features/guides/data/models/category_model.dart';
import 'package:offline_first_aid_app/ui/screens/injury_screen.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _filtered = [];

  @override
  void initState() {
    super.initState();

    // Clear suggestions when focus is lost
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _filtered = []);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = q.trim().toLowerCase();

      if (query.isEmpty) {
        setState(() => _filtered = []);
        return;
      }

      final results = _allCategories
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();

      setState(() => _filtered = results);
    });
  }

  void _onSubmit(String value) {
    if (value.trim().isEmpty) return;

    // Close keyboard
    FocusScope.of(context).unfocus();

    // Optional: navigate to full search page later
    // Navigator.push(...)
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuideBloc, GuideState>(
      listener: (context, state) {
        if (state is CategoryLoaded) {
          _allCategories = state.categories;
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 🔍 SEARCH FIELD
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _onSubmit,
                decoration: InputDecoration(
                  hintText: 'ምድቦችን ፈልግ (ለምሳሌ: ቃጠሎ, ደም መፍሰስ)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _filtered = []);
                            _focusNode.unfocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF2F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),

              // 🔽 RESULTS DROPDOWN
              if (_filtered.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black12),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = _filtered[index];

                      return ListTile(
                        title: Text(c.name),
                        leading: const Icon(Icons.folder_open),
                        onTap: () {
                          // ✅ CLOSE KEYBOARD
                          FocusScope.of(context).unfocus();

                          final guideBloc = context.read<GuideBloc>();

                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: guideBloc,
                                    child: InjuryScreen(
                                      categoryId: c.id,
                                      categoryName: c.name,
                                    ),
                                  ),
                                ),
                              )
                              .then((_) {
                                guideBloc.add(LoadCategories());
                              });

                          // clear UI
                          _controller.clear();
                          setState(() => _filtered = []);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
