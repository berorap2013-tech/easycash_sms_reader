import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/sms_event.dart';
import 'services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const EasyCashSmsReaderApp());
}

class EasyCashSmsReaderApp extends StatelessWidget {
  const EasyCashSmsReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Cash SMS Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B2CBF)),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Supabase.instance.client.auth.currentSession == null
            ? const LoginScreen()
            : const SmsReaderScreen(),
      ),
    );
  }
}

class AppColors {
  static const bg = Color(0xFFF7F5FB);
  static const purple = Color(0xFF6B2CBF);
  static const blue = Color(0xFF209DDE);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
  static const text = Color(0xFF241C33);
  static const subText = Color(0xFF8B8793);
  static const border = Color(0xFFE9E5F2);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showSnack('اكتب البريد وكلمة المرور');
      return;
    }

    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: SmsReaderScreen())),
      );
    } catch (e) {
      showSnack('فشل تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, textDirection: TextDirection.rtl)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 22, offset: const Offset(0, 12))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.blue, AppColors.purple]),
                    ),
                    child: const Icon(Icons.sms_outlined, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 18),
                  const Text('Easy Cash SMS Reader', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.text), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('سجل دخول بنفس حساب Easy Cash لربط الرسائل بالحساب', style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  _input(emailController, 'البريد الإلكتروني', Icons.email_outlined, false),
                  const SizedBox(height: 14),
                  _input(passwordController, 'كلمة المرور', Icons.lock_outline, true),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('هذا التطبيق المرافق يحتاج صلاحية قراءة SMS على أندرويد فقط.', style: TextStyle(color: AppColors.subText, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.purple),
        filled: true,
        fillColor: const Color(0xFFF8F5FD),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.purple)),
      ),
    );
  }
}

class SmsReaderScreen extends StatefulWidget {
  const SmsReaderScreen({super.key});

  @override
  State<SmsReaderScreen> createState() => _SmsReaderScreenState();
}

class _SmsReaderScreenState extends State<SmsReaderScreen> {
  static const smsChannel = MethodChannel('easycash_sms_reader/sms');

  final supabase = Supabase.instance.client;
  final List<SmsEvent> events = [];
  final Set<String> syncedKeys = {};
  Timer? timer;
  bool permissionGranted = false;
  bool autoSync = true;
  bool loading = false;
  String statusText = 'جاهز';

