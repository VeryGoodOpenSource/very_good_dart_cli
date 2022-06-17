import 'dart:io';
import 'package:mason/mason.dart';

void run(HookContext context) {
  final year = DateTime.now().year;
  context.vars['current_year'] = year;
}
