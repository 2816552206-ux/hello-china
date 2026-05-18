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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDE2910), Color(0xFF8B0000)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '信美分期',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFDE00),
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 80),
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

// ========== MethodChannel 桥接 ==========

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
  final _serverController = TextEditingController(text: 'http://:8080/upload');
  final _uploaderController = TextEditingController();
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
      setState(() => _status = '请填写服务器地址和上传人员姓名');
      return;
    }

    setState(() => _uploading = true);
    try {
      final body = jsonEncode({
        'uploader': uploader,
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
            ? '上传成功！${_contacts.length} 个联系人已发送'
            : '上传失败: 服务器返回 ${response.statusCode}';
      });
      print('上传结果: ${response.statusCode} ${response.body}');
    } catch (e) {
      setState(() {
        _uploading = false;
        _status = '上传失败: 无法连接服务器，请检查地址和网络';
      });
      print('上传异常: $e');
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _uploaderController.dispose();
    super.dispose();
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
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('加载失败', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _loadAll, child: const Text('重试')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ---- 输入区域 ----
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _serverController,
                            decoration: const InputDecoration(
                              labelText: '服务器地址',
                              hintText: 'http://IP:8080/upload',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.cloud_upload, size: 20),
                            ),
                            style: const TextStyle(fontSize: 14),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _uploaderController,
                            decoration: const InputDecoration(
                              labelText: '上传人员',
                              hintText: '请输入姓名',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.person, size: 20),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text('设备: $_deviceName',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    // ---- 联系人列表 ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 18, color: Color(0xFFDE2910)),
                          const SizedBox(width: 6),
                          Text('共 ${_contacts.length} 个联系人',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _contacts.isEmpty
                          ? const Center(child: Text('通讯录为空'))
                          : ListView.builder(
                              itemCount: _contacts.length,
                              itemBuilder: (context, index) {
                                final c = _contacts[index];
                                final name = c['displayName'] as String? ?? '';
                                final phones = c['phones'] as List? ?? [];
                                final phone = phones.isNotEmpty ? phones.first.toString() : '';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDE2910),
                                    radius: 18,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  title: Text(name.isNotEmpty ? name : '无名',
                                      style: const TextStyle(fontSize: 15)),
                                  subtitle: phone.isNotEmpty
                                      ? Text(phone,
                                          style: const TextStyle(fontSize: 13))
                                      : null,
                                );
                              },
                            ),
                    ),
                    // ---- 状态 & 上传按钮 ----
                    if (_status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('成功') ? Colors.green : Colors.red,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: ElevatedButton(
                        onPressed: _uploading ? null : _upload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDE2910),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _uploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('上传到服务器', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
