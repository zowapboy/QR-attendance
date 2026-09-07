import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openSetupGuide() async {
    final opened = await launchUrl(
      Uri.parse('https://attendance.tuahrem.com/setup'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showMessage('Could not open the setup guide. Please try again.');
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
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton.icon(
                      onPressed: _openSetupGuide,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Step by step Guide'),
                    ),
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
