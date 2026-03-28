import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DomainsDnsScreen extends StatelessWidget {
  const DomainsDnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
              ),
              child: const Icon(Icons.change_history, size: 20, color: AppTheme.onPrimary),
            ),
            const SizedBox(width: 12),
            const Text('Vercel', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.onSurfaceVariant),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        children: [
          Row(
            children: [
              const Text('ACCOUNT SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              const Text('DOMAINS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Domains',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
          ),
          const SizedBox(height: 8),
          const Text('Manage and configure your custom domains and DNS records.', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.5)),
          
          const SizedBox(height: 48),
          
          // Add Domain Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Enter domain name...',
                      hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLowest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () {},
                  child: const Text('Add', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Domain 1
          _buildDomainCard(
            domain: 'acme.com',
            isValid: true,
            projectAssigned: 'acme-corp-dashboard',
            age: '2y 4m',
          ),
          
          const SizedBox(height: 16),
          
          // Domain 2
          _buildDomainCard(
            domain: 'api.acme.net',
            isValid: false,
            projectAssigned: 'acme-user-api',
            age: '4d',
            errorMessage: 'Invalid Configuration',
            errorDetails: 'Nameservers must be configured to point to Vercel.',
          ),
        ],
      ),
    );
  }

  Widget _buildDomainCard({
    required String domain,
    required bool isValid,
    required String projectAssigned,
    required String age,
    String? errorMessage,
    String? errorDetails,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(domain, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isValid ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.errorContainer.withValues(alpha: 0.1),
                        border: Border.all(color: isValid ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Icon(isValid ? Icons.check_circle : Icons.error, size: 12, color: isValid ? AppTheme.success : AppTheme.error),
                          const SizedBox(width: 4),
                          Text(isValid ? 'Valid' : 'Invalid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isValid ? AppTheme.success : AppTheme.error, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: () {},
                      child: const Text('Edit', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.surfaceContainerHigh),
          
          if (!isValid && errorMessage != null)
            Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.errorContainer.withValues(alpha: 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: AppTheme.error, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                        const SizedBox(height: 4),
                        Text(errorDetails ?? '', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8))),
                        const SizedBox(height: 16),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () {},
                          child: const Text('Verify again', style: TextStyle(color: AppTheme.surface, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PROJECT ASSIGNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(projectAssigned, style: const TextStyle(fontFamily: 'monospace', color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(age, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RENEWAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text('Auto-renew ON', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
