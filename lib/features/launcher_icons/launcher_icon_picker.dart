import 'package:flutter/material.dart';
import '../../platform/launcher_icon_controller.dart';

class LauncherIconPicker extends StatelessWidget {
  const LauncherIconPicker({super.key, required this.controller});
  final LauncherIconController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('桌面图标')),
            TextButton(
              onPressed:
                  controller.available &&
                      !controller.busy &&
                      controller.selected != LauncherIconController.defaultIcon
                  ? () => controller.select(LauncherIconController.defaultIcon)
                  : null,
              child: const Text('恢复默认'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final icon in LauncherIcon.values)
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: Semantics(
                    key: Key('launcher-icon-${icon.name}'),
                    button: true,
                    selected: controller.selected == icon,
                    enabled: controller.available && !controller.busy,
                    label:
                        '${icon.letter} ${icon.label}${controller.selected == icon ? '，当前图标' : ''}',
                    excludeSemantics: true,
                    onTap: controller.available && !controller.busy
                        ? () => controller.select(icon)
                        : null,
                    child: OutlinedButton(
                      onPressed: controller.available && !controller.busy
                          ? () => controller.select(icon)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 12,
                        ),
                        side: BorderSide(
                          color: controller.selected == icon
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF51485E),
                          width: controller.selected == icon ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              icon.asset,
                              width: 64,
                              height: 64,
                              cacheWidth: 192,
                              excludeFromSemantics: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${icon.letter} · ${icon.label}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.selected == icon ? '已选' : '选择',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '切换后返回桌面查看，图标刷新可能需要片刻。',
          style: TextStyle(color: Color(0xFFABA6BC), fontSize: 12),
        ),
        if (controller.busy)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(),
          ),
        if (controller.error != null) ...[
          const SizedBox(height: 10),
          Text(controller.error!),
          if (!controller.available && controller.error != '当前平台暂不支持更换桌面图标')
            TextButton(
              onPressed: controller.busy ? null : controller.load,
              child: const Text('重试'),
            ),
        ],
      ],
    ),
  );
}
