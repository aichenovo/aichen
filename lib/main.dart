import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kazumi/app_module.dart';
import 'package:kazumi/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/settings/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kazumi/request/request.dart';
import 'package:kazumi/utils/proxy_manager.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kazumi/pages/error/storage_error_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kazumi/utils/tmdb_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
  }

  if (Platform.isAndroid) {
    await Utils.checkWebViewFeatureSupport();
  }

  try {
    await Hive.initFlutter(
        '${(await getApplicationSupportDirectory()).path}/hive');
    await GStorage.init();
  } catch (_) {
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow(null, () async {
        // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
        // Without this. the window will never show on Windows.
        await windowManager.show();
        await windowManager.focus();
      });
    }
    runApp(MaterialApp(
        title: '初始化失败',
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN")
        ],
        locale: const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: "CN"),
        builder: (context, child) {
          return const StorageErrorPage();
        }));
    return;
  }

  bool showWindowButton = await GStorage.setting
      .get(SettingBoxKey.showWindowButton, defaultValue: false);

  if (Utils.isDesktop()) {
    await windowManager.ensureInitialized();
    bool isLowResolution = await Utils.isLowResolution();
    WindowOptions windowOptions = WindowOptions(
      size: isLowResolution ? const Size(840, 600) : const Size(1280, 860),
      center: true,
      skipTaskbar: false,
      // macOS always hide title bar regardless of showWindowButton setting
      titleBarStyle: (Platform.isMacOS || !showWindowButton)
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: showWindowButton,
      title: 'Aura',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Native window show has been blocked in `flutter_windows.cppL36` to avoid flickering.
      // Without this. the window will never show on Windows.
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Request();
  await Request.setCookie();
  ProxyManager.applyProxy();
  Future.microtask(() => TmdbMigration.migrateIfNeeded());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ModularApp(
        module: AppModule(),
        child: const AppWidget(),
      ),
    ),
  );

  // 在 App 第一帧渲染完成后显示欢迎公告弹窗
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // 如果想改为“只首次显示”，可以取消下面注释，使用 Hive 判断
    // bool isFirstLaunch = GStorage.setting.get(SettingBoxKey.isFirstLaunch, defaultValue: true) ?? true;
    // if (!isFirstLaunch) return;

    final context = Modular.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true, // 点击弹窗外部可关闭
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('欢迎使用 Aura'),
          content: const Text(
            '欢迎来到 Aura！\n\n'
            '这是一个基于自定义规则的视频/番剧采集播放工具。\n'
            '在这里你可以自由探索各种资源，享受追剧的乐趣～\n\n'
            '祝你使用愉快！有任何问题或建议，欢迎随时反馈。',
            style: TextStyle(height: 1.5),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // 如果想只首次显示，设置标志位（配合上面注释的判断）
                // GStorage.setting.put(SettingBoxKey.isFirstLaunch, false);
              },
              child: const Text('好的，知道了！'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        );
      },
    );
  });
}
