import 'package:flutter/material.dart';
import '../models/analytics.dart';

class CountryAnalysisCard extends StatelessWidget {
  final List<BreakdownItem> items;
  final bool isLoading;

  const CountryAnalysisCard({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  String _getCountryFlag(String countryCode) {
    if (countryCode.isEmpty || countryCode.length != 2) return '🏳️';
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

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(5).toList();
    final maxVisitors = displayItems.isNotEmpty ? displayItems.first.visitors : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E), // Slightly lighter dark background like in image
        borderRadius: BorderRadius.circular(16), // More rounded corners as in image
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Section
          AspectRatio(
            aspectRatio: 1.8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _DottedMapPainter(
                  highlightedCountries: displayItems.map((e) => e.key).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24)))
          else if (items.isEmpty)
            Center(
              child: Text(
                'No country data available',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final item = displayItems[index];
                final progress = maxVisitors > 0 ? item.visitors / maxVisitors : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Flag
                      Text(
                        _getCountryFlag(item.key),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                      // Country Name
                      Expanded(
                        child: Text(
                          _getCountryName(item.key),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Visitor Count
                      Text(
                        '${item.visitors}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Progress Bar
                      Container(
                        width: 80,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF15A24),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF15A24).withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DottedMapPainter extends CustomPainter {
  final List<String> highlightedCountries;

  _DottedMapPainter({required this.highlightedCountries});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = const Color(0xFFF15A24).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // This is a very simplified grid of dots representing the world
    const rows = 25;
    const cols = 50;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    // Let's use a more recognizable but simple world map shape
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Simple logic to draw "land" dots
        bool isLand = false;
        
        // North America
        if (r > 3 && r < 10 && c > 5 && c < 15) isLand = true;
        // South America
        if (r >= 10 && r < 18 && c > 10 && c < 15 - (r-10)/2) isLand = true;
        // Europe & Africa
        if (r > 3 && r < 18 && c > 20 && c < 28) isLand = true;
        // Asia
        if (r > 2 && r < 15 && c > 28 && c < 45) isLand = true;
        // Australia
        if (r > 15 && r < 20 && c > 38 && c < 45) isLand = true;

        if (isLand) {
          final center = Offset(c * cellWidth + cellWidth / 2, r * cellHeight + cellHeight / 2);
          
          // Randomly highlight some dots to simulate "activity"
          bool isHighlighted = false;
          if (highlightedCountries.contains('US') && c > 7 && c < 13 && r > 5 && r < 8) isHighlighted = true;
          if (highlightedCountries.contains('GB') && c > 21 && c < 23 && r > 4 && r < 6) isHighlighted = true;
          if (highlightedCountries.contains('DE') && c > 23 && c < 25 && r > 5 && r < 7) isHighlighted = true;
          if (highlightedCountries.contains('IN') && c > 33 && c < 36 && r > 9 && r < 12) isHighlighted = true;
          if (highlightedCountries.contains('CA') && c > 6 && c < 14 && r > 2 && r < 5) isHighlighted = true;
          if (highlightedCountries.contains('FR') && c > 21 && c < 23 && r > 6 && r < 8) isHighlighted = true;

          canvas.drawCircle(center, cellWidth * 0.3, isHighlighted ? highlightPaint : paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
