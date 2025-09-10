import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.forceBackButton = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool forceBackButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop() || forceBackButton;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
          ),
        ),
      ),
      leading: canPop ? const BackButton(color: Colors.white) : null,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      actions: [
        if (actions != null) ...actions!,
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          onSelected: (value) {
            if (value == 'settings') {
              context.push('/settings');
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'settings', child: Text('Settings')),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
