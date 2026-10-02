import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
      );
      // التنقل يعالج تلقائياً
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('إنشاء حساب'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // العنوان
                    Text(
                      'أهلاً بك',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أنشئ حسابك للبدء في إدارة أقسامك',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // الخطأ
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? const Color(0xFF3A1A1A)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline,
                              size: 18, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // الاسم الكامل
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'الاسم الكامل',
                      hint: 'مثال: أوطالب وليد',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'الاسم مطلوب (حرفان على الأقل)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // اسم المدرسة
                    _buildTextField(
                      controller: _schoolNameController,
                      label: 'المدرسة (اختياري)',
                      hint: 'مثال: ثانوية الأمير عبد القادر',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 14),

                    // البريد
                    _buildTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'البريد مطلوب';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'بريد غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // كلمة المرور
                    _buildTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      hint: '6 أحرف على الأقل',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: colors.textTertiary,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'كلمة المرور 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // تأكيد كلمة المرور
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirm,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: colors.textTertiary,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'تأكيد كلمة المرور مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // زر التسجيل
                    ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'إنشاء الحساب',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // رابط العودة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديك حساب؟',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _loading ? null : () => Navigator.pop(context),
                          child: Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
        labelStyle: TextStyle(
          color: context.isDark
              ? const Color(0xFF81C784)
              : const Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon,
            color: context.isDark
                ? const Color(0xFF81C784)
                : Colors.green.shade400,
            size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.inputBorder, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: context.isDark
                    ? const Color(0xFF4CAF50)
                    : Colors.green.shade300,
                width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
      ),
    );
  }
}