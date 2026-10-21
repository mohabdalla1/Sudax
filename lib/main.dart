import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const SudaxApp());
  } catch (_) {
    runApp(const StartupErrorApp());
  }
}

const brandBlue = Color(0xFF2258D8);
const ink = Color(0xFF17213A);
const pageBackground = Color(0xFFF5F7FC);

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const InfoCard(
                icon: Icons.settings_suggest_outlined,
                title: 'تعذر تشغيل Sudax',
                subtitle:
                    'تحقق من إعدادات Firebase في firebase_options.dart ثم أعد تشغيل الموقع.\n\nFirebase configuration is missing or could not be initialized.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SudaxApp extends StatefulWidget {
  const SudaxApp({super.key});

  @override
  State<SudaxApp> createState() => _SudaxAppState();
}

class _SudaxAppState extends State<SudaxApp> {
  Locale locale = const Locale('ar');

  void changeLocale(Locale value) => setState(() => locale = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudax',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
        scaffoldBackgroundColor: pageBackground,
        useMaterial3: true,
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E6F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E6F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: brandBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: SudaxRoot(
        locale: locale,
        onLocaleChanged: changeLocale,
      ),
    );
  }
}

class SudaxRoot extends StatelessWidget {
  const SudaxRoot({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return AuthPage(
              locale: locale,
              onLocaleChanged: onLocaleChanged,
            );
          }

          return DashboardPage(
            user: user,
            locale: locale,
            onLocaleChanged: onLocaleChanged,
          );
        },
      ),
    );
  }
}

String tr(Locale locale, String ar, String en) {
  return locale.languageCode == 'ar' ? ar : en;
}

