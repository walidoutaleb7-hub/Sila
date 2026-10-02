import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════
// نموذج رسالة جاهزة
// ═══════════════════════════════════════════
class MessageTemplate {
  final String id;
  final String title;
  final String category;
  final String body;

  const MessageTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.body,
  });

  String render({
    required String studentName,
    String? teacherName,
    String? schoolName,
  }) {
    return body
        .replaceAll('{الطالب}', studentName)
        .replaceAll('{الأستاذ}', teacherName ?? 'الأستاذ')
        .replaceAll('{المدرسة}', schoolName ?? 'المدرسة');
  }
}

const kMessageTemplates = <MessageTemplate>[
  MessageTemplate(
    id: 'abs_today',
    title: 'غياب اليوم',
    category: 'ABSENCE',
    body: 'السلام عليكم ورحمة الله وبركاته،\n\n'
        'نُعلمكم أن ابنكم/ابنتكم {الطالب} لم يحضر إلى المدرسة اليوم. '
        'نرجو إخبارنا بالسبب في أقرب وقت.\n\n'
        'مع تحيات {الأستاذ} - {المدرسة}',
  ),
  MessageTemplate(
    id: 'abs_repeated',
    title: 'غياب متكرر',
    category: 'ABSENCE',
    body: 'السلام عليكم،\n\n'
        'لاحظنا غياب {الطالب} المتكرر خلال الأيام الماضية. '
        'الغياب يؤثر على تحصيله الدراسي. نرجو التواصل معنا لمناقشة الأمر.\n\n'
        '{الأستاذ} - {المدرسة}',
  ),
  MessageTemplate(
    id: 'abs_late',
    title: 'تأخر صباحي',
    category: 'ABSENCE',
    body: 'السلام عليكم،\n\n'
        'وصل {الطالب} متأخراً اليوم. نرجو الحرص على الحضور في الوقت المحدد.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'abs_justify',
    title: 'طلب تبرير الغياب',
    category: 'ABSENCE',
    body: 'السلام عليكم،\n\n'
        'نرجو إرسال تبرير لغياب {الطالب} (شهادة طبية أو عذر مكتوب) '
        'لإضافته إلى ملفه.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'abs_important',
    title: 'تحذير من الغياب',
    category: 'ABSENCE',
    body: 'السلام عليكم،\n\n'
        'تجاوز {الطالب} الحد المسموح به من الغيابات. '
        'نرجو الحضور إلى المدرسة للقاء الإدارة في أقرب وقت.\n\n'
        '{المدرسة}',
  ),
  MessageTemplate(
    id: 'pr_excellent',
    title: 'نتيجة ممتازة',
    category: 'PRAISE',
    body: 'السلام عليكم،\n\n'
        'نبارك لكم تفوّق {الطالب} وحصوله على نتيجة ممتازة. '
        'نرجو مواصلة هذا الجهد المبارك.\n\n'
        '{الأستاذ} - {المدرسة}',
  ),
  MessageTemplate(
    id: 'pr_improved',
    title: 'تحسن ملحوظ',
    category: 'PRAISE',
    body: 'السلام عليكم،\n\n'
        'لاحظنا تحسناً واضحاً في مستوى {الطالب} خلال الفترة الأخيرة. '
        'شكراً لكم على دعمكم.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'pr_behavior',
    title: 'سلوك ممتاز',
    category: 'PRAISE',
    body: 'السلام عليكم،\n\n'
        '{الطالب} طالب مؤدب ومتعاون في القسم. '
        'نشكر لكم حسن تربيتكم.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'pr_participation',
    title: 'مشاركة فعّالة',
    category: 'PRAISE',
    body: 'السلام عليكم،\n\n'
        '{الطالب} يشارك بفعالية في الحصص ويطرح أسئلة ذكية. '
        'هذه روح نتمنى أن تستمر.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'pr_helpful',
    title: 'مساعدة الزملاء',
    category: 'PRAISE',
    body: 'السلام عليكم،\n\n'
        'لاحظنا أن {الطالب} يساعد زملاءه في الفهم. '
        'هذا سلوك نبيل يستحق التقدير.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'wn_homework',
    title: 'عدم إنجاز الواجب',
    category: 'WARNING',
    body: 'السلام عليكم،\n\n'
        'لم يُنجز {الطالب} الواجب المنزلي في المرة الأخيرة. '
        'نرجو متابعته في البيت.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'wn_low_grade',
    title: 'نتيجة ضعيفة',
    category: 'WARNING',
    body: 'السلام عليكم،\n\n'
        'حصل {الطالب} على نتيجة ضعيفة في آخر تقييم. '
        'نرجو متابعته عن قرب.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'wn_distraction',
    title: 'تشتت في القسم',
    category: 'WARNING',
    body: 'السلام عليكم،\n\n'
        'لاحظنا تشتت {الطالب} في القسم خلال الحصص الأخيرة. '
        'نرجو مساعدتنا في فهم السبب.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'wn_supplies',
    title: 'نقص في الأدوات',
    category: 'WARNING',
    body: 'السلام عليكم،\n\n'
        'يحتاج {الطالب} إلى بعض الأدوات الدراسية. '
        'نرجو توفيرها في أقرب وقت.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'wn_phone',
    title: 'استعمال الهاتف',
    category: 'WARNING',
    body: 'السلام عليكم،\n\n'
        'تم ضبط {الطالب} يستعمل الهاتف في القسم. '
        'نرجو متابعته لمنع تكرار الأمر.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'mt_parents',
    title: 'دعوة لقاء الأولياء',
    category: 'MEETING',
    body: 'السلام عليكم،\n\n'
        'ندعوكم لحضور لقاء الأولياء يوم _______ على الساعة _______.\n'
        'سنناقش مستوى {الطالب} وكيفية دعمه.\n\n'
        '{الأستاذ} - {المدرسة}',
  ),
  MessageTemplate(
    id: 'mt_meeting_specific',
    title: 'لقاء خاص',
    category: 'MEETING',
    body: 'السلام عليكم،\n\n'
        'نرجو منكم الحضور إلى المدرسة للقاء خاص بخصوص {الطالب}. '
        'الموضوع مهم ولا يحتاج تأجيلاً.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'mt_exam_reminder',
    title: 'تنبيه بموعد اختبار',
    category: 'MEETING',
    body: 'السلام عليكم،\n\n'
        'نُذكّركم بأن {الطالب} لديه اختبار في مادة _______ يوم _______. '
        'نرجو تحضيره جيداً.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'mt_homework_reminder',
    title: 'تنبيه بواجب',
    category: 'MEETING',
    body: 'السلام عليكم،\n\n'
        'على {الطالب} إنجاز الواجب المنزلي لدرس _______ قبل _______.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'mt_project',
    title: 'تنبيه بمشروع',
    category: 'MEETING',
    body: 'السلام عليكم،\n\n'
        'يشارك {الطالب} في مشروع مدرسي. نرجو دعمه لإنجازه في الوقت المحدد.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'gn_welcome',
    title: 'ترحيب',
    category: 'GENERAL',
    body: 'السلام عليكم ورحمة الله،\n\n'
        'أهلاً بكم في صف {الطالب}. '
        'أنا {الأستاذ}، أستاذ هذه المادة. '
        'سأتابع مستوى ابنكم عن كثب، ولا تتردوا في التواصل معي.\n\n'
        '{المدرسة}',
  ),
  MessageTemplate(
    id: 'gn_thanks',
    title: 'شكر',
    category: 'GENERAL',
    body: 'السلام عليكم،\n\n'
        'نشكركم على تعاونكم المستمر في متابعة {الطالب}. '
        'هذا دعم ثمين لنا.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'gn_holiday',
    title: 'عطلة',
    category: 'GENERAL',
    body: 'السلام عليكم،\n\n'
        'نُعلمكم أن المدرسة ستكون في عطلة من _______ إلى _______. '
        'نتمنى لكم عطلة سعيدة.\n\n'
        '{المدرسة}',
  ),
  MessageTemplate(
    id: 'gn_absence_teacher',
    title: 'غياب الأستاذ',
    category: 'GENERAL',
    body: 'السلام عليكم،\n\n'
        'نُعلمكم أن حصة _______ لن تُقام غداً لظرف خاص. '
        'سيتم تعويضها لاحقاً.\n\n'
        '{الأستاذ}',
  ),
  MessageTemplate(
    id: 'gn_custom',
    title: 'رسالة حرة',
    category: 'GENERAL',
    body: 'السلام عليكم،\n\n'
        'بخصوص {الطالب}: _______\n\n'
        '{الأستاذ}',
  ),
];

