import 'package:flutter/material.dart';
import '../services/api.dart';
import 'students.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SchoolClass>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classesFuture = ApiService.getClasses();
    });
  }

  Future<void> _showAddClassDialog() async {
    final nameController = TextEditingController();
    final levelController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_business,
                  color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'قسم جديد',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم القسم',
                hintText: 'مثال: 1AS-A',
                prefixIcon: const Icon(Icons.class_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: levelController,
              decoration: InputDecoration(
                labelText: 'المستوى',
                hintText: 'مثال: 1AS',
                prefixIcon: const Icon(Icons.stairs_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('إضافة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        levelController.text.trim().isNotEmpty) {
      try {
        await ApiService.createClass(
          name: nameController.text.trim(),
          level: levelController.text.trim(),
        );
        _loadClasses();
        if (mounted) {
          _showSnack('تم إضافة القسم بنجاح', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnack('خطأ: $e', isError: true);
        }
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ═══════ AppBar بتدرج لوني ═══════
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Colors.green.shade800,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, right: 16, bottom: 16),
              title: const Text(
                'صلة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.green.shade800,
                      Colors.green.shade500,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Icon(
                        Icons.mosque,
                        size: 220,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    const Positioned(
                      bottom: 60,
                      right: 20,
                      child: Text(
                        'المدرسة في جيبك',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═══════ قائمة الأقسام ═══════
          FutureBuilder<List<SchoolClass>>(
            future: _classesFuture,
            builder: (context, snapshot) {
              // ─── تحميل ───
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green.shade700,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ─── خطأ ───
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.wifi_off_rounded,
                              size: 56,
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'تعذّر الاتصال',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadClasses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final classes = snapshot.data ?? [];

              // ─── فارغ ───
              if (classes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade50,
                                  Colors.green.shade100,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'لا توجد أقسام بعد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط زر + لإضافة أول قسم',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // ─── قائمة الأقسام ───
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildClassCard(classes[index], index),
                    childCount: classes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'قسم جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildClassCard(SchoolClass c, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentsScreen(schoolClass: c),
                ),
              ).then((_) => _loadClasses()); // تحديث العدد عند العودة
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // أيقونة القسم
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade500,
                          Colors.green.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.class_,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // معلومات القسم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c.level,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${c.studentsCount} تلميذ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
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