import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/app/router.dart';
import 'package:wardrobe/core/app_font.dart';
import 'package:wardrobe/core/theme.dart';

class WardrobeApp extends ConsumerWidget {
  const WardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '衣橱',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ref.watch(appFontProvider)),
      routerConfig: appRouter,
    );
  }
}
