import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/async_views.dart';
import '../../domain/activity_csv.dart';
import '../view_models/activities.dart';
import '../widgets/activity_tile.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  static const _padding = 18.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(activitiesProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _padding,
                _padding,
                _padding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  onExport: activities.hasValue
                      ? () => _export(context, ref)
                      : null,
                ),
              ),
            ),
            switch (activities) {
              AsyncData(:final value) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: _padding),
                sliver: DecoratedSliver(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    sliver: SliverList.builder(
                      itemCount: value.length,
                      itemBuilder: (_, index) =>
                          ActivityTile(item: value[index]),
                    ),
                  ),
                ),
              ),
              AsyncError() => SliverToBoxAdapter(
                child: ErrorRetryView(
                  message: 'Your activity could not be loaded.',
                  onRetry: () => ref.invalidate(activitiesProvider),
                ),
              ),
              _ => const SliverToBoxAdapter(child: LoadingView()),
            },
            const SliverPadding(
              padding: EdgeInsets.all(_padding),
              sliver: SliverToBoxAdapter(child: _DisputesCard()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final items = ref.read(activitiesProvider).value ?? const [];
    await Clipboard.setData(ClipboardData(text: ActivityCsv.encode(items)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('CSV transaction report copied.'))),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onExport});
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              context.tr('Activity'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Export CSV report',
            onPressed: onExport,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      Text(
        context.tr('Audit-friendly payment history and receipts'),
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      TextField(
        decoration: InputDecoration(
          hintText: context.tr('Search transactions'),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: const Icon(Icons.tune_rounded),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

class _DisputesCard extends StatelessWidget {
  const _DisputesCard();

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.info_outline_rounded),
      title: Text(
        context.tr('Disputes and reversals'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text(
        'Production receipts will include fee breakdowns, exchange rates, settlement state and dispute actions.',
      ),
      isThreeLine: true,
    ),
  );
}