String authErrorMessage(Locale locale, FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return tr(locale, 'هذا البريد مسجل مسبقاً.', 'This email is already registered.');
    case 'invalid-email':
      return tr(locale, 'صيغة البريد الإلكتروني غير صحيحة.', 'The email address is invalid.');
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return tr(locale, 'البريد أو كلمة المرور غير صحيحة.', 'Email or password is incorrect.');
    case 'weak-password':
      return tr(locale, 'كلمة المرور ضعيفة؛ استخدم ستة أحرف على الأقل.', 'Password is too weak; use at least 6 characters.');
    case 'network-request-failed':
      return tr(locale, 'تعذر الاتصال بالإنترنت.', 'A network connection could not be established.');
    case 'too-many-requests':
      return tr(locale, 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.', 'Too many attempts. Please wait and try again.');
    case 'user-disabled':
      return tr(locale, 'هذا الحساب معطّل. تواصل مع الإدارة.', 'This account has been disabled. Contact the administrator.');
    default:
      return tr(locale, 'تعذر إكمال العملية. تحقق من إعدادات Firebase.', 'The operation failed. Check the Firebase configuration.');
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isSignUp = false;
  bool busy = false;
  bool passwordVisible = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      errorMessage = null;
    });

    final auth = FirebaseAuth.instance;
    try {
      if (isSignUp) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        final user = credential.user;
        if (user == null) {
          throw StateError('Firebase did not return a new user.');
        }

        await user.updateDisplayName(nameController.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': emailController.text.trim(),
          'displayName': nameController.text.trim(),
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => errorMessage = authErrorMessage(widget.locale, error));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = tr(
            widget.locale,
            'تعذر إنشاء الملف الشخصي. تحقق من اتصال Firebase وقواعد Firestore.',
            'Could not save the user profile. Check Firebase connectivity and Firestore rules.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorMessage = tr(
          widget.locale,
          'أدخل بريدك الإلكتروني الصحيح أولاً، ثم اضغط «نسيت كلمة المرور؟».',
          'Enter a valid email address first, then choose “Forgot password?”.',
        );
      });
      return;
    }

    setState(() {
      busy = true;
      errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            widget.locale,
            'إذا كان البريد مسجلاً، فستصلك رسالة لإعادة تعيين كلمة المرور.',
            'If the email is registered, a password-reset message will be sent.',
          )),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => errorMessage = authErrorMessage(widget.locale, error));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final wide = MediaQuery.sizeOf(context).width > 760;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x100D1B3D),
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (wide)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(44),
                        constraints: const BoxConstraints(minHeight: 600),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E4EC6), Color(0xFF102C78)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Brand(white: true),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(locale, 'حوّل أفكارك إلى', 'Turn your ideas into'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  tr(locale, 'مشاريع ملموسة.', 'real projects.'),
                                  style: const TextStyle(
                                    color: Color(0xFFBFD0FF),
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  tr(
                                    locale,
                                    'مساحة واحدة لطلباتك ومشاريعك والتواصل مع فريق التطوير.',
                                    'One place for your requests, projects, and collaboration with your development team.',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.7,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                FeatureLine(
                                  icon: Icons.dashboard_customize_outlined,
                                  textAr: 'متابعة واضحة لتقدم المشاريع',
                                  textEn: 'Clear project progress',
                                  locale: locale,
                                ),
                                const SizedBox(height: 12),
                                FeatureLine(
                                  icon: Icons.code_rounded,
                                  textAr: 'خدمات رقمية تناسب فكرتك',
                                  textEn: 'Digital services for your idea',
                                  locale: locale,
                                ),
                              ],
                            ),
                            const Text(
                              'SUDAX STUDIO  •  © 2026',
                              style: TextStyle(
                                color: Colors.white60,
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 48 : 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                if (!wide) const Brand(),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => widget.onLocaleChanged(
                                            Locale(locale.languageCode == 'ar' ? 'en' : 'ar'),
                                          ),
                                  icon: const Icon(Icons.language),
                                  label: Text(tr(locale, 'English', 'العربية')),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Text(
                              tr(
                                locale,
                                isSignUp ? 'إنشاء حساب جديد' : 'مرحباً بعودتك',
                                isSignUp ? 'Create your account' : 'Welcome back',
                              ),
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr(
                                locale,
                                'سجّل الدخول لإدارة مشاريعك وطلباتك.',
                                'Sign in to manage your projects and requests.',
                              ),
                              style: const TextStyle(color: Color(0xFF737D92)),
                            ),
                            const SizedBox(height: 28),
                            if (isSignUp) ...[
                              Text(tr(locale, 'الاسم الكامل', 'Full name')),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: tr(locale, 'اكتب اسمك', 'Your name'),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty
                                    ? tr(locale, 'أدخل اسمك', 'Enter your name')
                                    : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(tr(locale, 'البريد الإلكتروني', 'Email address')),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'name@example.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (value) => value == null || !value.trim().contains('@')
                                  ? tr(locale, 'أدخل بريداً صحيحاً', 'Enter a valid email')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(tr(locale, 'كلمة المرور', 'Password')),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: !passwordVisible,
                              autofillHints: isSignUp
                                  ? const [AutofillHints.newPassword]
                                  : const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => submit(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: tr(locale, 'إظهار أو إخفاء كلمة المرور', 'Show or hide password'),
                                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                                  icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                              validator: (value) => value == null || value.length < 6
                                  ? tr(locale, 'ستة أحرف على الأقل', 'At least 6 characters')
                                  : null,
                            ),
                            if (!isSignUp)
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: busy ? null : resetPassword,
                                  child: Text(tr(locale, 'نسيت كلمة المرور؟', 'Forgot password?')),
                                ),
                              ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Color(0xFFB42318)),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: busy ? null : submit,
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  tr(
                                    locale,
                                    busy
                                        ? 'يرجى الانتظار...'
                                        : isSignUp
                                            ? 'إنشاء الحساب'
                                            : 'تسجيل الدخول',
                                    busy
                                        ? 'Please wait...'
                                        : isSignUp
                                            ? 'Create account'
                                            : 'Sign in',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                        isSignUp = !isSignUp;
                                        errorMessage = null;
                                        passwordVisible = false;
                                      }),
                              child: Text(
                                tr(
                                  locale,
                                  isSignUp ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حساباً',
                                  isSignUp ? 'Already have an account? Sign in' : 'New here? Create an account',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr(
                                locale,
                                'الحسابات الجديدة تحصل على صلاحية العميل فقط.',
                                'New accounts receive the client role only.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF7A8497),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.user,
    required this.locale,
    required this.onLocaleChanged,
  });

  final User user;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  Future<void> requestProject(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'web';

    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(tr(locale, 'طلب مشروع جديد', 'New project request')),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: tr(locale, 'عنوان المشروع', 'Project title'),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? tr(locale, 'هذا الحقل مطلوب', 'This field is required')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: InputDecoration(
                          labelText: tr(locale, 'نوع الخدمة', 'Service type'),
                        ),
                        items: [
                          DropdownMenuItem(value: 'web', child: Text(tr(locale, 'موقع إلكتروني', 'Website'))),
                          DropdownMenuItem(value: 'mobile', child: Text(tr(locale, 'تطبيق هاتف', 'Mobile app'))),
                          DropdownMenuItem(value: 'design', child: Text(tr(locale, 'تصميم واجهات', 'UI/UX design'))),
                          DropdownMenuItem(value: 'other', child: Text(tr(locale, 'خدمة أخرى', 'Other service'))),
                        ],
                        onChanged: (value) => setDialogState(() => type = value ?? 'web'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: tr(locale, 'وصف المشروع', 'Project description'),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? tr(locale, 'اكتب وصفاً مختصراً', 'Please add a description')
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(tr(locale, 'إلغاء', 'Cancel')),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, {
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'serviceType': type,
                    });
                  }
                },
                child: Text(tr(locale, 'إرسال الطلب', 'Submit request')),
              ),
            ],
          ),
        ),
      );

      if (result == null) return;
      await FirebaseFirestore.instance.collection('projects').add({
        'title': result['title'],
        'description': result['description'],
        'serviceType': result['serviceType'],
        'status': 'requested',
        'clientId': user.uid,
        'developerIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(locale, 'تم إرسال طلب المشروع بنجاح.', 'Project request submitted successfully.'))),
        );
      }
    } on FirebaseException catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(locale, 'تعذر إرسال الطلب. تحقق من اتصال Firebase وصلاحيات قاعدة البيانات.', 'Could not submit the request. Check Firebase connectivity and database permissions.'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(locale, 'حدث خطأ غير متوقع أثناء إرسال الطلب.', 'An unexpected error occurred while submitting the request.'))),
        );
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  Query<Map<String, dynamic>> projectQueryForRole(String role) {
    final collection = FirebaseFirestore.instance.collection('projects');
    if (role == 'client') {
      return collection
          .where('clientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);
    }
    if (role == 'developer') {
      return collection
          .where('developerIds', arrayContains: user.uid)
          .orderBy('createdAt', descending: true);
    }
    return collection.orderBy('createdAt', descending: true);
  }

  Future<void> showProjectDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final title = data['title'] as String? ?? tr(locale, 'طلب دون عنوان', 'Untitled request');
    final description = data['description'] as String? ?? '';
    final status = data['status'] as String? ?? 'requested';
    final service = data['serviceType'] as String? ?? 'other';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(statusLabel(locale, status))),
                    Chip(label: Text(serviceLabel(locale, service))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(tr(locale, 'وصف المشروع', 'Project description'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                SelectableText(description.isEmpty ? tr(locale, 'لا يوجد وصف.', 'No description provided.') : description),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(locale, 'إغلاق', 'Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Brand()),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: InfoCard(
                  icon: Icons.lock_outline,
                  title: tr(locale, 'تعذر تحميل الملف الشخصي', 'Could not load the user profile'),
                  subtitle: tr(locale, 'تحقق من قواعد Firestore ثم أعد المحاولة.', 'Check Firestore rules and try again.'),
                ),
              ),
            ),
          );
        }
        if (profileSnapshot.connectionState == ConnectionState.waiting && !profileSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profile = profileSnapshot.data?.data();
        final role = profile?['role'] as String? ?? 'client';
        final storedName = profile?['displayName'] as String?;
        final name = (storedName != null && storedName.trim().isNotEmpty)
            ? storedName.trim()
            : (user.displayName ?? user.email ?? 'Sudax');
        final wide = MediaQuery.sizeOf(context).width > 760;
        final projectsQuery = projectQueryForRole(role);

        return Scaffold(
          appBar: AppBar(
            title: const Brand(),
            actions: [
              TextButton.icon(
                onPressed: () => onLocaleChanged(Locale(locale.languageCode == 'ar' ? 'en' : 'ar')),
                icon: const Icon(Icons.language),
                label: Text(tr(locale, 'English', 'العربية')),
              ),
              IconButton(
                tooltip: tr(locale, 'تسجيل الخروج', 'Sign out'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: EdgeInsets.all(wide ? 32 : 18),
                children: [
                  Container(
                    padding: EdgeInsets.all(wide ? 30 : 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F4FC7), Color(0xFF2B70E8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(locale, 'مساحة العمل', 'WORKSPACE'),
                          style: const TextStyle(color: Colors.white70, letterSpacing: 1.3, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(locale, 'مرحباً، $name', 'Welcome, $name'),
                          style: TextStyle(color: Colors.white, fontSize: wide ? 30 : 23, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(locale, 'تابع مشاريعك واطّلع على آخر التحديثات من مكان واحد.', 'Track your projects and updates in one place.'),
                          style: const TextStyle(color: Colors.white70, height: 1.6),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.verified_user_outlined, size: 17),
                              label: Text(roleLabel(locale, role)),
                              backgroundColor: Colors.white,
                            ),
                            if (user.email != null)
                              Chip(
                                avatar: const Icon(Icons.alternate_email, size: 16),
                                label: Text(user.email!, overflow: TextOverflow.ellipsis),
                                backgroundColor: Colors.white,
                              ),
                          ],
                        ),
                        if (role == 'client') ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brandBlue),
                              onPressed: () => requestProject(context),
                              icon: const Icon(Icons.add),
                              label: Text(tr(locale, 'طلب مشروع', 'Request a project')),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(locale, 'المشاريع والطلبات', 'Projects & requests'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink),
                        ),
                      ),
                      if (role == 'client')
                        IconButton.filledTonal(
                          tooltip: tr(locale, 'طلب مشروع جديد', 'New project request'),
                          onPressed: () => requestProject(context),
                          icon: const Icon(Icons.add),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: projectsQuery.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return InfoCard(
                          icon: Icons.cloud_off_outlined,
                          title: tr(locale, 'تعذر تحميل المشاريع', 'Could not load projects'),
                          subtitle: tr(locale, 'تحقق من قواعد Firestore والفهارس المركبة المطلوبة في Firebase Console.', 'Check Firestore rules and required composite indexes in Firebase Console.'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final documents = snapshot.data?.docs ?? [];
                      if (documents.isEmpty) {
                        return InfoCard(
                          icon: Icons.folder_open_outlined,
                          title: tr(locale, 'لا توجد مشاريع بعد', 'No projects yet'),
                          subtitle: tr(
                            locale,
                            role == 'client' ? 'أرسل طلبك الأول وسيظهر هنا.' : 'المشاريع المسندة إليك ستظهر هنا.',
                            role == 'client' ? 'Submit your first request and it will appear here.' : 'Projects assigned to you will appear here.',
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth > 820 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: documents.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              mainAxisExtent: 220,
                            ),
                            itemBuilder: (context, index) {
                              final document = documents[index];
                              final data = document.data();
                              final status = data['status'] as String? ?? 'requested';
                              final title = data['title'] as String? ?? tr(locale, 'طلب دون عنوان', 'Untitled request');
                              final description = data['description'] as String? ?? '';
                              final service = data['serviceType'] as String? ?? 'other';
                              return ProjectCard(
                                title: title,
                                description: description,
                                status: status,
                                service: service,
                                locale: locale,
                                onTap: () => showProjectDetails(context, data),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr(locale, 'Sudax — فكرتك، شيفرتنا.', 'Sudax — Your vision, our code.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF8A94A8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.service,
    required this.locale,
    required this.onTap,
  });

  final String title;
  final String description;
  final String status;
  final String service;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Card(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7EAF2)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_copy_outlined, color: brandBlue),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusLabel(locale, status),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: ink),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF727D92), height: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      serviceLabel(locale, service),
                      style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.white = false});

  final bool white;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: white ? Colors.white.withOpacity(.15) : brandBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.layers_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sudax',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: white ? Colors.white : ink,
                letterSpacing: -.5,
              ),
            ),
            Text(
              'YOUR VISION, OUR CODE',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.1,
                color: white ? Colors.white70 : const Color(0xFF758098),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FeatureLine extends StatelessWidget {
  const FeatureLine({
    super.key,
    required this.icon,
    required this.textAr,
    required this.textEn,
    required this.locale,
  });

  final IconData icon;
  final String textAr;
  final String textEn;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFBFD0FF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr(locale, textAr, textEn),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAF2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: brandBlue),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF778196), height: 1.5),
          ),
        ],
      ),
    );
  }
}

