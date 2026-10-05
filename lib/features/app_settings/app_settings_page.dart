import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../platform/launcher_icon_controller.dart';
import '../../platform/project_info.dart';
import '../launcher_icons/launcher_icon_picker.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key, this.launcherIcons});
  final LauncherIconController? launcherIcons;

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late final _version = ProjectInfo.version();

  Future<void> _openProject() async {
    if (await ProjectInfo.open() || !mounted) return;
    String feedback;
    try {
      await Clipboard.setData(const ClipboardData(text: ProjectInfo.address));
      feedback = '项目地址已复制，可在浏览器打开';
    } catch (_) {
      feedback = '无法打开项目，请根据页面地址访问 GitHub';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(feedback)));
  }

  Future<void> _showIcons() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .9,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('更换桌面图标', style: TextStyle(fontSize: 20)),
                  ),
                  IconButton(
                    tooltip: '关闭设置',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: LauncherIconPicker(controller: widget.launcherIcons!),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _group(BuildContext context, String title, List<Widget> rows) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 9),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  rows[index],
                ],
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('设置'),
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<String?>(
        future: _version,
        builder: (context, version) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (widget.launcherIcons != null)
              _group(context, '外观', [
                ListenableBuilder(
                  listenable: widget.launcherIcons!,
                  builder: (context, _) {
                    final selected = widget.launcherIcons!.selected;
                    return Tooltip(
                      message: '桌面图标',
                      child: ListTile(
                        title: const Text('桌面图标'),
                        subtitle: Text(
                          selected == null
                              ? '查看可用图标'
                              : '${selected.letter} · ${selected.label}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showIcons,
                      ),
                    );
                  },
                ),
              ]),
            _group(context, '关于 HypnoLoop', [
              const ListTile(
                title: Text('作者'),
                trailing: Text(ProjectInfo.author),
              ),
              ListTile(
                key: const Key('project-address'),
                title: const Text('项目地址'),
                subtitle: const Text(
                  ProjectInfo.displayAddress,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                onTap: _openProject,
              ),
              if (version.hasData)
                ListTile(
                  title: const Text('当前版本'),
                  trailing: Text(version.data!),
                ),
            ]),
          ],
        ),
      ),
    ),
  );
}
