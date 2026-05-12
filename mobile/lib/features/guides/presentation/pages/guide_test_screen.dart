import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/guide_bloc.dart';
import '../bloc/guide_event.dart';
import '../bloc/guide_state.dart';

class GuideTestScreen extends StatelessWidget {
  const GuideTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("መመሪያዎች"),
      ),
      body: BlocBuilder<GuideBloc, GuideState>(
        builder: (context, state) {
          if (state is GuideLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GuideLoaded) {
            return ListView.builder(
              itemCount: state.guides.length,
              itemBuilder: (context, index) {
                final guide = state.guides[index];
                return ListTile(
                  title: Text(guide.title),
                );
              },
            );
          }

          if (state is GuideError) {
            return Center(child: Text(state.message));
          }

          return const Center(
            child: Text("Press the button to load guides"),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<GuideBloc>().add(LoadGuides());
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}