import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../widgets/tv_keyboard_button.dart';
import '../widgets/tv_action_button.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onSettingsSaved;

  const SettingsDialog({super.key, required this.onSettingsSaved});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _protocol = SettingsService.defaultProtocol;
  String _host = SettingsService.defaultHost;
  String _port = SettingsService.defaultPort;

  // 当前正在编辑的字段：0=协议, 1=主机, 2=端口
  int _currentField = 0;
  String _currentInput = '';

  bool _isTesting = false;
  String? _statusMessage;
  bool? _testSuccess;

  // 键盘按键
  final List<String> _gridKeys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '.',
    '-',
    '_',
    ':',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final protocol = await SettingsService.getProtocol();
    final host = await SettingsService.getHost();
    final port = await SettingsService.getPort();

    setState(() {
      _protocol = protocol;
      _host = host;
      _port = port;
      _currentInput = _getCurrentFieldValue();
    });
  }

  String _getCurrentFieldValue() {
    switch (_currentField) {
      case 0:
        return _protocol;
      case 1:
        return _host;
      case 2:
        return _port;
      default:
        return '';
    }
  }

  void _setCurrentFieldValue(String value) {
    setState(() {
      switch (_currentField) {
        case 0:
          _protocol = value;
          break;
        case 1:
          _host = value;
          break;
        case 2:
          _port = value;
          break;
      }
    });
  }

  void _handleKeyboardTap(String key) {
    setState(() {
      if (key == '后退') {
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
          _setCurrentFieldValue(_currentInput);
        }
      } else if (key == '清空') {
        _currentInput = '';
        _setCurrentFieldValue(_currentInput);
      } else {
        // 对于协议字段，只允许输入 http 或 https
        if (_currentField == 0) {
          // 协议字段不通过键盘输入，跳过
          return;
        }
        // 对于端口字段，只允许数字
        if (_currentField == 2 && !RegExp(r'^\d$').hasMatch(key)) {
          return;
        }
        _currentInput += key.toLowerCase();
        _setCurrentFieldValue(_currentInput);
      }
      // 清除之前的状态消息
      _statusMessage = null;
      _testSuccess = null;
    });
  }

  void _handleConfirm() {
    // 确认当前字段，跳到下一个字段
    if (_currentField < 2) {
      setState(() {
        _currentField++;
        _currentInput = _getCurrentFieldValue();
      });
    } else {
      // 最后一个字段，执行测试和保存
      _testAndSave();
    }
  }

  Future<void> _testAndSave() async {
    setState(() {
      _isTesting = true;
      _statusMessage = '正在测试连接...';
      _testSuccess = null;
    });

    // 验证输入
    if (_host.isEmpty) {
      setState(() {
        _isTesting = false;
        _statusMessage = '请输入主机地址';
        _testSuccess = false;
      });
      _showToast('请输入主机地址');
      return;
    }

    if (_port.isEmpty || int.tryParse(_port) == null) {
      setState(() {
        _isTesting = false;
        _statusMessage = '请输入有效的端口号';
        _testSuccess = false;
      });
      _showToast('请输入有效的端口号');
      return;
    }

    // 测试连接
    final (success, message) = await SettingsService.testConnection(
      protocol: _protocol,
      host: _host,
      port: _port,
    );

    setState(() {
      _isTesting = false;
      _statusMessage = message;
      _testSuccess = success;
    });

    if (success) {
      // 保存设置
      await SettingsService.saveSettings(
        protocol: _protocol,
        host: _host,
        port: _port,
      );

      _showToast('设置已保存！请重新打开应用');

      // 延迟一下让用户看到成功消息
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pop();
        // 退出应用，用户需要重新打开
        SystemNavigator.pop();
      }
    } else {
      // 连接失败，显示Toast提示
      _showToast(message);
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: _testSuccess == true ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectField(int index) {
    setState(() {
      _currentField = index;
      _currentInput = _getCurrentFieldValue();
    });
  }

  void _toggleProtocol() {
    setState(() {
      _protocol = _protocol == 'http' ? 'https' : 'http';
      _currentInput = _protocol;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Row(
          children: [
            // 左侧：设置项
            Expanded(
              flex: 45,
              child: Container(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      '服务器设置',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '请配置 AnimeOne 服务器地址',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 50),

                    // 协议选择
                    _buildSettingItem(
                      index: 0,
                      label: '协议（内网一般都是HTTP）',
                      value: _protocol.toUpperCase(),
                      isProtocol: true,
                    ),
                    const SizedBox(height: 24),

                    // 主机地址
                    _buildSettingItem(
                      index: 1,
                      label: '主机地址',
                      value: _host.isEmpty ? '例如: 192.168.1.1' : _host,
                      isEmpty: _host.isEmpty,
                    ),
                    const SizedBox(height: 24),

                    // 端口号
                    _buildSettingItem(
                      index: 2,
                      label: '端口号',
                      value: _port.isEmpty ? '例如: 5000' : _port,
                      isEmpty: _port.isEmpty,
                    ),
                    const SizedBox(height: 40),

                    // 状态消息
                    if (_statusMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _testSuccess == true
                              ? Colors.green.withValues(alpha: 0.2)
                              : _testSuccess == false
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testSuccess == true
                                ? Colors.green
                                : _testSuccess == false
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isTesting)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                _testSuccess == true
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _testSuccess == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: _testSuccess == true
                                      ? Colors.green
                                      : _testSuccess == false
                                      ? Colors.red
                                      : Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 右侧：键盘
            Expanded(
              flex: 55,
              child: Container(
                color: const Color(0xFF252525),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Column(
                    children: [
                      // 当前输入显示
                      Container(
                        height: 60,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4facfe),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              _currentField == 0
                                  ? Icons.security
                                  : _currentField == 1
                                  ? Icons.computer
                                  : Icons.settings_ethernet,
                              color: const Color(0xFF4facfe),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentInput.isEmpty
                                    ? _getPlaceholder()
                                    : _currentInput,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: _currentInput.isEmpty
                                      ? Colors.white38
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 控制按钮
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            if (_currentField == 0)
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1.0),
                                  child: TvActionButton(
                                    label: '切换协议',
                                    color: const Color(0xFF4facfe),
                                    onTap: _toggleProtocol,
                                  ),
                                ),
                              )
                            else ...[
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1.0),
                                  child: TvKeyboardButton(
                                    label: '清空',
                                    onTap: () => _handleKeyboardTap('清空'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(1.1),
                                  child: TvKeyboardButton(
                                    label: '后退',
                                    onTap: () => _handleKeyboardTap('后退'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 键盘网格
                      if (_currentField != 0)
                        Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _gridKeys.length,
                            itemBuilder: (context, index) =>
                                FocusTraversalOrder(
                                  order: NumericFocusOrder(
                                    2.0 + (index * 0.001),
                                  ),
                                  child: TvKeyboardButton(
                                    label: _gridKeys[index],
                                    onTap: () =>
                                        _handleKeyboardTap(_gridKeys[index]),
                                  ),
                                ),
                          ),
                        )
                      else
                        const Expanded(
                          child: Center(
                            child: Text(
                              '点击"切换协议"按钮选择 HTTP 或 HTTPS\n然后点击"确认"继续',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 确认按钮
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3.0),
                        child: SizedBox(
                          height: 55,
                          width: double.infinity,
                          child: TvActionButton(
                            label: _currentField < 2 ? '确认' : '测试连接并保存',
                            color: const Color(0xFF4facfe),
                            onTap: _isTesting ? () {} : _handleConfirm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlaceholder() {
    switch (_currentField) {
      case 0:
        return '选择协议...';
      case 1:
        return '输入主机地址...';
      case 2:
        return '输入端口号...';
      default:
        return '';
    }
  }

  Widget _buildSettingItem({
    required int index,
    required String label,
    required String value,
    bool isEmpty = false,
    bool isProtocol = false,
  }) {
    final isActive = _currentField == index;

    return Focus(
      autofocus: index == 0,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _selectField(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return InkWell(
            onTap: () => _selectField(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4facfe).withValues(alpha: 0.2)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: focused
                      ? const Color(0xFF4facfe)
                      : isActive
                      ? const Color(0xFF4facfe).withValues(alpha: 0.5)
                      : Colors.white24,
                  width: focused ? 3 : 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF4facfe)
                              : Colors.white70,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          size: 16,
                          color: Color(0xFF4facfe),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isEmpty ? Colors.white38 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
