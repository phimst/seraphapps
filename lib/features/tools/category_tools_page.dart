import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/seraph_header.dart';
import 'tool_category.dart';

class CategoryToolsPage extends StatelessWidget {
  final ToolCategory category;
  const CategoryToolsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
                Expanded(
                  child: SeraphHeader(
                    title: category.title,
                    subtitle: category.desc,
                    padding: const EdgeInsets.only(top: 10, bottom: 18),
                  ),
                ),
              ],
            ),
            for (final tool in category.tools) ...[
              _toolCard(context, tool),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toolCard(BuildContext context, ToolEntry tool) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => Scaffold(body: SafeArea(child: tool.builder(ctx)))),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tool.icon, color: AppColors.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.name,
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(tool.desc, style: const TextStyle(color: AppColors.gray, fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
