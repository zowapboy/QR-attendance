import 'package:flutter/material.dart';

import '../models/dashboard_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/attendance_history.dart';
import '../widgets/monthly_stats.dart';
import '../widgets/today_attendance_card.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.username,
    required this.deviceId,
    this.session,
  });

  final String username;
  final String deviceId;
  final String? session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();

  DashboardData? _dashboard;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getDashboard(
        username: widget.username,
        deviceId: widget.deviceId,
        session: widget.session,
      );
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Unable to load attendance.',
        );
      }
      if (!mounted) return;
      setState(() => _dashboard = DashboardData.fromJson(response));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAgain() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboard == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null && _dashboard == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: AppColors.muted, size: 42),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
                if (_error == 'Invalid account or device') ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _signInAgain,
                    child: const Text('Sign in again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final dashboard = _dashboard!;
    final username =
        dashboard.username.isEmpty ? widget.username : dashboard.username;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning,',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.muted,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            username,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Refresh dashboard',
                        onPressed: _isLoading ? null : _loadDashboard,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceRaised,
                          foregroundColor: AppColors.primary,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dashboard.serverDate,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        'REPORTING ${dashboard.reportingTime}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: TodayAttendanceCard(
                    today: dashboard.today,
                    scannerOpen: dashboard.scannerOpen,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Current-month overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: MonthlyStats(month: dashboard.month),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recent attendance',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                sliver: SliverToBoxAdapter(
                  child: AttendanceHistory(history: dashboard.history),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
