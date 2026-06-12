import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// More tab — settings groups land in Phase 2; Ramadan/Calendar entries in
/// Phase 10. In debug builds it links to the widget gallery.
final class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return PlaceholderScreen(title: context.l10n.tabMore);
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tabMore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(context.l10n.galleryTitle),
            onTap: () => context.pushNamed(Routes.gallery.name),
          ),
        ],
      ),
    );
  }
}
