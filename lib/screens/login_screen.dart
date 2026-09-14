import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/offline_auth_service.dart';

import 'admin_home_screen.dart';
import 'hod_home_screen.dart';
import 'lecturer_home_screen.dart';
import 'student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  String? errorMessage;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    final identifier =
        loginController.text.trim();

    final password =
        passwordController.text;

    if (identifier.isEmpty) {
      setState(() {
        errorMessage =
            'Please enter your DWU ID or email.';
      });

      return;
    }

    if (password.isEmpty) {
      setState(() {
        errorMessage =
            'Please enter your password.';
      });

      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // --------------------------------------------------------
      // TRY NORMAL ONLINE LOGIN FIRST
      // --------------------------------------------------------

      final result =
          await ApiService.login(
        login: identifier,
        password: password,
      );

      final rawUser =
          result['user'];

      if (rawUser is! Map) {
        if (!mounted) {
          return;
        }

        setState(() {
          errorMessage =
              'Login succeeded, but user information '
              'was not returned correctly.';
        });

        return;
      }

      final user =
          Map<String, dynamic>.from(
        rawUser,
      );

      final role =
          user['role']
              ?.toString()
              .trim()
              .toUpperCase();

      // Save successful STUDENT credentials
      // for future offline login on this device.
      if (role == 'STUDENT') {
        await OfflineAuthService
            .saveStudentLogin(
          identifier: identifier,
          password: password,
          user: user,
        );
      }

      if (!mounted) {
        return;
      }

      openDashboard(
        user,
        offlineLogin: false,
      );
    } on SmartLogAuthenticationException
        catch (e) {
      // Laravel responded, therefore this is an
      // authentication problem rather than an
      // offline/network problem.

      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.message;
      });
    } on SmartLogNetworkException {
      // --------------------------------------------------------
      // SERVER UNAVAILABLE
      // TRY STUDENT OFFLINE LOGIN
      // --------------------------------------------------------

      final offlineUser =
          await OfflineAuthService
              .authenticateOffline(
        identifier: identifier,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (offlineUser == null) {
        setState(() {
          errorMessage =
              'SmartLog server is unavailable. '
              'Offline login is available only after '
              'this student has successfully signed '
              'in online on this device.';
        });

        return;
      }

      final role =
          offlineUser['role']
              ?.toString()
              .trim()
              .toUpperCase();

      if (role != 'STUDENT') {
        setState(() {
          errorMessage =
              'Offline login is currently available '
              'only for students.';
        });

        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Offline login successful. '
            'SmartLog is using data stored '
            'on this device.',
          ),
        ),
      );

      openDashboard(
        offlineUser,
        offlineLogin: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Unable to complete login: $e';
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

  void openDashboard(
    Map<String, dynamic> user, {
    required bool offlineLogin,
  }) {
    final role =
        user['role']
            ?.toString()
            .trim()
            .toUpperCase();

    if (role == 'STUDENT') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StudentHomeScreen(
            user: user,
          ),
        ),
      );

      return;
    }

    if (offlineLogin) {
      setState(() {
        errorMessage =
            'Offline login is currently available '
            'only for students.';
      });

      return;
    }

    if (role == 'LECTURER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LecturerHomeScreen(
            user: user,
          ),
        ),
      );

      return;
    }

    if (role == 'HOD') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HodHomeScreen(
            user: user,
          ),
        ),
      );

      return;
    }

    if (role == 'ICT_ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminHomeScreen(
            user: user,
          ),
        ),
      );

      return;
    }

    setState(() {
      errorMessage =
          'This SmartLog user role is '
          'not currently supported.';
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
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return Center(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 460,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // ========================================
                      // DWU LOGO
                      // ========================================

                      Container(
                        width: 112,
                        height: 112,
                        padding:
                            const EdgeInsets.all(
                          8,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          shape:
                              BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.10,
                              ),
                              blurRadius: 18,
                              offset:
                                  const Offset(
                                0,
                                6,
                              ),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/dwu_logo.jpg',
                            fit:
                                BoxFit.contain,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Icon(
                                Icons
                                    .school_rounded,
                                size: 60,
                                color:
                                    colorScheme
                                        .primary,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ========================================
                      // SMARTLOG TITLE
                      // ========================================

                      Text(
                        'SmartLog',
                        textAlign:
                            TextAlign.center,
                        style:
                            theme.textTheme
                                .headlineLarge
                                ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              -0.5,
                          color:
                              colorScheme
                                  .primary,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        'DWU Digital Clinical Logbook',
                        textAlign:
                            TextAlign.center,
                        style:
                            theme.textTheme
                                .titleMedium
                                ?.copyWith(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Clinical placement recording, '
                        'verification and progress tracking '
                        'with online and offline support.',
                        textAlign:
                            TextAlign.center,
                        style:
                            theme.textTheme
                                .bodyMedium
                                ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // ========================================
                      // LOGIN CARD
                      // ========================================

                      Card(
                        elevation: 3,
                        shadowColor:
                            Colors.black
                                .withValues(
                          alpha: 0.12,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                            children: [
                              Text(
                                'Sign In',
                                style: theme
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                'Use your DWU account '
                                'details to continue.',
                                style: theme
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(
                                height: 22,
                              ),

                              // ==================================
                              // DWU ID / EMAIL
                              // ==================================

                              TextField(
                                controller:
                                    loginController,
                                enabled:
                                    !loading,
                                keyboardType:
                                    TextInputType
                                        .emailAddress,
                                textInputAction:
                                    TextInputAction
                                        .next,
                                autofillHints:
                                    const [
                                  AutofillHints
                                      .username,
                                  AutofillHints
                                      .email,
                                ],
                                decoration:
                                    InputDecoration(
                                  labelText:
                                      'DWU ID or Email',
                                  hintText:
                                      'Enter your DWU ID or email',
                                  prefixIcon:
                                      const Icon(
                                    Icons
                                        .person_outline_rounded,
                                  ),
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              // ==================================
                              // PASSWORD
                              // ==================================

                              TextField(
                                controller:
                                    passwordController,
                                enabled:
                                    !loading,
                                obscureText:
                                    obscurePassword,
                                textInputAction:
                                    TextInputAction
                                        .done,
                                autofillHints:
                                    const [
                                  AutofillHints
                                      .password,
                                ],
                                onSubmitted: (_) {
                                  if (!loading) {
                                    login();
                                  }
                                },
                                decoration:
                                    InputDecoration(
                                  labelText:
                                      'Password',
                                  hintText:
                                      'Enter your password',
                                  prefixIcon:
                                      const Icon(
                                    Icons
                                        .lock_outline_rounded,
                                  ),
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  suffixIcon:
                                      IconButton(
                                    tooltip:
                                        obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                    onPressed:
                                        loading
                                            ? null
                                            : () {
                                                setState(
                                                  () {
                                                    obscurePassword =
                                                        !obscurePassword;
                                                  },
                                                );
                                              },
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons
                                              .visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                                                            // ==================================
                              // ERROR MESSAGE
                              // ==================================

                              if (errorMessage != null) ...[
                                const SizedBox(
                                  height: 16,
                                ),

                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.red
                                        .withValues(
                                      alpha: 0.07,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                    border: Border.all(
                                      color: Colors.red
                                          .withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(
                                        width: 9,
                                      ),
                                      Expanded(
                                        child: Text(
                                          errorMessage!,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.red,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 22,
                              ),

                              // ==================================
                              // SIGN IN BUTTON
                              // ==================================

                              SizedBox(
                                height: 54,
                                child:
                                    FilledButton.icon(
                                  onPressed:
                                      loading
                                          ? null
                                          : login,
                                  style:
                                      FilledButton.styleFrom(
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12,
                                      ),
                                    ),
                                  ),
                                  icon: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .login_rounded,
                                        ),
                                  label: Text(
                                    loading
                                        ? 'Signing in...'
                                        : 'Sign In',
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ========================================
                      // OFFLINE SUPPORT INFORMATION
                      // ========================================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.blue
                              .withValues(
                            alpha: 0.06,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          border: Border.all(
                            color: Colors.blue
                                .withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons
                                  .offline_bolt_outlined,
                              size: 23,
                            ),
                            SizedBox(
                              width: 11,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Offline Support',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Students who have '
                                    'previously signed in '
                                    'online on this device '
                                    'can continue using '
                                    'SmartLog when the '
                                    'server is unavailable.',
                                    style:
                                        TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ========================================
                      // DWU FOOTER
                      // ========================================

                      Text(
                        'Divine Word University',
                        textAlign:
                            TextAlign.center,
                        style:
                            theme.textTheme
                                .bodyMedium
                                ?.copyWith(
                          fontWeight:
                              FontWeight.w600,
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'SmartLog Clinical Placement System',
                        textAlign:
                            TextAlign.center,
                        style:
                            theme.textTheme
                                .bodySmall
                                ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}