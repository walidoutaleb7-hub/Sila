import 'package:flutter/material.dart';
import '../services/api.dart';

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
        title: const Text('إضافة قسم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم القسم',
                hintText: 'مثال: 1AS-A',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: levelController,
              decoration: const InputDecoration(
                labelText: 'المستوى',
                hintText: 'مثال: 1AS',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        nameController.text.isNotEmpty &&
        levelController.text.isNotEmpty) {
      try {
        await ApiService.createClass(
          name: nameController.text,
          level: levelController.text,
        );
        _loadClasses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة القسم بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صلة - الأقسام'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<SchoolClass>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('حدث خطأ: ${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadClasses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد أقسام بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('اضغط زر + لإضافة أول قسم',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadClasses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final c = classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text('${c.studentsCount}'),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('المستوى: ${c.level}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}