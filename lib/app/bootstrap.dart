import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/auth/auth_controller.dart';
import '../core/auth/auth_service.dart';
import '../core/state/brain_cubit.dart';
import '../core/storage/app_database.dart';
import '../core/storage/brain_repository.dart';
import '../core/sync/firebase_progress_store.dart';
import '../core/sync/progress_merge.dart';
import 'app.dart';

class BrainFlexBootstrap extends StatefulWidget {
  const BrainFlexBootstrap({
    super.key,
    required this.auth,
    required this.database,
    required this.firebaseConfigured,
  });

  final AuthController auth;
  final AppDatabase database;
  final bool firebaseConfigured;

  @override
  State<BrainFlexBootstrap> createState() => _BrainFlexBootstrapState();
}

class _BrainFlexBootstrapState extends State<BrainFlexBootstrap> {
  BrainCubit? cubit;
  String? loadedUid;
  AccountKind? loadedKind;
  bool wasBusy = false;
  Object? loadError;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_authChanged);
    unawaited(_load(widget.auth.session.uid));
  }

  void _authChanged() {
    final uid = widget.auth.session.uid;
    final finishedAction = wasBusy && !widget.auth.busy;
    wasBusy = widget.auth.busy;
    if (uid != loadedUid || finishedAction) unawaited(_switchProfile(uid));
  }

  Future<void> _switchProfile(String uid) async {
    final signingOut =
        uid != loadedUid &&
        widget.auth.session.isGuest &&
        loadedKind != null &&
        loadedKind != AccountKind.guest &&
        loadedKind != AccountKind.offlineGuest;
    if (signingOut) await cubit?.repository.deleteLocalData();
    await _load(uid);
  }

  Future<void> _load(String uid) async {
    try {
      final repository = BrainRepository(
        widget.database,
        profileId: uid,
        cloud: widget.firebaseConfigured && uid != 'offline-guest'
            ? FirebaseProgressStore(uid)
            : null,
      );
      var initial = await repository.load();
      final upgradingGuest =
          loadedUid != null &&
          uid != loadedUid &&
          cubit != null &&
          (loadedKind == AccountKind.guest ||
              loadedKind == AccountKind.offlineGuest) &&
          !widget.auth.session.isGuest;
      if (upgradingGuest) {
        initial = mergeProgress(local: cubit!.data, cloud: initial);
        await repository.importState(initial);
      }
      final next = BrainCubit(repository, initial);
      await next.bootstrap();
      if (!mounted || widget.auth.session.uid != uid) {
        await next.close();
        return;
      }
      final previous = cubit;
      setState(() {
        cubit = next;
        loadedUid = uid;
        loadedKind = widget.auth.session.kind;
        loadError = null;
      });
      await previous?.close();
    } catch (error) {
      if (mounted) setState(() => loadError = error);
    }
  }

  @override
  void dispose() {
    widget.auth.removeListener(_authChanged);
    cubit?.close();
    widget.auth.dispose();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScope(
    controller: widget.auth,
    child: cubit == null
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: loadError == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Could not open your local progress.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _load(widget.auth.session.uid),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
              ),
            ),
          )
        : BlocProvider.value(value: cubit!, child: const BrainFlexApp()),
  );
}
