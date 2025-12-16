import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/playback_history_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isTesting = false;
  String? _statusMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    final baseUrl = await SettingsService.getBaseUrl();
    setState(() {
      _serverUrlController.text = baseUrl;
    });
  }

  Future<void> _testAndSave() async {
    final url = _serverUrlController.text.trim();

    if (url.isEmpty) {
      _showMessage('请输入服务器地址', false);
      return;
    }

    // 解析URL
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      _showMessage('URL格式错误', false);
      return;
    }

    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      _showMessage('URL格式错误，应为: http://192.168.1.1:5000', false);
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMessage = '正在测试连接...';
      _testSuccess = null;
    });

    // 测试连接
    final (success, message) = await SettingsService.testConnection(
      protocol: uri.scheme,
      host: uri.host,
      port: uri.port.toString(),
    );

    if (success) {
      // 保存设置
      await SettingsService.saveSettings(
        protocol: uri.scheme,
        host: uri.host,
        port: uri.port.toString(),
      );
      _showMessage('保存成功！', true);
    } else {
      _showMessage(message, false);
    }

    setState(() {
      _isTesting = false;
    });
  }

  void _showMessage(String message, bool success) {
    setState(() {
      _statusMessage = message;
      _testSuccess = success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有播放记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PlaybackHistoryService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('播放记录已清除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 服务器地址
            const Text(
              '服务器地址',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Focus(
              child: TextField(
                controller: _serverUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.1:5000',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4facfe),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 测试并保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _testAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4facfe),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        '测试并保存',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess == true
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess == true ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _testSuccess == true ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 32),

            // 清除播放记录
            const Text(
              '数据管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _clearHistory,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '清除播放记录',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 32),

            // 关于
            const Text(
              '关于',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AnimeOne TV',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              '版本 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
