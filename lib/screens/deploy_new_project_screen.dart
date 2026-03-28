import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeployNewProjectScreen extends StatelessWidget {
  const DeployNewProjectScreen({super.key});

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
                color: AppTheme.surfaceContainerHigh,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Vero', style: TextStyle(fontWeight: FontWeight.w900)),
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
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        children: [
          const Text(
            'Deploy.',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ship your latest updates to the edge instantly.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),

          _buildSectionLabel('SELECT BRANCH'),
          const SizedBox(height: 16),
          _buildDropdown(),

          const SizedBox(height: 40),
          _buildSectionLabel('SOURCE CODE'),
          const SizedBox(height: 16),
          _buildDropzone(),

          const SizedBox(height: 40),
          _buildBuildSettings(),

          const SizedBox(height: 40),
          _buildDeployButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'main',
          dropdownColor: AppTheme.surfaceContainerHigh,
          icon: const Icon(Icons.expand_more, color: AppTheme.onSurfaceVariant),
          isExpanded: true,
          style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.normal),
          items: const [
            DropdownMenuItem(value: 'main', child: Text('main')),
            DropdownMenuItem(value: 'dev', child: Text('dev')),
            DropdownMenuItem(value: 'feature/ui-update', child: Text('feature/ui-update')),
          ],
          onChanged: (val) {},
        ),
      ),
    );
  }

  Widget _buildDropzone() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.15),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.onSurfaceVariant),
          SizedBox(height: 16),
          Text('Drop files or click to upload', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Manual file upload override', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBuildSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('BUILD SETTINGS'),
              const Text('EDIT', style: TextStyle(fontSize: 11, color: AppTheme.primary, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSettingItem('Root Directory', './')),
              Expanded(child: _buildSettingItem('Install Command', 'npm install')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSettingItem('Build Command', 'npm run build')),
              Expanded(child: _buildSettingItem('Output Directory', '.next')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildDeployButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFFC7C6C6)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Deploy Project',
                  style: TextStyle(
                    color: Color(0xFF1B1C1C),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.bolt, color: Color(0xFF1B1C1C)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
