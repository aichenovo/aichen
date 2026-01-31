import 'package:flutter/material.dart';
import 'package:kazumi/pages/menu/menu.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  void initState() {
    super.initState();
    // 页面初始化后，直接弹出弹窗（延迟一小步，避免上下文报错）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSimpleNoticeDialog();
    });
  }

  /// 极简版弹窗：每次进入都显示
  void _showSimpleNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('【公告】'),
        content: const Text('这是每次进入都会显示的极简弹窗'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // 仅关闭弹窗
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ScaffoldMenu();
  }
}
