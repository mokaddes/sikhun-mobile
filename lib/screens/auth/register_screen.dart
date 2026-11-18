import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/sikhun_brand_logo.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  String _selectedSegment = 'admission';
  final List<Map<String, String>> _segments = const [
    {'label': 'বিশ্ববিদ্যালয় ভর্তি প্রস্তুতি (DU, RU, BUET, Medical, GST)', 'value': 'admission'},
    {'label': 'বিসিএস ও সরকারি/ব্যাংক চাকরি প্রস্তুতি (Job)', 'value': 'job'},
    {'label': 'উচ্চ মাধ্যমিক (HSC)', 'value': 'hsc'},
    {'label': 'মাধ্যমিক (SSC)', 'value': 'ssc'},
    {'label': 'বিশ্ববিদ্যালয় অ্যাকাডেমিক (University)', 'value': 'university'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmController.text,
      phone: _phoneController.text.trim(),
      studentType: _selectedSegment,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProv.isBengali ? 'নতুন অ্যাকাউন্ট তৈরি করুন' : 'Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SikhunBrandLogo(
                    isBangla: localeProv.isBengali,
                    markSize: 44,
                    showTagline: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localeProv.isBengali ? 'শিখুনে রেজিস্ট্রেশন' : 'Register on Sikhun',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'একটি অ্যাকাউন্টে বই, অধ্যায়, প্রশ্নব্যাংক ও এআই টিউটর সুবিধা পান',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: SikhunTheme.mutedDark),
                ),
                const SizedBox(height: 22),

                if (auth.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SikhunTheme.danger.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SikhunTheme.danger.withAlpha(75)),
                    ),
                    child: Text(
                      auth.errorMessage!,
                      style: const TextStyle(color: SikhunTheme.danger, fontSize: 13),
                    ),
                  ),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'আপনার নাম',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'নাম লিখুন' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'ইমেইল লিখুন';
                    if (!value.contains('@')) return 'সঠিক ইমেইল ঠিকানা দিন';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'মোবাইল নম্বর (ঐচ্ছিক)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _selectedSegment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'শিক্ষা লক্ষ্য / ক্যাটাগরি',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _segments
                      .map((seg) => DropdownMenuItem<String>(
                            value: seg['value'],
                            child: Text(
                              seg['label']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSegment = val);
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'পাসওয়ার্ড (কমপক্ষে ৮ অক্ষর)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'কমপক্ষে ৮ অক্ষরের পাসওয়ার্ড দিন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'পাসওয়ার্ড দুটি মিলছে না';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SikhunTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'অ্যাকাউন্ট তৈরি করুন',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('আগে থেকেই অ্যাকাউন্ট আছে? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'লগইন করুন',
                        style: TextStyle(color: SikhunTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
