import 'package:flutter/material.dart';

import '../data/mock_payment_gateway.dart';
import '../domain/payment_transaction.dart';
import '../l10n/app_localizations.dart';
import '../widgets/payment_flow.dart';
import '../widgets/card_link_sheet.dart';
import '../state/app_state.dart';
import 'receipt_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.gateway,
    this.onNotificationsPressed,
  });
  final PaymentGateway gateway;
  final VoidCallback? onNotificationsPressed;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hidden = false;
  String? linkedCard;
  @override
  Widget build(BuildContext context) => SafeArea(
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
                    'Asif Quraishi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
              Text(
                hidden ? '•••••• AFN' : '24,560 AFN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Wallet ID  •••• 7814',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _Action(
                    'Cash in',
                    Icons.add_rounded,
                    () => openPaymentFlow(
                      context,
                      widget.gateway,
                      PaymentOperation.cashIn,
                    ),
                  ),
                  _Action(
                    'Bank push',
                    Icons.send_rounded,
                    () => openPaymentFlow(
                      context,
                      widget.gateway,
                      PaymentOperation.walletToCard,
                    ),
                  ),
                  _Action(
                    'QR Pay',
                    Icons.qr_code_scanner_rounded,
                    () => openPaymentFlow(
                      context,
                      widget.gateway,
                      PaymentOperation.purchase,
                      scanQrOnOpen: true,
                    ),
                  ),
                  _Action(
                    'Cash out',
                    Icons.payments_outlined,
                    () => openPaymentFlow(
                      context,
                      widget.gateway,
                      PaymentOperation.cashOut,
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
              linkedCard ?? context.tr('No card linked'),
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
            onTap: _linkCard,
          ),
        ),
        const SizedBox(height: 23),
        const _Header('Transaction services'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: PaymentOperation.values
              .where(
                (operation) => AppScope.of(
                  context,
                ).featureEnabled(operation.configurationKey, safeDefault: true),
              )
              .length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: .78,
            crossAxisSpacing: 7,
          ),
          itemBuilder: (context, index) {
            final operation = PaymentOperation.values
                .where(
                  (operation) => AppScope.of(context).featureEnabled(
                    operation.configurationKey,
                    safeDefault: true,
                  ),
                )
                .elementAt(index);
            return InkWell(
              onTap: () => openPaymentFlow(context, widget.gateway, operation),
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${operation.code}',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ],
              ),
            );
          },
        ),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: mockActivities
                  .take(4)
                  .map((item) => ActivityTile(item: item))
                  .toList(),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _linkCard() async {
    final card = await showCardLinkSheet(context);
    if (card == null || !mounted) return;
    setState(() => linkedCard = card);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card linked successfully for testing.')),
    );
  }
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

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item});
  final WalletActivity item;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ReceiptScreen(activity: item))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    leading: CircleAvatar(
      backgroundColor: const Color(0xffedf4f1),
      child: Icon(item.operation.icon, color: const Color(0xff087f67)),
    ),
    title: Text(
      context.tr(item.title),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${item.subtitle} • ${item.operation.code}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      '${item.incoming ? '+' : '−'} ${afn(item.amount)}',
      style: TextStyle(
        color: item.incoming ? const Color(0xff087f67) : Colors.black87,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
