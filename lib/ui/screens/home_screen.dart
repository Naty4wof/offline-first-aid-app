import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:offline_first_aid_app/ui/screens/chat_screen.dart';
import 'package:offline_first_aid_app/ui/screens/category_screen.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/search_section.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/category_section.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/quick_actions_section.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/home_bottom_nav.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/floating_mic_button.dart';

import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _sheetController;

  @override
  void initState() {
    super.initState();

    // ✅ Load categories once
    context.read<GuideBloc>().add(LoadCategories());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ CRITICAL FIX: remove focus AFTER returning to screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  void _startRecording() {
    _sheetController = _scaffoldKey.currentState?.showBottomSheet((context) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.mic_rounded, size: 36, color: Color(0xFFE14949)),
            SizedBox(height: 8),
            Text('መቅረብ በማለት ይጠብቁ...'),
            SizedBox(height: 6),
            Text(
              'ያስቆጡ በመዝጋት ይሰማ ይሆናል',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7880)),
            ),
          ],
        ),
      );
    });
  }

  void _stopRecording() {
    _sheetController?.close();
    _sheetController = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7FAF9),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'የመጀመሪያ እርዳታ መነሻ',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF132125),
          ),
        ),
      ),

      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: const [
              SearchSection(),
              SizedBox(height: 18),
              CategorySection(),
              SizedBox(height: 18),
              QuickActionsSection(),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingMicButton(
        onLongPressStart: (_) => _startRecording(),
        onLongPressEnd: (_) => _stopRecording(),
      ),

      bottomNavigationBar: HomeBottomNav(
        onGuidesTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CategoryScreen()));
        },
        onChatTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
        },
      ),
    );
  }
}
