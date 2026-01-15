import 'package:flutter/material.dart';

/// Widget pour basculer entre les thèmes clair et sombre
class ToggleTheme extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const ToggleTheme({
    Key? key,
    required this.isDarkMode,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(isDarkMode),
        ),
      ),
      tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
    );
  }
}