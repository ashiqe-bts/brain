import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/training/game_catalog.dart';

Future<void> showResearchBasisSheet(BuildContext context, GameType game) =>
    showModalBottomSheet<void>(
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
                AppText.researchTitle(game.title),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(evidence.summary),
              const SizedBox(height: 12),
              Text(AppText.studiedPopulation(evidence.population)),
              const SizedBox(height: 8),
              Text(AppText.importantLimitation(evidence.limitation)),
              const SizedBox(height: 8),
              SelectableText(evidence.reference),
              const SizedBox(height: 16),
              Text(AppText.train.researchDisclaimer),
            ],
          ),
        );
      },
    );
