import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class DomainDnsDetailsScreen extends StatefulWidget {
  final String domain;

  const DomainDnsDetailsScreen({super.key, required this.domain});

  @override
  State<DomainDnsDetailsScreen> createState() => _DomainDnsDetailsScreenState();
}

class _DomainDnsDetailsScreenState extends State<DomainDnsDetailsScreen> {
  Map<String, dynamic>? _domainConfig;
  List<Map<String, dynamic>>? _dnsRecords;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _recordTypeController = TextEditingController();
  final TextEditingController _recordNameController = TextEditingController();
  final TextEditingController _recordValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDomainDetails();
  }

  Future<void> _fetchDomainDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final config = await appState.apiService.getDomainConfiguration(widget.domain);
      final records = await appState.apiService.getDomainDnsRecords(widget.domain);

      if (mounted) {
        setState(() {
          _domainConfig = config;
          _dnsRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.domain, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                  children: [
                    _buildDomainStatus(),
                    const SizedBox(height: 40),
                    _buildDnsRecordsSection(),
                  ],
                ),
    );
  }

  Widget _buildDomainStatus() {
    if (_domainConfig == null) return const SizedBox.shrink();

    final verified = _domainConfig!['verified'] ?? false;
    final nameservers = _domainConfig!['nameservers'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DOMAIN STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verified ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                  border: Border.all(color: verified ? AppTheme.success.withOpacity(0.3) : AppTheme.error.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(verified ? Icons.check_circle : Icons.error, size: 12, color: verified ? AppTheme.success : AppTheme.error),
                    const SizedBox(width: 4),
                    Text(verified ? 'Verified' : 'Unverified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: verified ? AppTheme.success : AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (nameservers.isNotEmpty) ...[
            const Text('NAMESERVERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...nameservers.asMap().entries.map((entry) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 16, color: AppTheme.onSurfaceVariant),
                      onPressed: () => _copyToClipboard(entry.value.toString()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDnsRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('DNS RECORDS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            TextButton.icon(
              onPressed: () => _showAddRecordDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Record'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_dnsRecords == null || _dnsRecords!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Center(
              child: Text('No DNS records configured', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
          )
        else
          ..._dnsRecords!.map((record) => _buildDnsRecordCard(record)),
      ],
    );
  }

  Widget _buildDnsRecordCard(Map<String, dynamic> record) {
    final type = record['type'] ?? 'UNKNOWN';
    final name = record['name'] ?? '@';
    final value = record['value'] ?? '';
    final ttl = record['ttl'] ?? 3600;
    final id = record['id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              if (id.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppTheme.error),
                  onPressed: () => _deleteRecord(id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.toString(),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 16, color: AppTheme.onSurfaceVariant),
                      onPressed: () => _copyToClipboard(value.toString()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('TTL: ${ttl}s', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text('Failed to load domain details', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _fetchDomainDetails, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Add DNS Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _recordTypeController,
              decoration: const InputDecoration(
                labelText: 'Type (A, CNAME, MX, etc.)',
                hintText: 'A',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recordNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: '@',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recordValueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: '192.0.2.1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _addRecord(),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRecord() async {
    final type = _recordTypeController.text.trim();
    final name = _recordNameController.text.trim();
    final value = _recordValueController.text.trim();

    if (type.isEmpty || name.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final appState = context.read<AppState>();
      await appState.apiService.createDnsRecord(widget.domain, {
        'type': type,
        'name': name,
        'value': value,
      });

      _recordTypeController.clear();
      _recordNameController.clear();
      _recordValueController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNS record added successfully')),
        );
        _fetchDomainDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add record: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Delete Record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final appState = context.read<AppState>();
      await appState.apiService.deleteDnsRecord(widget.domain, recordId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNS record deleted')),
        );
        _fetchDomainDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _recordTypeController.dispose();
    _recordNameController.dispose();
    _recordValueController.dispose();
    super.dispose();
  }
}
