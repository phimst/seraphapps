import 'package:flutter/material.dart';

class ToolEntry {
  final IconData icon;
  final String name;
  final String desc;
  final WidgetBuilder builder;

  const ToolEntry({
    required this.icon,
    required this.name,
    required this.desc,
    required this.builder,
  });
}

class ToolCategory {
  final String title;
  final String desc;
  final IconData icon;
  final List<ToolEntry> tools;

  const ToolCategory({
    required this.title,
    required this.desc,
    required this.icon,
    required this.tools,
  });
}
