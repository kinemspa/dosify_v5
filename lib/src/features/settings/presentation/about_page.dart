// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/legal/disclaimer_settings.dart';
import 'package:skedux/src/core/utils/developer_options.dart';
import 'package:skedux/src/widgets/app_header.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';

/// Full-screen About page containing app info and all legal content.
///
/// Navigated to from Settings; replaces the old inline "Legal" + "About"
/// sections so they are consolidated in one place.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  static const _unlockTapTarget = 10;
  bool _devEnabled = false;
  int _tapCount = 0;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    _loadDevEnabled();
  }

  Future<void> _loadDevEnabled() async {
    final enabled = await DeveloperOptions.isEnabled();
    if (!mounted) return;
    setState(() => _devEnabled = enabled);
  }

  Future<void> _handleLogoTap() async {
    final now = DateTime.now();
    const resetWindowMs = 2000;
    if (_lastTapAt == null ||
        now.difference(_lastTapAt!).inMilliseconds > resetWindowMs) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount += 1;

    if (_tapCount < _unlockTapTarget) return;

    final nextEnabled = !_devEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DeveloperOptions.prefsKey, nextEnabled);

    if (!mounted) return;
    setState(() {
      _devEnabled = nextEnabled;
      _tapCount = 0;
    });
    showAppSnackBar(
      context,
      nextEnabled
          ? 'Developer options enabled'
          : 'Developer options disabled',
    );
  }

  Future<void> _showLicenses(BuildContext context) async {
    final info = await _packageInfo;
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: info.appName,
      applicationVersion: info.buildNumber.trim().isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})',
      applicationIcon: Image.asset(
        kPrimaryLogoAssetPath,
        height: kAboutDialogLogoSize,
        width: kAboutDialogLogoSize,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'About', forceBackButton: true),
      body: ListView(
        padding: kPagePadding,
        children: [
          // ── App info ────────────────────────────────────────────────────────
          Text(
            'App Info',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final versionText = info == null
                  ? 'Loading…'
                  : info.buildNumber.trim().isEmpty
                  ? info.version
                  : '${info.version} (${info.buildNumber})';

              return Column(
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: _handleLogoTap,
                      child: Image.asset(
                        kPrimaryLogoAssetPath,
                        height: kSettingsAboutTileLogoSize,
                        width: kSettingsAboutTileLogoSize,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    title: const Text('Skedux'),
                    subtitle: Text(
                      _devEnabled
                          ? '$versionText • Developer options enabled'
                          : versionText,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Open-source Licenses'),
                    subtitle: const Text('View third-party library licenses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLicenses(context),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: kSpacingL),

          // ── Legal ────────────────────────────────────────────────────────
          Text(
            'Legal',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Research Disclaimer'),
            subtitle: const Text('For research and informational purposes only'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/disclaimer', extra: true),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal'),
          ),
          ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: const Text('Reset disclaimer'),
            subtitle: const Text(
              'Reset acceptance so the disclaimer appears on next launch',
            ),
            onTap: () async {
              await DisclaimerSettings.reset();
              if (!context.mounted) return;
              showAppSnackBar(
                context,
                'Disclaimer will appear on next app launch',
              );
            },
          ),
        ],
      ),
    );
  }
}
