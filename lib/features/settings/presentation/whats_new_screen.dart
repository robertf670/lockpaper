import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lockpaper/core/models/release_info.dart';
import 'package:lockpaper/core/services/version_service.dart';

/// Screen that displays what's new in the current update
class WhatsNewScreen extends ConsumerWidget {
  const WhatsNewScreen({super.key, this.showAllHistory = false});

  /// Whether to show all version history or just recent updates
  final bool showAllHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionServiceAsync = ref.watch(versionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(showAllHistory ? 'Version History' : "What's New"),
      ),
      body: versionServiceAsync.when(
        data: (versionService) {
          final releases = showAllHistory
              ? versionService.getReleaseHistory()
              : versionService.getNewReleaseNotes();

          if (releases.isEmpty) {
            return const Center(
              child: Text('No updates available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: releases.length,
            itemBuilder: (context, index) {
              return _ReleaseCard(release: releases[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Mark version as seen when continuing
          if (!showAllHistory) {
            final versionService = await ref.read(versionServiceProvider.future);
            await versionService.markVersionSeen();
          }
          // Use GoRouter navigation instead of Navigator.pop()
          if (context.canPop()) {
            // If we can pop, we were pushed onto the stack
            context.pop();
          } else {
            // If we can't pop, we're the initial route - go to home
            context.go('/');
          }
        },
        label: const Text('Continue'),
        icon: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Widget that displays a single release with its changes
class _ReleaseCard extends StatelessWidget {
  final ReleaseInfo release;

  const _ReleaseCard({required this.release});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');

    // Group changes by category
    final changesByCategory = <String, List<ReleaseChange>>{};
    for (final change in release.changes) {
      final category = change.category ?? 'General';
      changesByCategory.putIfAbsent(category, () => []).add(change);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Version ${release.version}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(release.releaseDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...changesByCategory.entries.map((entry) {
              return _CategoryChanges(
                category: entry.key,
                changes: entry.value,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays changes for a specific category
class _CategoryChanges extends StatelessWidget {
  final String category;
  final List<ReleaseChange> changes;

  const _CategoryChanges({
    required this.category,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...changes.map((change) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(change.description),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
} 