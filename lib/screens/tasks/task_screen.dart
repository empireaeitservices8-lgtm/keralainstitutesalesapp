import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../sm/sm_teams_view.dart';
import '../asm/asm_teams_view.dart';
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
        } else if (session.role == 'SM') {
          return const SmTeamsView();
        } else if (session.role == 'ASM') {
          return const AsmTeamsView();
        } else {
          return ManagementTaskView(user: session);
        }
      },
    );
  }
}
