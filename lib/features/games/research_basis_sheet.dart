import 'package:flutter/material.dart';

import '../../core/models/brain_models.dart';
import '../../core/training/game_catalog.dart';

Future<void> showResearchBasisSheet(
  BuildContext context,
  GameType game,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) {
    final evidence = gameDefinition(game).evidence;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        children: [
          Text(
            '${game.title}: research basis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(evidence.summary),
          const SizedBox(height: 12),
          Text('Studied population: ${evidence.population}'),
          const SizedBox(height: 8),
          Text('Important limitation: ${evidence.limitation}'),
          const SizedBox(height: 8),
          SelectableText(evidence.reference),
          const SizedBox(height: 16),
          const Text(
            'This task is for practice and self-comparison. It is not a medical treatment, diagnosis, or proof of improvement in everyday cognition.',
          ),
        ],
      ),
    );
  },
);
