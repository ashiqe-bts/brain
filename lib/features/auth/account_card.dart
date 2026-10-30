import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_service.dart';
import '../../core/state/brain_cubit.dart';
import '../../core/storage/brain_repository.dart';
import '../../core/widgets/common.dart';
import 'email_auth_screen.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.header});
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return const SizedBox.shrink();
    final session = auth.session;
    final title = switch (session.kind) {
      AccountKind.offlineGuest => 'Offline guest',
      AccountKind.guest => 'Guest account',
      AccountKind.verificationPending => 'Verification pending',
      AccountKind.account =>
        session.email ?? session.displayName ?? 'BrainFlex account',
    };
    final subtitle = switch (session.kind) {
      AccountKind.offlineGuest =>
        'Training stays local until Firebase is configured.',
      AccountKind.guest =>
        'Create an account to use this progress on another device.',
      AccountKind.verificationPending =>
        'Check ${session.email} to finish setup.',
      AccountKind.account => 'Progress sync is active.',
    };
    return AppCard(
      child: Column(
        children: [
          header,
          ListTile(
            leading: Icon(
              session.isGuest
                  ? Icons.person_outline
                  : Icons.cloud_done_outlined,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
          ),
          ValueListenableBuilder<ProgressSyncStatus>(
            valueListenable: context.read<BrainCubit>().repository.syncStatus,
            builder: (context, status, _) {
              final message = switch (status) {
                ProgressSyncStatus.disabled => 'Cloud sync is unavailable.',
                ProgressSyncStatus.syncing => 'Syncing progress…',
                ProgressSyncStatus.synced => 'Progress is up to date.',
                ProgressSyncStatus.pending =>
                  'Sync pending. Training can continue offline.',
              };
              return Semantics(
                liveRegion: status == ProgressSyncStatus.pending,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    status == ProgressSyncStatus.pending
                        ? Icons.cloud_off_outlined
                        : Icons.sync_rounded,
                  ),
                  title: Text(message),
                ),
              );
            },
          ),
          if (session.isGuest) ...[
            ListTile(
              leading: const Icon(Icons.g_mobiledata_rounded),
              title: const Text('Continue with Google'),
              onTap: auth.busy
                  ? null
                  : () => auth.run(auth.service.continueWithGoogle),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Continue with email'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
              ),
            ),
          ] else ...[
            if (session.kind == AccountKind.verificationPending)
              ListTile(
                leading: const Icon(Icons.mark_email_unread_outlined),
                title: const Text('Resend verification email'),
                onTap: auth.busy
                    ? null
                    : () => auth.run(auth.service.sendVerification),
              ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: auth.busy
                  ? null
                  : () => auth.run(auth.service.signOutToGuest),
            ),
            ListTile(
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('Delete account and cloud data'),
              onTap: auth.busy ? null : () => _confirmDelete(context, auth),
            ),
          ],
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  auth.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AuthController auth) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your cloud progress. Type DELETE to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Confirmation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text == 'DELETE'),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed == true) await auth.run(auth.service.deleteAccount);
  }
}
