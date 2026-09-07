import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/app_link_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_progress.dart';
import 'login_screen.dart';

class AppLinkSetupScreen extends StatefulWidget {
  const AppLinkSetupScreen({super.key});

  @override
  State<AppLinkSetupScreen> createState() => _AppLinkSetupScreenState();
}

class _AppLinkSetupScreenState extends State<AppLinkSetupScreen> {
  final _linkController = TextEditingController();
  final _apiService = ApiService();
  final _appLinkService = AppLinkService();
  bool _isSaving = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _saveLink() async {
    final appLink = AppLinkService.normaliseAppLink(_linkController.text);
    if (appLink == null) {
      _showMessage('Enter the full HTTPS Apps Script link ending in /exec.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _apiService.validateAppLink(appLink);
      await _appLinkService.saveAppLink(appLink);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to connect. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: AppColors.primary,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Connect attendance app',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter the Google Apps Script web-app link provided by your shop owner before signing in.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 38),
                  const Text(
                    'APP LINK',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _linkController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveLink(),
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      hintText: 'https://script.google.com/.../exec',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveLink,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const LoadingProgressBar(
                              label: 'Connecting to server',
                              color: Colors.white,
                              trackColor: Color(0x55FFFFFF),
                              textColor: Colors.white,
                            )
                          : const Text(
                              'Save and continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.only(bottom: 8),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.muted,
                    title: Text(
                      'Show Setup Instructions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'For the sheet owner',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    children: [
                      _SetupInstruction(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupInstruction extends StatelessWidget {
  const _SetupInstruction();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InstructionStep(
              title: 'Step 1: Sheet Preparation',
              children: [
                _InstructionLine(
                  '1. Create one Google Sheet with these three tabs, named exactly as shown.',
                ),
                SizedBox(height: 12),
                _SheetTab(
                  name: 'Members',
                  columns: 'username, pin, device_id, active, created_at',
                ),
                _SheetTab(
                  name: 'Attendance',
                  columns:
                      'timestamp, date, username, arrival_time, difference_minutes, status, device_id, bssid',
                ),
                _SheetTab(
                  name: 'Settings',
                  columns: 'key, value',
                ),
                _InstructionLine(
                  '2. Copy the Sheet ID from its URL: the text between /d/ and /edit.',
                ),
              ],
            ),
            SizedBox(height: 22),
            _InstructionStep(
              title: 'Step 2: Apps Script',
              children: [
                _InstructionLine(
                  '1. Copy the supplied Code.gs Apps Script file.',
                ),
                _InstructionLine(
                  '2. In your Sheet, select Extensions > Apps Script. Replace the editor contents with Code.gs, then paste your Sheet ID into APP_CONFIG.',
                ),
                _InstructionLine(
                  '3. Deploy it as a Web app, allow access for your staff, and copy the HTTPS web-app link ending in /exec. Paste that link above.',
                ),
              ],
            ),
            SizedBox(height: 22),
            _InstructionStep(
              title: 'Step 3: Members',
              children: [
                _InstructionLine(
                  '1. In the Members tab, add one staff member per row below the headers.',
                ),
                _InstructionLine(
                  '2. Enter a unique username, a numeric login PIN, and TRUE in active. Leave device_id empty for the first login.',
                ),
                _InstructionLine(
                  '3. The first successful login binds the phone automatically. To allow a replacement phone, clear that member’s device_id cell.',
                ),
              ],
            ),
          ],
        ),
      );
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      );
}

class _InstructionLine extends StatelessWidget {
  const _InstructionLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
      );
}

class _SheetTab extends StatelessWidget {
  const _SheetTab({required this.name, required this.columns});

  final String name;
  final String columns;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
              columns,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
}
