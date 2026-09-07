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
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.only(bottom: 8),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.muted,
                    title: Text(
                      'Quick setup instructions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Required Google Sheet tabs and columns',
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
            Text(
              '1. Create one Google Sheet and add these tabs exactly as named.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            SizedBox(height: 14),
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
            SizedBox(height: 10),
            Text(
              '2. Paste and deploy the QR Attendance Apps Script as a Web app. Set its spreadsheet ID, then copy the HTTPS URL ending in /exec into the field above.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '3. The Sheet owner adds member usernames, numeric PINs, settings, the QR token, and allowed Wi-Fi BSSIDs. Employees only use this app to sign in and scan.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
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
