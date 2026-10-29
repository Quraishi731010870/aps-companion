import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/currency_format.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/async_views.dart';
import '../../../activity/presentation/view_models/activities.dart';
import '../../../activity/presentation/widgets/activity_tile.dart';
import '../../../auth/presentation/view_models/current_user.dart';
import '../../../payments/presentation/view_models/enabled_operations.dart';
import '../../../payments/domain/payment_transaction.dart';
import '../../../payments/presentation/view_models/linked_card.dart';
import '../../../payments/presentation/view_models/wallet.dart';
import '../../../payments/presentation/views/card_link_sheet.dart';
import '../../../payments/presentation/views/payment_flow.dart';
import '../../../payments/presentation/views/saved_card_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onNotificationsPressed});
  final VoidCallback? onNotificationsPressed;
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool hidden = false;

  static const _quickActions = [
    (
      label: 'Cash in',
      icon: Icons.add_rounded,
      operation: PaymentOperation.cashIn,
      scan: false,
    ),
    (
      label: 'Bank push',
      icon: Icons.send_rounded,
      operation: PaymentOperation.walletToCard,
      scan: false,
    ),
    (
      label: 'QR Pay',
      icon: Icons.qr_code_scanner_rounded,
      operation: PaymentOperation.purchase,
      scan: true,
    ),
    (
      label: 'Cash out',
      icon: Icons.payments_outlined,
      operation: PaymentOperation.cashOut,
      scan: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final linkedCard = ref.watch(linkedCardProvider).value;
    final userName = ref.watch(
      displayedUserProvider.select((user) => user.displayName),
    );
    final operations = ref.watch(enabledOperationsProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Image.asset(
                  'assets/branding/payafghan_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Good afternoon'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'View transaction history',
                onPressed: widget.onNotificationsPressed,
                icon: const Badge(
                  smallSize: 7,
                  child: Icon(Icons.notifications_none_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff087f67), Color(0xff075749)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff087f67).withValues(alpha: .22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('Available balance'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                _WalletSummary(hidden: hidden),
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (final action in _quickActions)
                      _Action(
                        action.label,
                        action.icon,
                        () => openPaymentFlow(
                          context,
                          action.operation,
                          scanQrOnOpen: action.scan,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Row(
            children: [
              const Expanded(child: _Header('My card')),
              TextButton.icon(
                onPressed: _linkCard,
                icon: Icon(linkedCard == null ? Icons.add_link : Icons.edit),
                label: Text(
                  context.tr(linkedCard == null ? 'Link card' : 'Change'),
                ),
              ),
            ],
          ),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xffe7f3ef),
                child: Icon(
                  linkedCard == null
                      ? Icons.credit_card_off_outlined
                      : Icons.credit_card_rounded,
                  color: const Color(0xff087f67),
                ),
              ),
              title: Text(
                linkedCard?.label ?? context.tr('No card linked'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                linkedCard == null
                    ? context.tr(
                        'Connect an APS-enabled bank card to your wallet',
                      )
                    : context.tr('Linked securely to your PayAfghan wallet'),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openCard,
            ),
          ),
          const SizedBox(height: 23),
          const _Header('Transaction services'),
          _ServiceGrid(operations),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfffff4da),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xffffe1a0),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xff955f00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Complete your verification'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        context.tr('Raise your monthly limit to 250,000 AFN'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _Header('Recent activity'),
          const _RecentActivity(),
        ],
      ),
    );
  }

  /// Shows the linked card, or the link form when there is none yet.
  Future<void> _openCard() async {
    final card = ref.read(linkedCardProvider).value;
    if (card == null) return _linkCard();
    final replace = await showSavedCardSheet(context, card);
    if (replace == true && mounted) await _linkCard();
  }

  Future<void> _linkCard() async {
    final card = await showCardLinkSheet(context);
    if (card == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card linked successfully for testing.')),
    );
  }
}

/// Balance and masked wallet id from the backend.
class _WalletSummary extends ConsumerWidget {
  const _WalletSummary({required this.hidden});
  final bool hidden;

  static const _balanceStyle = TextStyle(
    color: Colors.white,
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );
  static const _detailStyle = TextStyle(color: Colors.white70);

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    walletProvider,
  )) {
    AsyncData(:final value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hidden
              ? '•••••• ${value.currency}'
              : groupedAmount(value.availableBalance, value.currency),
          style: _balanceStyle,
        ),
        Text('Wallet ID  ${value.masked}', style: _detailStyle),
      ],
    ),
    AsyncError() => Row(
      children: [
        Expanded(
          child: Text(context.tr('Balance unavailable'), style: _detailStyle),
        ),
        IconButton(
          tooltip: context.tr('Try again'),
          onPressed: () => ref.invalidate(walletProvider),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
        ),
      ],
    ),
    _ => const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      ),
    ),
  };
}

/// Service tiles sized by content, not screen width: about 104px per column
/// (4 on phones, more on tablets) and a fixed height that follows text scale.
class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid(this.operations);
  final List<PaymentOperation> operations;

  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static const _codeStyle = TextStyle(fontSize: 10, color: Colors.black45);

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // Icon, gap, two label lines, the code line and a little breathing room.
    final tileHeight =
        52 + 7 + scaler.scale(11) * 1.3 * 2 + scaler.scale(10) * 1.3 + 10;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: operations.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 104,
        mainAxisExtent: tileHeight,
        crossAxisSpacing: 7,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) => _ServiceTile(operations[index]),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile(this.operation);
  final PaymentOperation operation;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => openPaymentFlow(context, operation),
    borderRadius: BorderRadius.circular(17),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xffe7f3ef),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(operation.icon, color: const Color(0xff087f67)),
        ),
        const SizedBox(height: 7),
        Text(
          context.tr(operation.label.split(' (').first),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _ServiceGrid._labelStyle,
        ),
        Text('${operation.code}', style: _ServiceGrid._codeStyle),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(
            context.tr(label),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      context.tr(text),
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w900),
    ),
  );
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: switch (ref.watch(activitiesProvider)) {
        AsyncData(:final value) when value.isEmpty => const EmptyView(
          icon: Icons.receipt_long_outlined,
          message: 'No transactions yet',
          detail: 'Payments you make will appear here.',
        ),
        AsyncData(:final value) => Column(
          children: [
            for (final item in value.take(4)) ActivityTile(item: item),
          ],
        ),
        AsyncError() => ErrorRetryView(
          message: 'Recent activity could not be loaded.',
          onRetry: () => ref.invalidate(activitiesProvider),
        ),
        _ => const LoadingView(),
      },
    ),
  );
}
