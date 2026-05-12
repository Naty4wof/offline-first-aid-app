import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';

import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_state.dart';

class FirstAidGuideScreen extends StatefulWidget {
  final String injuryId;
  final String injuryName;

  const FirstAidGuideScreen({
    super.key,
    required this.injuryId,
    required this.injuryName,
  });

  @override
  State<FirstAidGuideScreen> createState() => _FirstAidGuideScreenState();
}

class _FirstAidGuideScreenState extends State<FirstAidGuideScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    context.read<GuideBloc>().add(LoadGuidesByInjury(widget.injuryId));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String path) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Text(widget.injuryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              StorageService.instance.isFavorite(widget.injuryId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: StorageService.instance.isFavorite(widget.injuryId)
                  ? Colors.red
                  : null,
            ),
            onPressed: () {
              setState(() {
                context.read<GuideBloc>().add(ToggleFavorite(widget.injuryId));
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<GuideBloc, GuideState>(
        builder: (context, state) {
          if (state is GuideLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GuideLoaded) {
            final guide = state.guides.first;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (guide.imagePath != null)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: AssetImage(guide.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                _header(guide.title),
                if (guide.audioPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleAudio(guide.audioPath!),
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? "አቁም" : "ያዳምጡ (Audio)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E9B59),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                _cardSection(
                  title: "መግለጫ",
                  icon: Icons.info_outline,
                  content: guide.description,
                ),

                _listCard(
                  title: "ምልክቶች",
                  icon: Icons.sick,
                  items: guide.symptoms,
                ),

                _stepsSection(guide.steps),

                _warningSection(guide.warnings),

                _listCard(
                  title: "መድረሻ መፈለግ",
                  icon: Icons.local_hospital,
                  items: guide.whenToSeekHelp,
                ),

                _cardSection(
                  title: "ምክንያት",
                  icon: Icons.lightbulb_outline,
                  content: guide.explanation,
                ),

                _dosDonts(guide.dos, guide.donts),
              ],
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

  // ================= UI COMPONENTS =================

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _cardSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    if (content.isEmpty) return const SizedBox();

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _listCard({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox();

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 8),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepsSection(List<String> steps) {
    if (steps.isEmpty) return const SizedBox();

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("የመጀመሪያ እርምጃዎች", Icons.list_alt),
          const SizedBox(height: 12),

          ...steps.asMap().entries.map((entry) {
            int i = entry.key;
            String step = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE14949),
                    child: Text(
                      "${i + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(step, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _warningSection(List<String> warnings) {
    if (warnings.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "ማስጠንቀቂያ",
            Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          const SizedBox(height: 8),

          ...warnings.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text("⚠ $e", style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dosDonts(List<String> dos, List<String> donts) {
    return Row(
      children: [
        Expanded(
          child: _coloredCard(
            title: "ያድርጉ",
            color: Colors.green.shade50,
            items: dos,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _coloredCard(
            title: "አታድርጉ",
            color: Colors.red.shade50,
            items: donts,
          ),
        ),
      ],
    );
  }

  Widget _coloredCard({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          ...items.map((e) => Text("• $e")),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.black),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
