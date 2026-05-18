import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const HelloChinaApp());
}

class HelloChinaApp extends StatelessWidget {
  const HelloChinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '你好，中国！',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HelloChinaPage(),
    );
  }
}

class HelloChinaPage extends StatefulWidget {
  const HelloChinaPage({super.key});

  @override
  State<HelloChinaPage> createState() => _HelloChinaPageState();
}

class _HelloChinaPageState extends State<HelloChinaPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDE2910), Color(0xFF8B0000)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 80, color: Color(0xFFFFDE00)),
              const SizedBox(height: 30),
              ScaleTransition(
                scale: _scaleAnim,
                child: const Text(
                  '你好，中国！',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFDE00),
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hello, China!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withAlpha(200),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('我爱你，中国！❤️', textAlign: TextAlign.center),
                      backgroundColor: Color(0xFFFFDE00),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDE00),
                  foregroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('点 我', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('读取通讯录', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== 通讯录 MethodChannel ==========

class ContactsChannel {
  static const _channel = MethodChannel('com.example.helloChina/contacts');

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod('requestPermission') == true;
  }

  static Future<List<Map>> getContacts() async {
    final result = await _channel.invokeMethod('getContacts');
    return List<Map>.from(result as List);
  }
}

// ========== 通讯录页面 ==========

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map> _contacts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final contacts = await ContactsChannel.getContacts();
      setState(() => _contacts = contacts);
      print('成功读取 ${contacts.length} 个联系人');
    } catch (e) {
      print('读取联系人失败: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        backgroundColor: const Color(0xFFDE2910),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contact_phone, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text('读取通讯录失败', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadContacts,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _contacts.isEmpty
                  ? const Center(child: Text('通讯录为空'))
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final c = _contacts[index];
                        final name = c['displayName'] as String? ?? '';
                        final phones = c['phones'] as List? ?? [];
                        final phone = phones.isNotEmpty ? phones.first.toString() : '无号码';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFDE2910),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(name.isNotEmpty ? name : '无名'),
                          subtitle: Text(phone),
                        );
                      },
                    ),
    );
  }
}