  @override
  void initState() {
    super.initState();
    initReader();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> initReader() async {
    await requestSmsPermission();
    if (permissionGranted) {
      await loadMessages();
      timer = Timer.periodic(const Duration(seconds: 4), (_) => loadMessages(silent: true));
    }
  }

  Future<void> requestSmsPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      permissionGranted = status.isGranted;
      statusText = status.isGranted ? 'تم تفعيل قراءة الرسائل' : 'صلاحية الرسائل غير مفعلة';
    });
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (!permissionGranted) return;
    if (!silent) setState(() => loading = true);

    try {
      final raw = await smsChannel.invokeMethod<List<dynamic>>('getRecentSms', {'limit': 40});
      final parsed = (raw ?? [])
          .map((item) => parseNativeSms(Map<String, dynamic>.from(item as Map)))
          .where((event) => isWalletMessage(event.sender, event.body))
          .toList();

      for (final event in parsed) {
        if (!events.any((old) => old.key == event.key)) {
          events.insert(0, event);
          if (autoSync) {
            await syncEvent(event, silent: true);
          }
        }
      }

      setState(() {
        statusText = 'آخر تحديث: ${DateFormat('HH:mm:ss').format(DateTime.now())}';
      });
    } catch (e) {
      setState(() => statusText = 'خطأ قراءة الرسائل: $e');
    } finally {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  SmsEvent parseNativeSms(Map<String, dynamic> item) {
    final sender = (item['sender'] ?? '').toString();
    final body = (item['body'] ?? '').toString();
    final millis = int.tryParse((item['date'] ?? '').toString()) ?? DateTime.now().millisecondsSinceEpoch;
    final receivedAt = DateTime.fromMillisecondsSinceEpoch(millis);
    final key = base64Url.encode(utf8.encode('$millis|$sender|$body'));

    return SmsEvent(
      key: key,
      sender: sender,
      body: body,
      receivedAt: receivedAt,
      operationType: detectOperationType(body),
      amount: extractAmount(body),
      phone: extractPhone(body),
      transactionId: extractTransactionId(body),
      walletCompany: detectWalletCompany(sender, body),
    );
  }

  bool isWalletMessage(String sender, String body) {
    final text = '$sender $body'.toLowerCase();
    return text.contains('vodafone') ||
        text.contains('cash') ||
        text.contains('فودافون') ||
        text.contains('اتصالات') ||
        text.contains('orange') ||
        text.contains('اورنج') ||
        text.contains('we pay') ||
        text.contains('instapay') ||
        text.contains('انستا') ||
        text.contains('محفظ');
  }

  String detectWalletCompany(String sender, String body) {
    final text = '$sender $body'.toLowerCase();
    if (text.contains('vodafone') || text.contains('فودافون')) return 'Vodafone Cash';
    if (text.contains('etisalat') || text.contains('اتصالات')) return 'Etisalat Cash';
    if (text.contains('orange') || text.contains('اورنج')) return 'Orange Money';
    if (text.contains('we pay') || text.contains('وي')) return 'WE Pay';
    if (text.contains('instapay') || text.contains('انستا')) return 'InstaPay';
    return 'Unknown';
  }

  String detectOperationType(String body) {
    final text = body.toLowerCase();
    if (text.contains('استلمت') || text.contains('received') || text.contains('وارد') || text.contains('تم ايداع')) {
      return 'incoming';
    }
    if (text.contains('حولت') || text.contains('sent') || text.contains('خصم') || text.contains('تم تحويل')) {
      return 'outgoing';
    }
    return 'unknown';
  }

  double extractAmount(String body) {
    final patterns = [
      RegExp(r'(?:egp|جنيه|ج\.م|le)\s*([0-9]+(?:[\.,][0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'([0-9]+(?:[\.,][0-9]{1,2})?)\s*(?:egp|جنيه|ج\.م|le)', caseSensitive: false),
      RegExp(r'(?:مبلغ|قيمة)\s*([0-9]+(?:[\.,][0-9]{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
      }
    }
    return 0;
  }

  String extractPhone(String body) {
    final match = RegExp(r'01[0125][0-9]{8}').firstMatch(body);
    return match?.group(0) ?? '';
  }

  String extractTransactionId(String body) {
    final patterns = [
      RegExp(r'(?:رقم العملية|رقم العمليه|عملية|عمليه|transaction|ref|id)\D*([0-9]{5,})', caseSensitive: false),
      RegExp(r'([0-9]{10,})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) return match.group(1) ?? '';
    }
    return '';
  }

  Future<void> syncEvent(SmsEvent event, {bool silent = false}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('wallet_sms_events').upsert(
        event.toSupabase(userId: user.id),
        onConflict: 'user_id,message_key',
      );
      syncedKeys.add(event.key);
      if (!silent) showSnack('تم إرسال الرسالة إلى Easy Cash');
      setState(() {});
    } catch (e) {
      if (!silent) showSnack('فشل الإرسال: $e');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: LoginScreen())),
    );
  }

  void showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, textDirection: TextDirection.rtl)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('قارئ رسائل Easy Cash', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
        actions: [
          IconButton(onPressed: loadMessages, icon: const Icon(Icons.refresh, color: AppColors.purple)),
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout, color: AppColors.red)),
        ],
      ),
      body: Column(
        children: [
          _statusCard(),
          Expanded(
            child: events.isEmpty ? _empty() : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              itemCount: events.length,
              itemBuilder: (_, index) => _smsCard(events[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [AppColors.blue, AppColors.purple]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              Switch(
                value: autoSync,
                activeColor: Colors.white,
                onChanged: (v) => setState(() => autoSync = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'أي رسالة محفظة تظهر هنا سيتم إرسالها إلى Supabase لتظهر لاحقًا داخل Easy Cash.',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(permissionGranted ? Icons.sms_outlined : Icons.sms_failed_outlined, size: 56, color: AppColors.subText),
          const SizedBox(height: 12),
          Text(permissionGranted ? 'لا توجد رسائل محفظة حتى الآن' : 'فعّل صلاحية قراءة SMS', style: const TextStyle(color: AppColors.subText, fontWeight: FontWeight.w900)),
          if (!permissionGranted)
            TextButton(onPressed: requestSmsPermission, child: const Text('طلب الصلاحية')),
        ],
      ),
    );
  }

  Widget _smsCard(SmsEvent event) {
    final synced = syncedKeys.contains(event.key);
    final color = event.operationType == 'incoming' ? AppColors.green : event.operationType == 'outgoing' ? AppColors.red : AppColors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.sms, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.walletCompany, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
                    Text('${event.sender} - ${DateFormat('dd/MM/yyyy HH:mm').format(event.receivedAt)}', style: const TextStyle(color: AppColors.subText, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: synced ? AppColors.green.withOpacity(0.12) : AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(synced ? 'تم الإرسال' : 'جديد', style: TextStyle(color: synced ? AppColors.green : AppColors.purple, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('النوع: ${event.operationType}'),
              _chip('المبلغ: ${event.amount.toStringAsFixed(2)}'),
              if (event.phone.isNotEmpty) _chip('الرقم: ${event.phone}'),
              if (event.transactionId.isNotEmpty) _chip('عملية: ${event.transactionId}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(event.body, style: const TextStyle(color: AppColors.text, height: 1.4, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => syncEvent(event),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('إرسال لـ Easy Cash'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF8F5FD), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Text(text, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
