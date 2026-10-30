import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/i18n.dart';

/// The project's GitHub repository, opened by the footer's GitHub button.
const String kRepoUrl = 'https://github.com/tom8zds/f95hub';

/// The project's author, credited in the settings footer.
const String kAuthor = 'tom8zds';

/// The settings footer: the app mark, the build's version, the author and a
/// GitHub button that opens [kRepoUrl] in the browser.
///
/// The version comes from the executable's own metadata
/// ([PackageInfo.fromPlatform]), so it always matches the build; when the
/// platform cannot report it (widget tests, an unsupported host) the line is
/// simply omitted.
class AboutFooter extends StatefulWidget {
  const AboutFooter({super.key});

  @override
  State<AboutFooter> createState() => _AboutFooterState();
}

class _AboutFooterState extends State<AboutFooter> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {
      // No platform metadata available; leave the version line out.
    }
    if (mounted && version != null) {
      setState(() => _version = version);
    }
  }

  Future<void> _openRepo() => launchUrl(
        Uri.parse(kRepoUrl),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final version = _version;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/branding/icon_256.png',
                width: 48,
                height: 48,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('f95hub', style: theme.textTheme.titleMedium),
                if (version != null)
                  Text(
                    t.settings.about.version(version: version),
                    style: muted,
                  ),
                Text(t.settings.about.author(author: kAuthor), style: muted),
              ],
            ),
          ),
          IconButton(
            tooltip: t.settings.about.github,
            onPressed: _openRepo,
            icon: const FaIcon(FontAwesomeIcons.github, size: 20),
          ),
        ],
      ),
    );
  }
}
