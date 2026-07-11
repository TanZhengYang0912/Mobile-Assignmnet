import 'dart:convert';

import 'package:http/http.dart' as http;

/// Maps the many ways Nominatim spells a Malaysian state/federal territory
/// onto the canonical names used by BaselineService.statePopulation. KL and
/// Putrajaya have no dedicated government dataset entry of their own, so
/// they fall back to their enclosing state, Selangor.
const Map<String, String> _stateAliases = {
  'selangor': 'Selangor',
  'johor': 'Johor',
  'kedah': 'Kedah',
  'kelantan': 'Kelantan',
  'melaka': 'Melaka',
  'malacca': 'Melaka',
  'negeri sembilan': 'Negeri Sembilan',
  'pahang': 'Pahang',
  'perak': 'Perak',
  'perlis': 'Perlis',
  'pulau pinang': 'Pulau Pinang',
  'penang': 'Pulau Pinang',
  'sabah': 'Sabah',
  'sarawak': 'Sarawak',
  'terengganu': 'Terengganu',
  'labuan': 'W.P. Labuan',
  'wilayah persekutuan labuan': 'W.P. Labuan',
  'kuala lumpur': 'Selangor',
  'wilayah persekutuan kuala lumpur': 'Selangor',
  'putrajaya': 'Selangor',
  'wilayah persekutuan putrajaya': 'Selangor',
};

/// A single Nominatim search result. [state] is null if it couldn't be
/// resolved to a known Malaysian state (including if it's outside Malaysia).
class AddressSuggestion {
  final String displayName;
  final String? state;
  const AddressSuggestion(this.displayName, this.state);
}

/// An address the user has committed to, with its resolved state.
class ResolvedAddress {
  final String address;
  final String state;
  const ResolvedAddress(this.address, this.state);
}

String? _normalizeState(Map<String, dynamic>? address) {
  if (address == null) return null;
  final country = (address['country'] as String?)?.toLowerCase();
  if (country != null && country != 'malaysia') return null;
  final raw = (address['state'] ?? address['state_district']) as String?;
  if (raw == null) return null;
  return _stateAliases[raw.trim().toLowerCase()];
}

/// Searches OpenStreetMap Nominatim for Malaysian addresses matching [query].
Future<List<AddressSuggestion>> searchMalaysianAddresses(
  String query, {
  int limit = 6,
}) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'format': 'json',
    'q': query,
    'countrycodes': 'my',
    'addressdetails': '1',
    'limit': '$limit',
  });
  final response = await http
      .get(uri, headers: {'User-Agent': 'mySumber-App/1.0'})
      .timeout(const Duration(seconds: 8));
  if (response.statusCode != 200) return [];
  final results = jsonDecode(response.body) as List<dynamic>;
  return results.map((r) {
    final map = r as Map<String, dynamic>;
    return AddressSuggestion(
      map['display_name'] as String,
      _normalizeState(map['address'] as Map<String, dynamic>?),
    );
  }).toList();
}
