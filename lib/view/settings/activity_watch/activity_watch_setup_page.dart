import '../../../screen.dart';
import '../../../service/activity_watch/activity_watch_service.dart';

class ActivityWatchSetupPage extends StatefulWidget {
  const ActivityWatchSetupPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ActivityWatchSetupPage> createState() => _ActivityWatchSetupPageState();
}

class _ActivityWatchSetupPageState extends State<ActivityWatchSetupPage> {
  final _deviceLabel = TextEditingController();
  final _scrollController = ScrollController();
  final _service = ActivityWatchService();
  bool _consented = false;
  bool _submitting = false;
  String? _credential;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _deviceLabel.text = defaultTargetPlatform == TargetPlatform.macOS
        ? 'Mac desktop'
        : 'Desktop device';
  }

  @override
  void dispose() {
    _deviceLabel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    _ => '',
  };

  Future<void> _enroll() async {
    if (!_consented || _deviceLabel.text.trim().isEmpty || _platform.isEmpty) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final enrollment = await _service.enroll(
        deviceLabel: _deviceLabel.text,
        platform: _platform,
        consentVersion: 1,
      );
      if (!mounted) return;
      setState(() {
        _deviceId = enrollment.deviceId;
        _credential = enrollment.credential;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity Watch enrollment failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Activity Watch',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              'Opt in to privacy-safe desktop activity summaries. The agent records active, idle, and locked durations plus application name/category only.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppUiConstants.spacingXl),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Privacy protection',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  const Text(
                    'Never collected: keystrokes, clipboard content, screenshots, pointer coordinates, window/tab titles, full URLs, page content, or command-line arguments.',
                  ),
                  const SizedBox(height: AppUiConstants.spacingLg),
                  AppFormTextField(
                    controller: _deviceLabel,
                    labelText: 'Device label',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consented,
                    onChanged: _submitting
                        ? null
                        : (value) =>
                              setState(() => _consented = value ?? false),
                    title: const Text(
                      'I consent to this privacy-safe Activity Watch collection.',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _submitting || !_consented || _platform.isEmpty
                          ? null
                          : _enroll,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shield_outlined),
                      label: Text(
                        _submitting ? 'Enrolling…' : 'Enroll this device',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_credential != null) ...<Widget>[
              const SizedBox(height: AppUiConstants.spacingXl),
              AppSectionCard(
                child: SelectableText(
                  'Device enrolled: $_deviceId\n\nDevice credential (copy into the protected Go service credential file):\n$_credential',
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return widget.embedded
        ? ShellPageActions(actions: const <Widget>[], child: content)
        : AppStandaloneShell(
            title: 'Activity Watch',
            scrollController: _scrollController,
            actions: const <Widget>[],
            child: content,
          );
  }
}
