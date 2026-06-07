import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import '../models/analytics.dart';

class CountryAnalysisCard extends StatelessWidget {
  final List<BreakdownItem> items;
  final bool isLoading;

  const CountryAnalysisCard({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  String _countryNameToIsoCode(String countryName) {
    // If it's already a 2-letter code, return it
    if (countryName.length == 2) return countryName.toUpperCase();

    final nameToIso = {
      'United States': 'US',
      'United Kingdom': 'GB',
      'United Kingdom of Great Britain and Northern Ireland': 'GB',
      'Canada': 'CA',
      'Australia': 'AU',
      'Germany': 'DE',
      'France': 'FR',
      'Spain': 'ES',
      'Italy': 'IT',
      'Netherlands': 'NL',
      'Brazil': 'BR',
      'Japan': 'JP',
      'South Korea': 'KR',
      'Korea, Republic of': 'KR',
      'China': 'CN',
      'India': 'IN',
      'Mexico': 'MX',
      'Russia': 'RU',
      'Russian Federation': 'RU',
      'South Africa': 'ZA',
      'Sweden': 'SE',
      'Norway': 'NO',
      'Denmark': 'DK',
      'Finland': 'FI',
      'Poland': 'PL',
      'Turkey': 'TR',
      'Argentina': 'AR',
      'Colombia': 'CO',
      'Chile': 'CL',
      'Peru': 'PE',
      'Venezuela': 'VE',
      'Indonesia': 'ID',
      'Malaysia': 'MY',
      'Philippines': 'PH',
      'Singapore': 'SG',
      'Thailand': 'TH',
      'Vietnam': 'VN',
      'Hong Kong': 'HK',
      'Taiwan': 'TW',
      'New Zealand': 'NZ',
      'Ireland': 'IE',
      'Belgium': 'BE',
      'Austria': 'AT',
      'Switzerland': 'CH',
      'Portugal': 'PT',
      'Greece': 'GR',
      'Czech Republic': 'CZ',
      'Czechia': 'CZ',
      'Hungary': 'HU',
      'Romania': 'RO',
      'Ukraine': 'UA',
      'Israel': 'IL',
      'United Arab Emirates': 'AE',
      'Saudi Arabia': 'SA',
      'Egypt': 'EG',
      'Nigeria': 'NG',
      'Kenya': 'KE',
      'Bangladesh': 'BD',
      'Pakistan': 'PK',
      'Sri Lanka': 'LK',
      'Nepal': 'NP',
      'Myanmar': 'MM',
      'Cambodia': 'KH',
      'Laos': 'LA',
    };
    
    // Try exact match first
    if (nameToIso.containsKey(countryName)) {
      return nameToIso[countryName]!;
    }
    
    // Try case-insensitive match
    final lowerName = countryName.toLowerCase();
    for (var entry in nameToIso.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    
    return '';
  }

  String _getCountryFlag(String countryCodeOrName) {
    String isoCode;
    if (countryCodeOrName.length == 2) {
      isoCode = countryCodeOrName.toUpperCase();
    } else {
      isoCode = _countryNameToIsoCode(countryCodeOrName);
    }

    if (isoCode.isEmpty) return '🏳️';
    
    final code = isoCode.toUpperCase();
    
    // Regional indicator symbols start at U+1F1E6 (A)
    // These require surrogate pair encoding in UTF-16
    int firstLetter = 0x1F1E6 + (code.codeUnitAt(0) - 0x41);
    int secondLetter = 0x1F1E6 + (code.codeUnitAt(1) - 0x41);
    
    // Convert to surrogate pairs
    String encodeRune(int rune) {
      if (rune <= 0xFFFF) {
        return String.fromCharCode(rune);
      }
      // Surrogate pair encoding for code points > 0xFFFF
      int code = rune - 0x10000;
      int highSurrogate = 0xD800 + (code >> 10);
      int lowSurrogate = 0xDC00 + (code & 0x3FF);
      return String.fromCharCode(highSurrogate) + String.fromCharCode(lowSurrogate);
    }
    
    return encodeRune(firstLetter) + encodeRune(secondLetter);
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
    
    // Prepare colors for the map
    final Map<String, Color> countryColors = {};
    for (var item in displayItems) {
      String isoCode;
      if (item.key.length == 2) {
        isoCode = item.key.toLowerCase();
      } else {
        isoCode = _countryNameToIsoCode(item.key).toLowerCase();
      }
      
      if (isoCode.isNotEmpty) {
        countryColors[isoCode] = const Color(0xFFF15A24);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E), // Slightly lighter dark background like in image
        borderRadius: BorderRadius.circular(16), // More rounded corners as in image
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Section with CountriesWorldMap
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF25262B),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: SimpleMap(
                instructions: SMapWorld.instructions,
                defaultColor: const Color(0xFF3A3B40),
                countryBorder: CountryBorder(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
                colors: countryColors,
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
