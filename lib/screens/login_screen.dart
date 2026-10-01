import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/offline_auth_service.dart';
import '../theme/smartlog_theme.dart';

import 'admin_home_screen.dart';
import 'hod_home_screen.dart';
import 'lecturer_home_screen.dart';
import 'student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  String? errorMessage;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    final identifier = loginController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your DWU ID or email.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.login(
        login: identifier,
        password: password,
      );

      final rawUser = result['user'];

      if (rawUser is! Map) {
        if (!mounted) return;

        setState(() {
          errorMessage = 'Login succeeded, but user information was not returned correctly.';
        });
        return;
      }

      final user = Map<String, dynamic>.from(rawUser);

      final role = user['role']?.toString().trim().toUpperCase();

      // Preserve student credentials for offline login.
      if (role == 'STUDENT') {
        await OfflineAuthService.saveStudentLogin(
          identifier: identifier,
          password: password,
          user: user,
        );
      }

      if (!mounted) return;

      openDashboard(user, offlineLogin: false);
    } on SmartLogAuthenticationException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
      });
    } on SmartLogNetworkException {
      // Server unavailable: attempt existing student offline login.
      final offlineUser = await OfflineAuthService.authenticateOffline(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      if (offlineUser == null) {
        setState(() {
          errorMessage =
              'SmartLog server is unavailable. Offline login is available only '
              'after this student has successfully signed in online on this device.';
        });
        return;
      }

      final role = offlineUser['role']?.toString().trim().toUpperCase();

      if (role != 'STUDENT') {
        setState(() {
          errorMessage =
              'Offline login is currently available only for students.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Offline login successful. SmartLog is using data stored on this device.',
          ),
        ),
      );

      openDashboard(offlineUser, offlineLogin: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to complete login: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN CORRECT DASHBOARD
  // ============================================================

  void openDashboard(Map<String, dynamic> user, {required bool offlineLogin}) {
    final role = user['role']?.toString().trim().toUpperCase();

    if (role == 'STUDENT') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StudentHomeScreen(user: user)),
      );
      return;
    }

    if (offlineLogin) {
      setState(() {
        errorMessage =
            'Offline login is currently available only for students.';
      });
      return;
    }

    if (role == 'LECTURER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LecturerHomeScreen(user: user)),
      );
      return;
    }

    if (role == 'HOD') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HodHomeScreen(user: user)),
      );
      return;
    }

    if (role == 'ICT_ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminHomeScreen(user: user)),
      );
      return;
    }

    setState(() {
      errorMessage = 'This SmartLog user role is not currently supported.';
    });
  }

  // ============================================================
  // CLEAN UP
  // ============================================================

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartLogColors.background,
      body: Stack(
        children: [
          // ----------------------------------------------------
          // BACKGROUND DECORATION
          // ----------------------------------------------------

          Positioned(
            top: -130,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartLogColors.cyan.withValues(alpha: 0.10),
              ),
            ),
          ),

          Positioned(
            top: 120,
            left: -110,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartLogColors.blue.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 470),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrandHeader(),

                            const SizedBox(height: 24),

                            _buildLoginCard(),

                            const SizedBox(height: 16),

                            _buildOfflineCard(),

                            const SizedBox(height: 22),

                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAND HEADER
  // ============================================================

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SmartLogColors.navy,
            SmartLogColors.deepBlue,
            SmartLogColors.blue,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: SmartLogColors.navy.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Final SmartLog logo
          Container(
            width: 118,
            height: 118,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.80),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/smartlog_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 56,
                      color: SmartLogColors.blue,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'SMARTLOG',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'DWU Digital Clinical Logbook',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Record clinical experience. Verify progress. '
            'Continue working online or offline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SmartLogColors.border),
        boxShadow: [
          BoxShadow(
            color: SmartLogColors.navy.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SmartLogColors.paleBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    color: SmartLogColors.blue,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: SmartLogColors.navy,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sign in with your DWU account',
                        style: TextStyle(
                          color: SmartLogColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'DWU ID or Email',
              style: TextStyle(
                color: SmartLogColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: loginController,
              enabled: !loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              decoration: const InputDecoration(
                hintText: 'Enter your DWU ID or email',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),

            const SizedBox(height: 17),

            const Text(
              'Password',
              style: TextStyle(
                color: SmartLogColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: passwordController,
              enabled: !loading,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!loading) {
                  login();
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],

            const SizedBox(height: 22),

            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: loading ? null : login,
                style: FilledButton.styleFrom(
                  backgroundColor: SmartLogColors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: SmartLogColors.blue.withValues(
                    alpha: 0.50,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Signing in...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 21),
                          SizedBox(width: 9),
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 14),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: SmartLogColors.muted,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Secure DWU SmartLog access',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SmartLogColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: SmartLogColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SmartLogColors.danger.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SmartLogColors.danger,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: SmartLogColors.danger,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFLINE SUPPORT
  // ============================================================

  Widget _buildOfflineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmartLogColors.paleBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SmartLogColors.cyan.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.offline_bolt_outlined,
              color: SmartLogColors.cyan,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Offline Support',
                  style: TextStyle(
                    color: SmartLogColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Students who previously signed in online on this device '
                  'can continue accessing SmartLog when the server is unavailable.',
                  style: TextStyle(
                    color: SmartLogColors.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: const [
            _FeatureChip(
              icon: Icons.assignment_outlined,
              label: 'Clinical Logbook',
            ),
            _FeatureChip(icon: Icons.verified_outlined, label: 'Verification'),
            _FeatureChip(icon: Icons.sync_rounded, label: 'Offline Sync'),
          ],
        ),

        const SizedBox(height: 18),

        const Text(
          'Divine Word University',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SmartLogColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'SmartLog Clinical Placement System',
          textAlign: TextAlign.center,
          style: TextStyle(color: SmartLogColors.muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

// ============================================================
// SMALL FEATURE CHIP
// ============================================================

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: SmartLogColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: SmartLogColors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SmartLogColors.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
