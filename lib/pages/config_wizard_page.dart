import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/config.dart';
import '../i18n/i18n.dart';
import '../state/config.dart';
import '../state/library.dart';
import '../state/session.dart';
import '../widgets/page_frame.dart';

/// First-launch setup: collects the storage directory and an optional f95zone
/// login, then writes the non-secret [Config] and holds the session cookie in
/// memory only.
class ConfigWizardPage extends ConsumerStatefulWidget {
  const ConfigWizardPage({super.key});

  @override
  ConsumerState<ConfigWizardPage> createState() => _ConfigWizardPageState();
}

class _ConfigWizardPageState extends ConsumerState<ConfigWizardPage> {
  String? _downloadDir;
  String _cookie = '';
  bool _saving = false;

  Future<void> _pickDir() async {
    final dir = await ref.read(directoryPickerProvider)();
    if (dir != null) {
      setState(() => _downloadDir = dir);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref.read(configProvider.notifier).save(
            Config(downloadDir: _downloadDir),
          );

      final cookie = _cookie.trim();
      if (cookie.isNotEmpty) {
        await ref.read(sessionProvider.notifier).login(cookie);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PageFrame(
      title: t.setup.title,
      loading: _saving,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.setup.welcome,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          DownloadDirSection(value: _downloadDir, onBrowse: _pickDir),
          const SizedBox(height: 16),
          LoginSection(
            cookie: _cookie,
            onCookieChanged: (v) => setState(() => _cookie = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _finish,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.buttons.finish),
          ),
        ],
      ),
    );
  }
}

/// Download directory picker: the selected path plus a "Browse" button.
class DownloadDirSection extends StatelessWidget {
  const DownloadDirSection({
    super.key,
    required this.value,
    required this.onBrowse,
  });

  final String? value;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _Section(
      title: t.setup.downloadDirectory,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null || value!.isEmpty
                  ? t.setup.noDirectory
                  : value!,
              overflow: TextOverflow.ellipsis,
              style: value == null || value!.isEmpty
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.folder_open),
            label: Text(t.common.browse),
          ),
        ],
      ),
    );
  }
}

/// Optional f95zone login: a pasted session cookie.
class LoginSection extends StatelessWidget {
  const LoginSection({
    super.key,
    required this.cookie,
    required this.onCookieChanged,
  });

  final String cookie;
  final ValueChanged<String> onCookieChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _Section(
      title: t.setup.loginOptional,
      child: Column(
        children: [
          TextFormField(
            initialValue: cookie,
            decoration: InputDecoration(
              labelText: t.settings.login.sessionCookie,
              helperText: t.settings.login.sessionCookieHelp,
              isDense: true,
            ),
            onChanged: onCookieChanged,
          ),
        ],
      ),
    );
  }
}

/// A titled, card-wrapped form section shared by the wizard's blocks.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
