import 'package:flutter/material.dart';
import '../models/analytics.dart';
import '../theme/app_theme.dart';

class AnalyticsBreakdownCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<BreakdownItem> items;
  final String emptyLabel;
  final List<Color> colorPalette;
  final Function(String)? onItemTap;

  const AnalyticsBreakdownCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    this.emptyLabel = 'No data available',
    this.colorPalette = const [AppTheme.onSurfaceVariant],
    this.onItemTap,
  });

  bool get _isCountries => title.toLowerCase() == 'countries';
  bool get _isBrowsers => title.toLowerCase() == 'browsers';
  bool get _isDevices => title.toLowerCase() == 'devices';

  String _getCountryFlag(String countryCode) {
    if (countryCode.isEmpty || countryCode.length != 2) return '';
    // Convert 2-letter country code to flag emoji using regional indicator symbols
    final code = countryCode.toUpperCase();
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  String _getCountryName(String countryCode) {
    if (countryCode.isEmpty || countryCode.length != 2) return countryCode;
    
    final code = countryCode.toUpperCase();
    final countryNames = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'ES': 'Spain',
      'IT': 'Italy',
      'NL': 'Netherlands',
      'BR': 'Brazil',
      'JP': 'Japan',
      'KR': 'South Korea',
      'CN': 'China',
      'IN': 'India',
      'MX': 'Mexico',
      'RU': 'Russia',
      'ZA': 'South Africa',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'PL': 'Poland',
      'TR': 'Turkey',
      'AR': 'Argentina',
      'CO': 'Colombia',
      'CL': 'Chile',
      'PE': 'Peru',
      'VE': 'Venezuela',
      'ID': 'Indonesia',
      'MY': 'Malaysia',
      'PH': 'Philippines',
      'SG': 'Singapore',
      'TH': 'Thailand',
      'VN': 'Vietnam',
      'HK': 'Hong Kong',
      'TW': 'Taiwan',
      'NZ': 'New Zealand',
      'IE': 'Ireland',
      'BE': 'Belgium',
      'AT': 'Austria',
      'CH': 'Switzerland',
      'PT': 'Portugal',
      'GR': 'Greece',
      'CZ': 'Czech Republic',
      'HU': 'Hungary',
      'RO': 'Romania',
      'UA': 'Ukraine',
      'IL': 'Israel',
      'AE': 'United Arab Emirates',
      'SA': 'Saudi Arabia',
      'EG': 'Egypt',
      'NG': 'Nigeria',
      'KE': 'Kenya',
      'BD': 'Bangladesh',
      'PK': 'Pakistan',
      'LK': 'Sri Lanka',
      'NP': 'Nepal',
      'MM': 'Myanmar',
      'KH': 'Cambodia',
      'LA': 'Laos',
    };
    
    return countryNames[code] ?? countryCode;
  }

  IconData _getBrowserIcon(String browserName) {
    final name = browserName.toLowerCase();
    
    // Map common browser names to appropriate Material icons
    if (name.contains('chrome')) {
      return Icons.circle; // Chrome uses a circular logo
    } else if (name.contains('safari')) {
      return Icons.compass_calibration; // Compass-like icon for Safari
    } else if (name.contains('firefox')) {
      return Icons.whatshot; // Fire-like icon for Firefox
    } else if (name.contains('edge') || name.contains('edg')) {
      return Icons.waves; // Wave-like icon for Edge
    } else if (name.contains('opera')) {
      return Icons.theater_comedy; // Theater mask for Opera
    } else if (name.contains('brave')) {
      return Icons.shield; // Shield for Brave
    } else if (name.contains('vivaldi')) {
      return Icons.music_note; // Music note for Vivaldi
    } else if (name.contains('samsung') || name.contains('internet')) {
      return Icons.phone_android; // Android browser
    } else if (name.contains('uc')) {
      return Icons.web; // Generic web icon for UC Browser
    } else {
      return Icons.public; // Generic browser icon
    }
  }

  Color _getBrowserColor(String browserName) {
    final name = browserName.toLowerCase();
    
    // Return brand colors for browsers
    if (name.contains('chrome')) {
      return const Color(0xFF4285F4); // Google Blue
    } else if (name.contains('safari')) {
      return const Color(0xFF006CFF); // Safari Blue
    } else if (name.contains('firefox')) {
      return const Color(0xFFFF7139); // Firefox Orange
    } else if (name.contains('edge') || name.contains('edg')) {
      return const Color(0xFF0078D4); // Edge Blue
    } else if (name.contains('opera')) {
      return const Color(0xFFFF1B2D); // Opera Red
    } else if (name.contains('brave')) {
      return const Color(0xFFF47242); // Brave Orange
    } else if (name.contains('vivaldi')) {
      return const Color(0xFFEF3939); // Vivaldi Red
    } else if (name.contains('samsung') || name.contains('internet')) {
      return const Color(0xFF1428A0); // Samsung Blue
    } else {
      return AppTheme.onSurfaceVariant; // Default color
    }
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    
    // Map common device types to appropriate Material icons
    if (name.contains('desktop') || name.contains('pc')) {
      return Icons.desktop_windows;
    } else if (name.contains('mobile') || name.contains('phone')) {
      return Icons.smartphone;
    } else if (name.contains('tablet') || name.contains('ipad')) {
      return Icons.tablet;
    } else if (name.contains('iphone')) {
      return Icons.phone_iphone;
    } else if (name.contains('android')) {
      return Icons.phone_android;
    } else if (name.contains('ios')) {
      return Icons.phone_iphone;
    } else if (name.contains('mac')) {
      return Icons.laptop_mac;
    } else if (name.contains('laptop')) {
      return Icons.laptop;
    } else if (name.contains('watch')) {
      return Icons.watch;
    } else if (name.contains('tv')) {
      return Icons.tv;
    } else {
      return Icons.devices; // Generic device icon
    }
  }

  Color _getDeviceColor(String deviceName) {
    final name = deviceName.toLowerCase();
    
    // Return colors for different device types
    if (name.contains('desktop') || name.contains('pc')) {
      return const Color(0xFF607D8B); // Blue Grey
    } else if (name.contains('mobile') || name.contains('phone')) {
      return const Color(0xFF4CAF50); // Green
    } else if (name.contains('tablet') || name.contains('ipad')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (name.contains('iphone')) {
      return const Color(0xFF2196F3); // Blue
    } else if (name.contains('android')) {
      return const Color(0xFF4CAF50); // Android Green
    } else if (name.contains('ios')) {
      return const Color(0xFF2196F3); // iOS Blue
    } else if (name.contains('mac')) {
      return const Color(0xFF9E9E9E); // Grey
    } else if (name.contains('laptop')) {
      return const Color(0xFF795548); // Brown
    } else if (name.contains('watch')) {
      return const Color(0xFFE91E63); // Pink
    } else if (name.contains('tv')) {
      return const Color(0xFFFF9800); // Orange
    } else {
      return AppTheme.onSurfaceVariant; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant.withOpacity(0.8),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'VISITORS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceContainerHigh),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  emptyLabel,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 8 ? 8 : items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.surfaceContainerHigh),
              itemBuilder: (context, index) {
                final item = items[index];
                final maxVisitors = items.first.visitors;
                final progress = maxVisitors > 0 ? item.visitors / maxVisitors : 0.0;
                final color = colorPalette[index % colorPalette.length];

                final row = _buildRow(context, item, progress, color);
                
                if (onItemTap != null) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onItemTap!(item.key),
                      behavior: HitTestBehavior.translucent,
                      child: row,
                    ),
                  );
                }
                
                return row;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, BreakdownItem item, double progress, Color color) {
    final flag = _isCountries ? _getCountryFlag(item.key) : '';
    final displayName = item.key.isEmpty 
        ? 'Direct / Unknown' 
        : _isCountries 
            ? _getCountryName(item.key) 
            : item.key;
    final browserIcon = _isBrowsers ? _getBrowserIcon(item.key) : null;
    final browserColor = _isBrowsers ? _getBrowserColor(item.key) : null;
    final deviceIcon = _isDevices ? _getDeviceIcon(item.key) : null;
    final deviceColor = _isDevices ? _getDeviceColor(item.key) : null;
    
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Progress bar background
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
                // Text overlay
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          if (flag.isNotEmpty) ...[
                            Text(
                              flag,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (browserIcon != null) ...[
                            Icon(
                              browserIcon,
                              size: 16,
                              color: browserColor,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (deviceIcon != null) ...[
                            Icon(
                              deviceIcon,
                              size: 16,
                              color: deviceColor,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 50,
            child: Text(
              '${item.visitors}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
