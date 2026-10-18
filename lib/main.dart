import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SudaxApp());
}

const brandBlue = Color(0xFF2258D8);
const ink = Color(0xFF17213A);

class SudaxApp extends StatefulWidget {
  const SudaxApp({super.key});
  @override
  State<SudaxApp> createState() => _SudaxAppState();
}

class _SudaxAppState extends State<SudaxApp> {
  Locale locale = const Locale('ar');
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sudax', debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: brandBlue), scaffoldBackgroundColor: const Color(0xFFF5F7FC), useMaterial3: true, fontFamily: 'Arial', inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE1E6F0))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE1E6F0))), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
        home: SudaxRoot(locale: locale, onLocaleChanged: (value) => setState(() => locale = value)),
      );
}

class SudaxRoot extends StatelessWidget {
  const SudaxRoot({super.key, required this.locale, required this.onLocaleChanged});
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = snapshot.data;
    if (user == null) return AuthPage(locale: locale, onLocaleChanged: onLocaleChanged);
    return DashboardPage(user: user, locale: locale, onLocaleChanged: onLocaleChanged);
  }));
}

String tr(Locale l, String ar, String en) => l.languageCode == 'ar' ? ar : en;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.locale, required this.onLocaleChanged});
  final Locale locale; final ValueChanged<Locale> onLocaleChanged;
  @override State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>(); final name = TextEditingController(); final email = TextEditingController(); final password = TextEditingController();
  bool signup = false, busy = false; String? error;
  @override void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (signup) {
        final cred = await auth.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
        await cred.user?.updateDisplayName(name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({'uid': cred.user!.uid, 'email': email.text.trim(), 'displayName': name.text.trim(), 'role': 'client', 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await auth.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = switch (e.code) { 'email-already-in-use' => tr(widget.locale, 'هذا البريد مسجل مسبقاً', 'This email is already registered'), 'invalid-credential' || 'wrong-password' || 'user-not-found' => tr(widget.locale, 'البريد أو كلمة المرور غير صحيحة', 'Email or password is incorrect'), 'weak-password' => tr(widget.locale, 'كلمة المرور ضعيفة', 'Password is too weak'), _ => tr(widget.locale, 'تعذر تسجيل الدخول. تحقق من الإعدادات والاتصال.', 'Could not sign in. Check configuration and connection.') });
    } catch (_) { setState(() => error = tr(widget.locale, 'تعذر إنشاء الملف الشخصي. تحقق من قواعد Firestore.', 'Could not create profile. Check Firestore rules.')); }
    if (mounted) setState(() => busy = false);
  }
  @override Widget build(BuildContext context) {
    final l = widget.locale; final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x100D1B3D), blurRadius: 32, offset: Offset(0, 12))]), clipBehavior: Clip.antiAlias, child: Flex(direction: wide ? Axis.horizontal : Axis.vertical, mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min, children: [
      if (wide) Expanded(child: Container(padding: const EdgeInsets.all(44), constraints: const BoxConstraints(minHeight: 580), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E4EC6), Color(0xFF102C78)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Brand(white: true), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(l, 'حوّل أفكارك إلى', 'Turn your ideas into'), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)), Text(tr(l, 'مشاريع ملموسة.', 'real projects.'), style: const TextStyle(color: Color(0xFFBFD0FF), fontSize: 34, fontWeight: FontWeight.w800)), const SizedBox(height: 18), Text(tr(l, 'مساحة واحدة لطلباتك ومشاريعك والتواصل مع فريق التطوير.', 'One place for your requests, projects, and collaboration with your development team.'), style: const TextStyle(color: Colors.white70, height: 1.7, fontSize: 16)), const SizedBox(height: 28), const FeatureLine(icon: Icons.dashboard_customize_outlined, textAr: 'متابعة واضحة لتقدم المشاريع', textEn: 'Clear project progress'), const SizedBox(height: 12), const FeatureLine(icon: Icons.code_rounded, textAr: 'خدمات رقمية تناسب فكرتك', textEn: 'Digital services for your idea')]), const Text('SUDAX STUDIO  •  © 2026', style: TextStyle(color: Colors.white60, letterSpacing: 1.2, fontSize: 11))])) ,
      Flexible(fit: FlexFit.loose, child: Padding(padding: EdgeInsets.all(wide ? 48 : 24), child: Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [if (!wide) const Brand(), const Spacer(), TextButton.icon(onPressed: () => widget.onLocaleChanged(Locale(l.languageCode == 'ar' ? 'en' : 'ar')), icon: const Icon(Icons.language), label: Text(tr(l, 'English', 'العربية')))]), const SizedBox(height: 28), Text(tr(l, signup ? 'إنشاء حساب جديد' : 'مرحباً بعودتك', signup ? 'Create your account' : 'Welcome back'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 8), Text(tr(l, 'سجّل الدخول لإدارة مشاريعك وطلباتك.', 'Sign in to manage your projects and requests.'), style: const TextStyle(color: Color(0xFF737D92))), const SizedBox(height: 28), if (signup) ...[Text(tr(l, 'الاسم الكامل', 'Full name')), const SizedBox(height: 8), TextFormField(controller: name, validator: (v) => (v == null || v.trim().isEmpty) ? tr(l, 'أدخل اسمك', 'Enter your name') : null, textInputAction: TextInputAction.next), const SizedBox(height: 16)], Text(tr(l, 'البريد الإلكتروني', 'Email address')), const SizedBox(height: 8), TextFormField(controller: email, keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || !v.contains('@')) ? tr(l, 'أدخل بريداً صحيحاً', 'Enter a valid email') : null, textInputAction: TextInputAction.next), const SizedBox(height: 16), Text(tr(l, 'كلمة المرور', 'Password')), const SizedBox(height: 8), TextFormField(controller: password, obscureText: true, validator: (v) => (v == null || v.length < 6) ? tr(l, 'ستة أحرف على الأقل', 'At least 6 characters') : null, onFieldSubmitted: (_) => submit()), if (error != null) ...[const SizedBox(height: 14), Text(error!, style: const TextStyle(color: Colors.red))], const SizedBox(height: 22), FilledButton.icon(onPressed: busy ? null : submit, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward_rounded), label: Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(tr(l, busy ? 'يرجى الانتظار...' : signup ? 'إنشاء الحساب' : 'تسجيل الدخول', busy ? 'Please wait...' : signup ? 'Create account' : 'Sign in')))), const SizedBox(height: 14), TextButton(onPressed: () => setState(() { signup = !signup; error = null; }), child: Text(tr(l, signup ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حساباً', signup ? 'Already have an account? Sign in' : 'New here? Create an account'))), const SizedBox(height: 12), Text(tr(l, 'الحسابات الجديدة تحصل على صلاحية العميل فقط.', 'New accounts receive the client role only.'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7A8497), fontSize: 12))])))]))));
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user, required this.locale, required this.onLocaleChanged});
  final User user; final Locale locale; final ValueChanged<Locale> onLocaleChanged;
  Future<void> requestProject(BuildContext context) async {
    final key = GlobalKey<FormState>(); final title = TextEditingController(); final desc = TextEditingController(); String type = 'web';
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(title: Text(tr(locale, 'طلب مشروع جديد', 'New project request')), content: SizedBox(width: 440, child: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: title, decoration: InputDecoration(labelText: tr(locale, 'عنوان المشروع', 'Project title')), validator: (v) => v == null || v.trim().isEmpty ? tr(locale, 'هذا الحقل مطلوب', 'Required') : null), const SizedBox(height: 12), DropdownButtonFormField<String>(value: type, decoration: InputDecoration(labelText: tr(locale, 'نوع الخدمة', 'Service type')), items: [DropdownMenuItem(value: 'web', child: Text(tr(locale, 'موقع إلكتروني', 'Website'))), DropdownMenuItem(value: 'mobile', child: Text(tr(locale, 'تطبيق هاتف', 'Mobile app'))), DropdownMenuItem(value: 'design', child: Text(tr(locale, 'تصميم واجهات', 'UI/UX design'))), DropdownMenuItem(value: 'other', child: Text(tr(locale, 'أخرى', 'Other')))], onChanged: (v) => setLocal(() => type = v ?? 'web')), const SizedBox(height: 12), TextFormField(controller: desc, minLines: 3, maxLines: 5, decoration: InputDecoration(labelText: tr(locale, 'وصف المشروع', 'Project description')), validator: (v) => v == null || v.trim().isEmpty ? tr(locale, 'اكتب وصفاً مختصراً', 'Please add a description') : null)]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(locale, 'إلغاء', 'Cancel'))), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(ctx, true); }, child: Text(tr(locale, 'إرسال الطلب', 'Submit request')))]));
    if (result == true) { await FirebaseFirestore.instance.collection('projects').add({'title': title.text.trim(), 'description': desc.text.trim(), 'serviceType': type, 'status': 'requested', 'clientId': user.uid, 'developerIds': <String>[], 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}); }
    title.dispose(); desc.dispose();
  }
  @override Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(), builder: (context, profileSnap) {
    final profile = profileSnap.data?.data(); final role = profile?['role'] as String? ?? 'client'; final name = (profile?['displayName'] as String?)?.trim().isNotEmpty == true ? profile!['displayName'] as String : (user.displayName ?? user.email ?? 'Sudax');
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('projects').orderBy('createdAt', descending: true);
    if (role == 'client') q = q.where('clientId', isEqualTo: user.uid).orderBy('createdAt', descending: true);
    if (role == 'developer') q = q.where('developerIds', arrayContains: user.uid).orderBy('createdAt', descending: true);
    final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: const Brand(), actions: [TextButton.icon(onPressed: () => onLocaleChanged(Locale(locale.languageCode == 'ar' ? 'en' : 'ar')), icon: const Icon(Icons.language), label: Text(tr(locale, 'English', 'العربية'))), IconButton(tooltip: tr(locale, 'تسجيل الخروج', 'Sign out'), onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)), const SizedBox(width: 12)]), body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: ListView(padding: EdgeInsets.all(wide ? 32 : 18), children: [Container(padding: EdgeInsets.all(wide ? 30 : 22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1F4FC7), Color(0xFF2B70E8)]), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(locale, 'مساحة العمل', 'WORKSPACE'), style: const TextStyle(color: Colors.white70, letterSpacing: 1.3, fontSize: 11)), const SizedBox(height: 12), Text(tr(locale, 'مرحباً، $name', 'Welcome, $name'), style: TextStyle(color: Colors.white, fontSize: wide ? 30 : 23, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(tr(locale, 'تابع مشاريعك واطّلع على آخر التحديثات من مكان واحد.', 'Track your projects and updates in one place.'), style: const TextStyle(color: Colors.white70, height: 1.6)), const SizedBox(height: 18), Wrap(spacing: 8, runSpacing: 8, children: [Chip(avatar: const Icon(Icons.verified_user_outlined, size: 17), label: Text(roleLabel(locale, role)), backgroundColor: Colors.white)]), if (role == 'client') Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brandBlue), onPressed: () => requestProject(context), icon: const Icon(Icons.add), label: Text(tr(locale, 'طلب مشروع', 'Request a project')))] )]), const SizedBox(height: 26), Row(children: [Expanded(child: Text(tr(locale, 'المشاريع والطلبات', 'Projects & requests'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink))), if (role == 'client') IconButton.filledTonal(onPressed: () => requestProject(context), icon: const Icon(Icons.add))]), const SizedBox(height: 12), StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: q.snapshots(), builder: (context, snap) { if (snap.hasError) return InfoCard(icon: Icons.lock_outline, title: tr(locale, 'تعذر تحميل المشاريع', 'Could not load projects'), subtitle: tr(locale, 'تحقق من قواعد Firestore والفهارس المطلوبة في Firebase Console.', 'Check Firestore rules and any required indexes in Firebase Console.')); if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())); final docs = snap.data?.docs ?? []; if (docs.isEmpty) return InfoCard(icon: Icons.folder_open_outlined, title: tr(locale, 'لا توجد مشاريع بعد', 'No projects yet'), subtitle: tr(locale, role == 'client' ? 'أرسل طلبك الأول وسيظهر هنا.' : 'Projects assigned to you will appear here.')); return LayoutBuilder(builder: (context, constraints) { final cols = constraints.maxWidth > 820 ? 2 : 1; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: docs.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 210), itemBuilder: (context, i) { final data = docs[i].data(); final status = data['status'] as String? ?? 'requested'; return Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE7EAF2))), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.folder_copy_outlined, color: brandBlue), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor(status).withOpacity(.10), borderRadius: BorderRadius.circular(30)), child: Text(statusLabel(locale, status), style: TextStyle(color: statusColor(status), fontSize: 12, fontWeight: FontWeight.w700)))]), const SizedBox(height: 12), Text(data['title'] as String? ?? tr(locale, 'طلب دون عنوان', 'Untitled request'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: ink)), const SizedBox(height: 7), Text(data['description'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF727D92), height: 1.5)), const Spacer(), Text(serviceLabel(locale, data['serviceType'] as String? ?? 'other'), style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w700, fontSize: 12))]))); }); }); })]))));
  });
}

