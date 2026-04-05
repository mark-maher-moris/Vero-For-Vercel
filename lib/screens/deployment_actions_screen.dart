import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../providers/app_state.dart';
import '../screens/deployment_files_screen.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';

class DeploymentActionsScreen extends StatefulWidget {
  final Deployment deployment;
  final String projectId;

  const DeploymentActionsScreen({
    super.key,
    required this.deployment,
    required this.projectId,
  });

  @override
  State<DeploymentActionsScreen> createState() => _DeploymentActionsScreenState();
}

class _DeploymentActionsScreenState extends State<DeploymentActionsScreen> {
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final isPro = subscription.isPro;
    
    final isProduction = widget.deployment.state == 'READY' && widget.deployment.target == 'production';
    final canPromote = widget.deployment.state == 'READY' && widget.deployment.target != 'production';
    final canRollback = isProduction;
    final canCancel = widget.deployment.state == 'BUILDING' || widget.deployment.state == 'QUEUED';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Deployment Actions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
        children: [
          _buildDeploymentInfo(),
          const SizedBox(height: 40),
          _buildFilesAction(),
          const SizedBox(height: 24),
          _buildActionsSection(canPromote, canRollback, canCancel, isPro),
          if (_successMessage != null) ...[
            const SizedBox(height: 24),
            _buildSuccessMessage(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            _buildErrorMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeploymentInfo() {
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
            children: [
              Text('DEPLOYMENT', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStateColor(widget.deployment.state).withOpacity(0.1),
                  border: Border.all(color: _getStateColor(widget.deployment.state).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStateIcon(widget.deployment.state), size: 12, color: _getStateColor(widget.deployment.state)),
                    const SizedBox(width: 4),
                    Text(widget.deployment.state, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStateColor(widget.deployment.state))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.deployment.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 8),
          Text('Created ${timeago.format(DateTime.fromMillisecondsSinceEpoch(widget.deployment.created))}', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TARGET', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text(widget.deployment.target?.toUpperCase() ?? 'PREVIEW', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('URL', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text(widget.deployment.url, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INSPECTION', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        _buildActionButton(
          label: 'View Source Files',
          description: 'Browse the files included in this deployment',
          icon: Icons.folder,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeploymentFilesScreen(deployment: widget.deployment),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(bool canPromote, bool canRollback, bool canCancel, bool isPro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACTIONS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        if (canPromote) ...[
          _buildActionButton(
            label: 'Promote to Production',
            description: 'Make this deployment the live production version',
            icon: Icons.arrow_upward,
            color: AppTheme.primary,
            onTap: _isLoading ? null : (isPro ? _promoteDeployment : () => SuperwallService().presentPaywall()),
            isLocked: !isPro,
          ),
          const SizedBox(height: 12),
        ],
        if (canRollback) ...[
          _buildActionButton(
            label: 'Rollback Deployment',
            description: 'Revert to the previous production deployment',
            icon: Icons.history,
            color: Colors.orange,
            onTap: _isLoading ? null : (isPro ? _rollbackDeployment : () => SuperwallService().presentPaywall()),
            isLocked: !isPro,
          ),
          const SizedBox(height: 12),
        ],
        if (canCancel) ...[
          _buildActionButton(
            label: 'Cancel Deployment',
            description: 'Stop this deployment from completing',
            icon: Icons.stop_circle,
            color: AppTheme.error,
            onTap: _isLoading ? null : _cancelDeployment,
          ),
          const SizedBox(height: 12),
        ],
        if (!canPromote && !canRollback && !canCancel)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: AppTheme.onSurfaceVariant, size: 20),
                const SizedBox(height: 12),
                const Text('No actions available', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('This deployment cannot be promoted, rolled back, or cancelled in its current state.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            border: Border.all(color: isLocked ? AppTheme.outlineVariant.withOpacity(0.2) : color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLocked ? AppTheme.surfaceContainerHigh : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(isLocked ? Icons.lock : icon, color: isLocked ? AppTheme.onSurfaceVariant : color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? AppTheme.onSurfaceVariant : AppTheme.onSurface)),
                        if (isLocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
              else
                Icon(isLocked ? Icons.arrow_forward_ios : Icons.arrow_forward, color: isLocked ? AppTheme.onSurfaceVariant.withOpacity(0.5) : color, size: isLocked ? 14 : 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_successMessage!, style: TextStyle(fontSize: 14, color: AppTheme.success, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: AppTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: TextStyle(fontSize: 14, color: AppTheme.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _promoteDeployment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      await appState.apiService.promoteDeployment(
        projectId: widget.projectId,
        deploymentId: widget.deployment.uid,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Deployment promoted to production successfully!';
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to promote deployment: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rollbackDeployment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      await appState.apiService.rollbackDeployment(
        projectId: widget.projectId,
        deploymentId: widget.deployment.uid,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Deployment rolled back successfully!';
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to rollback deployment: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelDeployment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      await appState.apiService.cancelDeployment(
        projectId: widget.projectId,
        deploymentId: widget.deployment.uid,
      );
      if (mounted) {
        setState(() {
          _successMessage = 'Deployment cancelled successfully!';
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to cancel deployment: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'READY':
        return AppTheme.success;
      case 'ERROR':
        return AppTheme.error;
      case 'BUILDING':
      case 'QUEUED':
        return Colors.orange;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state) {
      case 'READY':
        return Icons.check_circle;
      case 'ERROR':
        return Icons.error;
      case 'BUILDING':
        return Icons.hourglass_bottom;
      case 'QUEUED':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }
}
