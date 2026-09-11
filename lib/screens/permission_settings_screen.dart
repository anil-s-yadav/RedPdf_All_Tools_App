import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import '../services/notification_service.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _cameraGranted = false;
  bool _isLoading = true;

  static const String _prefKeyNotif = 'pref_perm_notif_enabled';
  static const String _prefKeyCamera = 'pref_perm_camera_enabled';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    final notifStatus = await Permission.notification.status;
    final cameraStatus = await Permission.camera.status;

    final notifPref = prefs.getBool(_prefKeyNotif) ?? notifStatus.isGranted;
    final cameraPref = prefs.getBool(_prefKeyCamera) ?? cameraStatus.isGranted;

    if (mounted) {
      setState(() {
        _notificationGranted = notifStatus.isGranted && notifPref;
        _cameraGranted = cameraStatus.isGranted && cameraPref;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePermission({
    required String title,
    required String explanation,
    required Permission permission,
    required bool currentValue,
    required String prefKey,
    required Function(bool) onUpdated,
  }) async {
    if (!currentValue) {
      final status = await permission.request();
      final prefs = await SharedPreferences.getInstance();
      if (status.isGranted) {
        await prefs.setBool(prefKey, true);
        if (permission == Permission.notification) {
          await NotificationService.instance.scheduleDailyReminders();
        }
        onUpdated(true);
      } else if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog(title);
      } else {
        await prefs.setBool(prefKey, false);
        if (permission == Permission.notification) {
          await NotificationService.instance.cancelAllReminders();
        }
        onUpdated(false);
      }
    } else {
      final bool? confirm = await _showWarningWithCountdownDialog(
        title: title,
        explanation: explanation,
      );

      if (confirm == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(prefKey, false);
        if (permission == Permission.notification) {
          await NotificationService.instance.cancelAllReminders();
        }
        onUpdated(false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title permission disabled in app.'),
              action: SnackBarAction(
                label: 'System Settings',
                textColor: Colors.amberAccent,
                onPressed: () => openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showWarningWithCountdownDialog({
    required String title,
    required String explanation,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _WarningCountdownDialog(
          title: title,
          explanation: explanation,
        );
      },
    );
  }

  void _showOpenSettingsDialog(String permissionName) {
    final appColors = Theme.of(context).appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings_rounded, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 10),
            Text(
              'Permission Required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: appColors.text,
              ),
            ),
          ],
        ),
        content: Text(
          '$permissionName permission was previously denied. Please enable it in Android System Settings to use this feature.',
          style: TextStyle(color: appColors.subtitle, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: appColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int grantedCount = 0;
    if (_notificationGranted) grantedCount++;
    if (_cameraGranted) grantedCount++;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: appColors.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Permission Settings',
          style: TextStyle(
            color: appColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F291E), const Color(0xFF0F172A)]
                            : [const Color(0xFFF0FDF4), const Color(0xFFEFF6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF10B981),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'Data Safety & Privacy',
                                    style: TextStyle(
                                      color: appColors.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '100% OFFLINE',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your privacy is fully protected. All PDF tools and document conversions process 100% locally on your device. We never collect, upload, or share your files or personal data.',
                                style: TextStyle(
                                  color: appColors.subtitle,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERMISSIONS LIST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: appColors.subtitle?.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '$grantedCount of 2 Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: appColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: appColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          _buildPermissionTile(
                            context: context,
                            title: 'Notifications',
                            description:
                                'Daily reminder alerts at 10:00 AM & background task completion updates.',
                            icon: Icons.notifications_active_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            isEnabled: _notificationGranted,
                            onChanged: (val) {
                              _togglePermission(
                                title: 'Notifications',
                                explanation:
                                    'Turning off Notifications will stop daily reminders and alerts when PDF export or compression finishes.',
                                permission: Permission.notification,
                                currentValue: _notificationGranted,
                                prefKey: _prefKeyNotif,
                                onUpdated: (newVal) =>
                                    setState(() => _notificationGranted = newVal),
                              );
                            },
                            showDivider: true,
                          ),
                          _buildPermissionTile(
                            context: context,
                            title: 'Camera',
                            description:
                                'Capture physical papers, invoices and documents directly into PDF.',
                            icon: Icons.camera_alt_rounded,
                            iconColor: const Color(0xFF6366F1),
                            isEnabled: _cameraGranted,
                            onChanged: (val) {
                              _togglePermission(
                                title: 'Camera',
                                explanation:
                                    'Disabling Camera will prevent you from scanning documents or taking photos directly inside the app.',
                                permission: Permission.camera,
                                currentValue: _cameraGranted,
                                prefKey: _prefKeyCamera,
                                onUpdated: (newVal) =>
                                    setState(() => _cameraGranted = newVal),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => openAppSettings(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Open System App Settings',
                                      style: TextStyle(
                                        color: appColors.text,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Manage Android-level permissions & system defaults',
                                      style: TextStyle(
                                        color: appColors.subtitle,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: appColors.subtitle?.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionTile({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    final appColors = Theme.of(context).appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: appColors.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEnabled ? 'Allowed' : 'Disabled',
                            style: TextStyle(
                              color: isEnabled
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: appColors.subtitle?.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: isEnabled,
                activeTrackColor: appColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 74),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: appColors.divider?.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

class _WarningCountdownDialog extends StatefulWidget {
  final String title;
  final String explanation;

  const _WarningCountdownDialog({
    required this.title,
    required this.explanation,
  });

  @override
  State<_WarningCountdownDialog> createState() =>
      _WarningCountdownDialogState();
}

class _WarningCountdownDialogState extends State<_WarningCountdownDialog> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        if (mounted) {
          setState(() => _countdown--);
        }
      } else {
        if (mounted) {
          setState(() => _countdown = 0);
        }
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Disable ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: appColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.explanation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appColors.subtitle,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _countdown > 0
                  ? (isDark
                      ? const Color(0xFFFEF3C7).withValues(alpha: 0.1)
                      : const Color(0xFFFFFBEB))
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _countdown > 0
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _countdown > 0 ? Icons.timer_outlined : Icons.lock_open_rounded,
                  size: 16,
                  color: _countdown > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 6),
                Text(
                  _countdown > 0
                      ? 'Please wait ${_countdown}s before confirming'
                      : 'You may now proceed to disable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _countdown > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: appColors.divider ?? Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Keep Enabled',
                  style: TextStyle(
                    color: appColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _countdown == 0
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFEF4444).withValues(alpha: 0.25),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _countdown > 0 ? 'Wait (${_countdown}s)' : 'Turn Off',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
