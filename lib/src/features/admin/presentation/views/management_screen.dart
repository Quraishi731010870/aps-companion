import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _adminMenu
        .map((section) => section.filtered(_query))
        .where((section) => section.items.isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('SVRB Admin Portal'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _portalHeader(),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search services, settings, and reports',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          ...sections.map(_sectionTile),
          if (sections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No matching admin services.')),
            ),
        ],
      ),
    );
  }

  Widget _portalHeader() => Card(
    color: const Color(0xffe6f3ef),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xff087f67),
                foregroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings_rounded),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SVRB Admin Portal',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
              _EnvironmentBadge(),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Service configuration, operator controls, customer operations, and ISO 8583 tools.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _InfoChip(
                icon: Icons.person_outline,
                label: 'Admin session not configured',
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: 'Session timeout: 10 min',
              ),
              _InfoChip(icon: Icons.lock_outline, label: 'Draft console'),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _sectionTile(_AdminSection section) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      initiallyExpanded: _query.isNotEmpty,
      leading: CircleAvatar(child: Icon(section.icon)),
      title: Text(
        section.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${section.items.length} menu groups and services'),
      children: section.items.map((item) => _menuItem(item, 0)).toList(),
    ),
  );

  Widget _menuItem(_AdminItem item, int depth) {
    if (item.children.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 12.0 * depth),
        child: ExpansionTile(
          dense: true,
          initiallyExpanded: _query.isNotEmpty,
          leading: Icon(item.icon, size: 21),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          children: item.children
              .map((child) => _menuItem(child, depth + 1))
              .toList(),
        ),
      );
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 24 + 16.0 * depth, right: 18),
      leading: Icon(item.icon, size: 20, color: const Color(0xff087f67)),
      title: Text(item.title),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => item.title == 'ISO 8583 Message Console'
              ? const Iso8583ConsoleScreen()
              : _AdminModuleScreen(item: item),
        ),
      ),
    );
  }
}

class _EnvironmentBadge extends StatelessWidget {
  const _EnvironmentBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffffefd1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'NON-PRODUCTION',
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xff087f67)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _AdminModuleScreen extends StatefulWidget {
  const _AdminModuleScreen({required this.item});

  final _AdminItem item;

  @override
  State<_AdminModuleScreen> createState() => _AdminModuleScreenState();
}

class _AdminModuleScreenState extends State<_AdminModuleScreen> {
  late final Map<String, TextEditingController> _controllers;
  bool _enabled = true;
  String _scope = 'Global';

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final entry in _fieldsFor(widget.item.title).entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.item.title)),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: SwitchListTile(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            secondary: Icon(widget.item.icon, color: const Color(0xff087f67)),
            title: const Text(
              'Service enabled',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Draft setting for this console session'),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _scope,
          decoration: const InputDecoration(labelText: 'Configuration scope'),
          items: const [
            DropdownMenuItem(value: 'Global', child: Text('Global')),
            DropdownMenuItem(value: 'Afghan EMI', child: Text('Afghan EMI')),
            DropdownMenuItem(value: 'Demo Bank', child: Text('Demo Bank')),
          ],
          onChanged: (value) => setState(() => _scope = value ?? _scope),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  _descriptionFor(widget.item.title),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                for (final entry in _controllers.entries) ...[
                  TextField(
                    controller: entry.value,
                    enabled: _enabled,
                    decoration: InputDecoration(labelText: entry.key),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _PrototypeNotice(),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Draft values applied for this screen session only.',
              ),
            ),
          ),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Apply draft'),
        ),
      ],
    ),
  );
}

class _PrototypeNotice extends StatelessWidget {
  const _PrototypeNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xfffff4da),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xff955f00)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Admin screens are prototype drafts. Live changes need an authenticated admin backend, permission checks, persistence, and audit logging.',
          ),
        ),
      ],
    ),
  );
}

class Iso8583ConsoleScreen extends StatefulWidget {
  const Iso8583ConsoleScreen({super.key});

  @override
  State<Iso8583ConsoleScreen> createState() => _Iso8583ConsoleScreenState();
}

