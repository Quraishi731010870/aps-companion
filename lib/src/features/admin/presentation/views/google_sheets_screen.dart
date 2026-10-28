import 'package:flutter/material.dart';

import '../../data/google_sheets_service.dart';

class GoogleSheetsScreen extends StatefulWidget {
  const GoogleSheetsScreen({super.key});

  @override
  State<GoogleSheetsScreen> createState() => _GoogleSheetsScreenState();
}

class _GoogleSheetsScreenState extends State<GoogleSheetsScreen> {
  final _service = GoogleSheetsService();
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _status = TextEditingController(text: 'Active');

  List<SheetUser> _users = const [];
  String? _error;
  bool _connected = false;
  bool _connecting = false;
  bool _loading = false;
  bool _adding = false;

  @override
  void dispose() {
    _service.dispose();
    _id.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Google Sheets')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _connectionCard(),
        if (_connected) ...[
          const SizedBox(height: 18),
          _usersCard(),
          const SizedBox(height: 18),
          _addUserCard(),
        ],
      ],
    ),
  );

  Widget _connectionCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                !_connected
                    ? Icons.table_chart_outlined
                    : Icons.cloud_done_rounded,
                color: const Color(0xff087f67),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  !_connected
                      ? 'Connect to the Users worksheet'
                      : 'Google Sheets Connected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (_connected) ...[
            const SizedBox(height: 8),
            const Text(
              'Google Apps Script service connected.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
          if (!_connected) ...[
            const SizedBox(height: 8),
            Text(
              _service.isConfigured
                  ? 'Connects through the configured Apps Script service. This shared-token setup is for trusted prototype testing only.'
                  : 'Not configured. Deploy the Apps Script service, add its /exec URL and test token to dart_defines.local.json, then rebuild and reinstall the app.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _connecting || !_service.isConfigured ? null : _connect,
            icon: _connecting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_outlined),
            label: Text(
              _connected ? 'Reconnect service' : 'Connect Google Sheets',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _usersCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Users worksheet',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _refreshUsers,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (_loading)
            const LinearProgressIndicator()
          else if (_users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No user rows found.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _users
                    .map(
                      (user) => DataRow(
                        cells: [
                          DataCell(Text(user.id)),
                          DataCell(Text(user.name)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.phone)),
                          DataCell(Text(user.status)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _addUserCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a test user',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _field(_id, 'ID'),
            _field(_name, 'Name'),
            _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
            _field(_phone, 'Phone', keyboardType: TextInputType.phone),
            _field(_status, 'Status'),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _adding ? null : _addUser,
              icon: _adding
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add User to Google Sheet'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    ),
  );

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final users = await _service.readUsers();
      if (!mounted) return;
      setState(() {
        _connected = true;
        _users = users;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _service.readUsers();
      if (mounted) setState(() => _users = users);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await _service.appendUser(
        SheetUser(
          id: _id.text.trim(),
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          status: _status.text.trim(),
        ),
      );
      if (!mounted) return;
      _formKey.currentState?.reset();
      _id.clear();
      _name.clear();
      _email.clear();
      _phone.clear();
      _status.text = 'Active';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added to Google Sheets.')),
      );
      await _refreshUsers();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}