class Brand extends StatelessWidget { const Brand({super.key, this.white = false}); final bool white; @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: white ? Colors.white.withOpacity(.15) : brandBlue, borderRadius: BorderRadius.circular(13)), child: Icon(Icons.layers_rounded, color: white ? Colors.white : Colors.white, size: 23)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sudax', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: white ? Colors.white : ink, letterSpacing: -.5)), Text('YOUR VISION, OUR CODE', style: TextStyle(fontSize: 8, letterSpacing: 1.1, color: white ? Colors.white70 : const Color(0xFF758098)))])]); }
class FeatureLine extends StatelessWidget { const FeatureLine({super.key, required this.icon, required this.textAr, required this.textEn}); final IconData icon; final String textAr, textEn; @override Widget build(BuildContext context) { final l = Localizations.localeOf(context); return Row(children: [Icon(icon, color: const Color(0xFFBFD0FF), size: 20), const SizedBox(width: 12), Text(tr(l, textAr, textEn), style: const TextStyle(color: Colors.white, fontSize: 14))]); } }
class InfoCard extends StatelessWidget { const InfoCard({super.key, required this.icon, required this.title, required this.subtitle}); final IconData icon; final String title, subtitle; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EAF2))), child: Column(children: [Icon(icon, size: 36, color: brandBlue), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF778196), height: 1.5))])); }
String roleLabel(Locale l, String r) => switch (r) { 'admin' => tr(l, 'مدير', 'Administrator'), 'developer' => tr(l, 'مطوّر', 'Developer'), _ => tr(l, 'عميل', 'Client') };
String statusLabel(Locale l, String s) => switch (s) { 'in_progress' => tr(l, 'قيد التنفيذ', 'In progress'), 'review' => tr(l, 'قيد المراجعة', 'In review'), 'completed' => tr(l, 'مكتمل', 'Completed'), _ => tr(l, 'طلب جديد', 'Requested') };
Color statusColor(String s) => switch (s) { 'in_progress' => const Color(0xFF2E70D1), 'review' => const Color(0xFF9A6700), 'completed' => const Color(0xFF16845B), _ => const Color(0xFF6D7587) };
String serviceLabel(Locale l, String s) => switch (s) { 'web' => tr(l, 'موقع إلكتروني', 'Website'), 'mobile' => tr(l, 'تطبيق هاتف', 'Mobile app'), 'design' => tr(l, 'تصميم واجهات', 'UI/UX design'), _ => tr(l, 'خدمات أخرى', 'Other service') };