class _Iso8583ConsoleScreenState extends State<Iso8583ConsoleScreen> {
  final _mti = TextEditingController(text: '0200');
  final _fields = <int, TextEditingController>{
    3: TextEditingController(text: '000000'),
    4: TextEditingController(text: '000000001000'),
    7: TextEditingController(),
    11: TextEditingController(),
    41: TextEditingController(text: 'AFGHAN01'),
    42: TextEditingController(text: 'EMIMERCHANT0001'),
    49: TextEditingController(text: '971'),
  };

  @override
  void dispose() {
    _mti.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bitmap = _primaryBitmap();
    final populated = _fields.entries
        .where((entry) => entry.value.text.trim().isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('ISO 8583 Message Console')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _PrototypeNotice(),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request message',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mti,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'MTI',
                      helperText: 'Example: 0200 financial request, 0100 authorization, 0800 network management',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  for (final entry in _isoFields.entries) ...[
                    TextField(
                      controller: _fields[entry.key],
                      maxLength: entry.value.length,
                      keyboardType: entry.value.numeric
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText:
                            'DE ${entry.key.toString().padLeft(2, '0')} • ${entry.value.name}',
                        helperText:
                            '${entry.value.length} ${entry.value.numeric ? 'numeric' : 'alphanumeric'} characters${entry.key == 4 ? ' • AFN minor units' : ''}',
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ISO 8583 preview',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  _PreviewLine(label: 'MTI', value: _mti.text),
                  _PreviewLine(label: 'Primary bitmap', value: bitmap),
                  for (final entry in populated)
                    _PreviewLine(
                      label: 'DE ${entry.key.toString().padLeft(2, '0')}',
                      value: entry.value.text,
                    ),
                  const Divider(height: 24),
                  Text(
                    _isValid(bitmap)
                        ? 'Field lengths and numeric fields are valid for this sample profile.'
                        : 'Complete fields using the shown lengths; real processor profiles may differ.',
                    style: TextStyle(
                      color: _isValid(bitmap)
                          ? const Color(0xff087f67)
                          : const Color(0xff955f00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This tool builds a logical primary bitmap and field preview. Wire encoding, MAC/key handling, routing, and live transmission require the processor’s ISO 8583 profile and a secured payment switch.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _primaryBitmap() {
    var bitmap = BigInt.zero;
    for (final entry in _fields.entries) {
      if (entry.value.text.trim().isEmpty) continue;
      bitmap |= BigInt.one << (64 - entry.key);
    }
    return bitmap.toRadixString(16).padLeft(16, '0').toUpperCase();
  }

  bool _isValid(String bitmap) {
    if (!RegExp(r'^0[0-9]00$').hasMatch(_mti.text)) return false;
    if (bitmap == '0000000000000000') return false;
    for (final entry in _fields.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;
      final definition = _isoFields[entry.key]!;
      if (value.length != definition.length) return false;
      if (definition.numeric && !RegExp(r'^\d+$').hasMatch(value)) {
        return false;
      }
    }
    return true;
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    ),
  );
}

class _IsoField {
  const _IsoField(this.name, this.length, {this.numeric = true});
  final String name;
  final int length;
  final bool numeric;
}

const _isoFields = <int, _IsoField>{
  3: _IsoField('Processing code', 6),
  4: _IsoField('Amount, transaction', 12),
  7: _IsoField('Transmission date and time', 10),
  11: _IsoField('Systems trace audit number', 6),
  41: _IsoField('Card acceptor terminal ID', 8, numeric: false),
  42: _IsoField('Card acceptor ID code', 15, numeric: false),
  49: _IsoField('Transaction currency code', 3),
};

Map<String, String> _fieldsFor(String title) {
  if (title.contains('Middleware')) {
    return {
      'Processor profile': 'AF-ISO8583-DEFAULT',
      'Message standard': 'ISO 8583 (profile required)',
      'Connection timeout (seconds)': '30',
      'Reversal policy': 'On timeout, reconcile before reversal',
    };
  }
  if (title.contains('Payment') || title.contains('Currency')) {
    return {
      'Default currency': 'AFN (971)',
      'Transaction ceiling (AFN)': '50000',
      'Settlement timezone': 'Asia/Kabul',
      'Processor profile': 'Not connected',
    };
  }
  if (title.contains('Limit')) {
    return {
      'Daily amount (AFN)': '50000',
      'Monthly amount (AFN)': '250000',
      'Daily transaction count': '25',
      'Reset timezone': 'Asia/Kabul',
    };
  }
  if (title.contains('Password')) {
    return {
      'Minimum length': '10',
      'Maximum login attempts': '5',
      'Lock duration (minutes)': '15',
      'Require multi-factor authentication': 'Enabled',
    };
  }
  if (title.contains('Notification') || title.contains('Mail')) {
    return {
      'Provider': 'Not configured',
      'Default locale': 'English',
      'Retry count': '3',
      'Delivery status callback': 'Not configured',
    };
  }
  if (title.contains('Audit')) {
    return {
      'Retention (days)': '90',
      'Record operator changes': 'Enabled',
      'Record customer access': 'Enabled',
      'Alert severity threshold': 'Warning',
    };
  }
  return {
    'Display name': title,
    'Configuration key': title.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    ),
    'Default locale': 'English',
    'Status': 'Draft',
  };
}

String _descriptionFor(String title) {
  if (title.contains('Middleware')) {
    return 'Transport and processor profile settings. Never store clear PINs or cryptographic keys in this app.';
  }
  if (title.contains('Payment')) {
    return 'Payment routing and transaction policy draft for the selected institution.';
  }
  if (title.contains('Limit')) {
    return 'Customer and merchant velocity controls by amount, count, and cycle.';
  }
  if (title.contains('Operator') || title.contains('Role')) {
    return 'Operator access management, role assignment, and privileged-action policy.';
  }
  return 'Draft controls for $title. Connect this module to a secured admin API to apply production changes.';
}

class _AdminSection {
  const _AdminSection(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<_AdminItem> items;

  _AdminSection filtered(String query) {
    if (query.isEmpty || title.toLowerCase().contains(query.toLowerCase())) {
      return this;
    }
    return _AdminSection(
      title,
      icon,
      items
          .map((item) => item.filtered(query))
          .whereType<_AdminItem>()
          .toList(),
    );
  }
}

class _AdminItem {
  const _AdminItem(this.title, this.icon, {this.children = const []});
  final String title;
  final IconData icon;
  final List<_AdminItem> children;

  _AdminItem? filtered(String query) {
    final normalized = query.toLowerCase();
    if (title.toLowerCase().contains(normalized)) return this;
    final matches = children
        .map((child) => child.filtered(query))
        .whereType<_AdminItem>()
        .toList();
    return matches.isEmpty ? null : _AdminItem(title, icon, children: matches);
  }
}

const _adminMenu = <_AdminSection>[
  _AdminSection('Service Settings', Icons.tune_rounded, [
    _AdminItem('Customer Management', Icons.people_alt_outlined),
    _AdminItem('Customer Devices', Icons.devices_outlined),
    _AdminItem('Customer groups', Icons.groups_outlined),
    _AdminItem('Merchants', Icons.storefront_outlined),
    _AdminItem(
      'Settings',
      Icons.settings_outlined,
      children: [
        _AdminItem('Settings by institution', Icons.account_balance_outlined),
        _AdminItem('System settings', Icons.settings_applications_outlined),
        _AdminItem('Import/Export settings', Icons.import_export_rounded),
      ],
    ),
    _AdminItem(
      'Middleware Settings',
      Icons.hub_outlined,
      children: [
        _AdminItem('ISO 8583 Message Console', Icons.code_rounded),
        _AdminItem('Processor profiles', Icons.account_tree_outlined),
        _AdminItem('Connection monitoring', Icons.monitor_heart_outlined),
        _AdminItem('Message Sending', Icons.send_outlined),
      ],
    ),
    _AdminItem(
      'Password Settings',
      Icons.password_rounded,
      children: [
        _AdminItem('Password Strength Policies', Icons.password_rounded),
        _AdminItem('Password Prohibited Regex Groups', Icons.rule_rounded),
      ],
    ),
    _AdminItem('Login Policies', Icons.login_rounded),
    _AdminItem('Resource Manager', Icons.folder_open_outlined),
    _AdminItem(
      'Content Management & Customization',
      Icons.palette_outlined,
      children: [_AdminItem('Setting up themes', Icons.color_lens_outlined)],
    ),
    _AdminItem('Supported Functions', Icons.checklist_rounded),
    _AdminItem('Regions', Icons.map_outlined),
    _AdminItem('Client Category', Icons.category_outlined),
    _AdminItem('Locales', Icons.language_rounded),
    _AdminItem('Countries', Icons.public_rounded),
    _AdminItem('Payment Settings', Icons.payments_outlined),
    _AdminItem('Loan Forms', Icons.assignment_outlined),
    _AdminItem('Operation Confirmation', Icons.fact_check_outlined),
    _AdminItem(
      'Notification (SMS/Push) settings',
      Icons.notifications_active_outlined,
      children: [
        _AdminItem('Notification (SMS/Push) templates', Icons.article_outlined),
        _AdminItem(
          'Notification (SMS/Push) dictionary',
          Icons.menu_book_outlined,
        ),
        _AdminItem('Push subtypes', Icons.notifications_outlined),
      ],
    ),
    _AdminItem(
      'Mail Settings',
      Icons.mail_outline_rounded,
      children: [
        _AdminItem(
          'Notification (Mail) templates',
          Icons.mark_email_unread_outlined,
        ),
        _AdminItem('Custom (Mail) templates', Icons.edit_document),
      ],
    ),
    _AdminItem(
      'Bank',
      Icons.account_balance_outlined,
      children: [
        _AdminItem('Geo offers', Icons.location_on_outlined),
        _AdminItem('Common Information', Icons.info_outline_rounded),
        _AdminItem('Bank points', Icons.place_outlined),
        _AdminItem('News', Icons.newspaper_outlined),
        _AdminItem('Offers', Icons.local_offer_outlined),
        _AdminItem('Policies', Icons.policy_outlined),
        _AdminItem('Announcements', Icons.campaign_outlined),
        _AdminItem(
          'Institution Information',
          Icons.account_balance_wallet_outlined,
        ),
        _AdminItem('Banner', Icons.image_outlined),
        _AdminItem('Stubs', Icons.receipt_outlined),
      ],
    ),
    _AdminItem(
      'Currency Settings',
      Icons.currency_exchange_rounded,
      children: [
        _AdminItem('Supported Currencies', Icons.payments_outlined),
        _AdminItem('Displayed Exchange Rates', Icons.show_chart_rounded),
      ],
    ),
    _AdminItem(
      'Limits',
      Icons.speed_rounded,
      children: [
        _AdminItem('Cycles', Icons.restart_alt_rounded),
        _AdminItem('Templates', Icons.dashboard_customize_outlined),
        _AdminItem('Schemes', Icons.account_tree_outlined),
      ],
    ),
    _AdminItem(
      'Modules',
      Icons.widgets_outlined,
      children: [_AdminItem('Service Requests', Icons.support_agent_rounded)],
    ),
    _AdminItem(
      'Dictionaries',
      Icons.menu_book_outlined,
      children: [
        _AdminItem('Common dictionaries', Icons.library_books_outlined),
        _AdminItem('Customer dictionaries', Icons.person_search_outlined),
      ],
    ),
    _AdminItem('Content Import', Icons.file_upload_outlined),
    _AdminItem('Message Sending', Icons.send_outlined),
    _AdminItem('Scratch cards', Icons.card_giftcard_outlined),
    _AdminItem('Restriction Management', Icons.block_outlined),
    _AdminItem(
      'Customer Operations Analysis',
      Icons.insights_rounded,
      children: [
        _AdminItem('PFM Expenses Rules', Icons.trending_down_rounded),
        _AdminItem('PFM Income Rules', Icons.trending_up_rounded),
        _AdminItem('Carbon Footprint', Icons.eco_outlined),
      ],
    ),
    _AdminItem('Terms and conditions', Icons.description_outlined),
    _AdminItem('Resource Localization Dictionary', Icons.translate_rounded),
    _AdminItem('Audit Setting', Icons.fact_check_outlined),
    _AdminItem('QR-code Setting', Icons.qr_code_rounded),
    _AdminItem('Info Channel Setting', Icons.rss_feed_rounded),
    _AdminItem('Service Profile Setting', Icons.badge_outlined),
  ]),
  _AdminSection('Session Info', Icons.account_circle_outlined, [
    _AdminItem('Session details', Icons.timer_outlined),
    _AdminItem('Reset All Sessions', Icons.restart_alt_rounded),
    _AdminItem('Cache', Icons.cached_rounded),
    _AdminItem('Reset Cache', Icons.cleaning_services_outlined),
    _AdminItem('Change password', Icons.lock_reset_rounded),
    _AdminItem('Interface locale', Icons.language_rounded),
  ]),
  _AdminSection('Console Settings', Icons.admin_panel_settings_outlined, [
    _AdminItem('Operator Management', Icons.manage_accounts_outlined),
    _AdminItem('Operator Profiles Management', Icons.badge_outlined),
    _AdminItem('Role Management', Icons.admin_panel_settings_outlined),
    _AdminItem('Settings', Icons.settings_outlined),
    _AdminItem('Audit', Icons.fact_check_outlined),
    _AdminItem('Reports', Icons.analytics_outlined),
    _AdminItem('Notification logs', Icons.notifications_outlined),
    _AdminItem('Restrictions', Icons.block_outlined),
    _AdminItem('Customer restrictions', Icons.person_off_outlined),
    _AdminItem('Restrictions by lock reason', Icons.lock_clock_outlined),
    _AdminItem('Profiles', Icons.account_box_outlined),
    _AdminItem('Operator reports', Icons.assessment_outlined),
    _AdminItem('Integration table', Icons.table_chart_outlined),
  ]),
  _AdminSection('Operator Workspace', Icons.workspaces_outlined, [
    _AdminItem('Client Management', Icons.phone_android_outlined),
    _AdminItem('Customer profiles', Icons.account_box_outlined),
    _AdminItem('Customer restrictions', Icons.person_off_outlined),
    _AdminItem('Restrictions by lock reason', Icons.lock_clock_outlined),
    _AdminItem('Operator reports', Icons.assessment_outlined),
  ]),
  _AdminSection('Reports', Icons.analytics_outlined, [
    _AdminItem('Operations for period', Icons.receipt_long_outlined),
    _AdminItem('Build operator report', Icons.summarize_outlined),
    _AdminItem('Report templates', Icons.description_outlined),
  ]),
  _AdminSection('Dynamic Platform', Icons.dynamic_form_outlined, [
    _AdminItem('Dynamic operations', Icons.dynamic_form_outlined),
    _AdminItem(
      'Operation settings',
      Icons.tune_rounded,
      children: [
        _AdminItem('Dynamic operation limits', Icons.speed_rounded),
        _AdminItem('Terms and conditions', Icons.description_outlined),
        _AdminItem('Dynamic operation steps', Icons.account_tree_outlined),
        _AdminItem('Step parameters', Icons.tune_rounded),
        _AdminItem('Step field conditions', Icons.rule_rounded),
        _AdminItem('Step processing rules', Icons.settings_suggest_outlined),
      ],
    ),
    _AdminItem('Dynamic operation groups', Icons.group_work_outlined),
    _AdminItem('Parameter mappings', Icons.compare_arrows_rounded),
    _AdminItem('Dynamic objects', Icons.data_object_rounded),
    _AdminItem('Dynamic structures', Icons.schema_outlined),
    _AdminItem('Static operations', Icons.list_alt_rounded),
    _AdminItem('Client subtypes', Icons.category_outlined),
    _AdminItem(
      'Flexible Payment Engine',
      Icons.account_balance_wallet_outlined,
    ),
    _AdminItem('Maker-checker operations', Icons.fact_check_outlined),
    _AdminItem('Transfer settings to another stand', Icons.swap_horiz_rounded),
    _AdminItem(
      'Deprecated',
      Icons.warning_amber_outlined,
      children: [_AdminItem('Deprecated integration API', Icons.api_outlined)],
    ),
  ]),
];