// ═══════════════════════════════════════════
// خدمة الإرسال — ✅ مُصلَّحة
// ═══════════════════════════════════════════
class MessagingService {
  /// إرسال رسالة عبر واتساب
  /// ✅ نستخدم launchUrl مباشرة بدون canLaunchUrl (السبب: canLaunchUrl يفشل أحياناً)
  static Future<bool> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = _cleanPhone(phone);
    if (cleanPhone.isEmpty) return false;

    final fullPhone = _ensureCountryCode(cleanPhone);

    // ✅ محاولة 1: تطبيق واتساب مباشرة
    try {
      final uri = Uri.parse(
        'whatsapp://send?phone=$fullPhone&text=${Uri.encodeComponent(message)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {}

    // ✅ محاولة 2: واتساب بزنس
    try {
      final uri = Uri.parse(
        'whatsapp-business://send?phone=$fullPhone&text=${Uri.encodeComponent(message)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {}

    // ✅ محاولة 3: wa.me (يعمل بدون تطبيق)
    try {
      final uri = Uri.parse(
        'https://wa.me/$fullPhone?text=${Uri.encodeComponent(message)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {}

    return false;
  }

  /// إرسال SMS
  static Future<bool> sendSMS({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = _cleanPhone(phone);
    if (cleanPhone.isEmpty) return false;

    // ✅ محاولة 1: sms:
    try {
      final uri = Uri.parse(
        'sms:$cleanPhone?body=${Uri.encodeComponent(message)}',
      );
      await launchUrl(uri);
      return true;
    } catch (_) {}

    // ✅ محاولة 2: smsto:
    try {
      final uri = Uri.parse(
        'smsto:$cleanPhone?body=${Uri.encodeComponent(message)}',
      );
      await launchUrl(uri);
      return true;
    } catch (_) {}

    return false;
  }

  /// اتصال هاتفي
  static Future<bool> callPhone(String phone) async {
    final cleanPhone = _cleanPhone(phone);
    if (cleanPhone.isEmpty) return false;

    try {
      final uri = Uri.parse('tel:$cleanPhone');
      await launchUrl(uri);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  static String _ensureCountryCode(String phone) {
    if (phone.startsWith('0') && !phone.startsWith('00')) {
      return '213${phone.substring(1)}';
    }
    if (phone.startsWith('00')) {
      return phone.substring(2);
    }
    if (phone.startsWith('+')) {
      return phone.substring(1);
    }
    return phone;
  }

  static String formatPhone(String phone) {
    final clean = _cleanPhone(phone);
    if (clean.length == 10) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 6)} '
          '${clean.substring(6, 8)} ${clean.substring(8)}';
    }
    return clean;
  }
}