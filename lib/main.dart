import 'package:flutter/material.dart';

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
              // 五角星图标
              const Icon(Icons.star, size: 80, color: Color(0xFFFFDE00)),
              const SizedBox(height: 30),
              // 主标题
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
              // 副标题
              Text(
                'Hello, China!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withAlpha(200),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 60),
              // 底部按钮
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
            ],
          ),
        ),
      ),
    );
  }
}
