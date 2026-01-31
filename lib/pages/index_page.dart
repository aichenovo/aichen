import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazumi/pages/menu/menu.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  // 存储从 GitHub 获取的公告内容
  String _noticeContent = "正在加载公告...";

  @override
  void initState() {
    super.initState();
    // 1. 先获取公告内容，再弹出弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchNoticeFromGitHub();
      _showSimpleNoticeDialog();
    });
  }

  /// 从 GitHub 获取公告内容
  Future<void> _fetchNoticeFromGitHub() async {
    try {
      // 注意：GitHub 直接读取 raw 内容（blob 页面是网页，raw 才是纯文本）
      // 把 blob 替换为 raw，去掉浏览器渲染相关的内容
      final url = Uri.parse("https://raw.githubusercontent.com/aichenovo/aichen/main/notice");
      final response = await http.get(url);

      // 请求成功（状态码 200）
      if (response.statusCode == 200) {
        setState(() {
          // 把返回的纯文本赋值给公告内容
          _noticeContent = response.body;
        });
      } else {
        // 请求失败，显示错误提示
        _noticeContent = "公告加载失败（状态码：${response.statusCode}）";
      }
    } catch (e) {
      // 捕获网络异常等错误
      _noticeContent = "公告加载失败：${e.toString()}";
    }
  }

  /// 显示包含 GitHub 公告内容的弹窗
  void _showSimpleNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('【公告】'),
        // 用 SingleChildScrollView 包裹，避免内容过多溢出
        content: SingleChildScrollView(
          child: Text(_noticeContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
