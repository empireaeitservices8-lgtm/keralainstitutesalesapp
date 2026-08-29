import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'bde_task_view.dart';
import 'management_task_view.dart';

class TaskScreen extends StatelessWidget {
  static const String path = '/tasks';
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthProvider.instance,
      builder: (context, _) {
        final session = AuthProvider.instance.session;
        if (session.role == 'BDE') {
          return BdeTaskView(user: session);
        } else {
          return ManagementTaskView(user: session);
        }
      },
    );
  }
}
