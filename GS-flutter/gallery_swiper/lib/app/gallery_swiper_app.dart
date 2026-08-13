import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/gallery/pages/gallery_page.dart';

class GallerySwiperApp extends StatelessWidget {
  const GallerySwiperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GallerySwiper',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      home: const GalleryPage(),
    );
  }
}