String roleLabel(Locale locale, String role) {
  switch (role) {
    case 'admin':
      return tr(locale, 'مدير', 'Administrator');
    case 'developer':
      return tr(locale, 'مطوّر', 'Developer');
    default:
      return tr(locale, 'عميل', 'Client');
  }
}

String statusLabel(Locale locale, String status) {
  switch (status) {
    case 'in_progress':
      return tr(locale, 'قيد التنفيذ', 'In progress');
    case 'review':
      return tr(locale, 'قيد المراجعة', 'In review');
    case 'completed':
      return tr(locale, 'مكتمل', 'Completed');
    case 'cancelled':
      return tr(locale, 'ملغي', 'Cancelled');
    default:
      return tr(locale, 'طلب جديد', 'Requested');
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'in_progress':
      return const Color(0xFF2E70D1);
    case 'review':
      return const Color(0xFF9A6700);
    case 'completed':
      return const Color(0xFF16845B);
    case 'cancelled':
      return const Color(0xFFB42318);
    default:
      return const Color(0xFF6D7587);
  }
}

String serviceLabel(Locale locale, String service) {
  switch (service) {
    case 'web':
      return tr(locale, 'موقع إلكتروني', 'Website');
    case 'mobile':
      return tr(locale, 'تطبيق هاتف', 'Mobile app');
    case 'design':
      return tr(locale, 'تصميم واجهات', 'UI/UX design');
    default:
      return tr(locale, 'خدمات أخرى', 'Other service');
  }
}
