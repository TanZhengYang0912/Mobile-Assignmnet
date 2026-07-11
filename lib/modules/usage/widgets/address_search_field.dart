import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../services/address_lookup_service.dart';

/// A text field with live Malaysia-restricted address autocomplete
/// (OpenStreetMap Nominatim). Shared by the Profile "edit address" dialog
/// and the registration profile-setup wizard so both enforce the exact same
/// "must resolve to somewhere in Malaysia" rule.
class AddressSearchField extends StatefulWidget {
  final String initialAddress;
  final String? errorText;

  const AddressSearchField({
    super.key,
    this.initialAddress = '',
    this.errorText,
  });

  @override
  State<AddressSearchField> createState() => AddressSearchFieldState();
}

class AddressSearchFieldState extends State<AddressSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  String? _resolvedState;
  bool _searching = false;

  String get currentText => _controller.text.trim();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _resolvedState = null;
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final suggestions = await searchMalaysianAddresses(query);
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (_) {
      // Silently ignore — suggestions are a nice-to-have, not required.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Resolves the current text to a Malaysian address+state. If the user
  /// already picked a suggestion this is instant; otherwise it runs one
  /// last geocode lookup against the typed text. Returns null (with
  /// [error] populated) if it can't be verified as within Malaysia.
  Future<ResolvedAddress?> validate({required void Function(String) onError}) async {
    final address = currentText;
    if (address.isEmpty) {
      onError('Address cannot be empty');
      return null;
    }
    if (_resolvedState != null) {
      return ResolvedAddress(address, _resolvedState!);
    }
    try {
      final matches = await searchMalaysianAddresses(address, limit: 1);
      if (matches.isEmpty) {
        onError(
            'Couldn\'t find this address. Please select a suggestion from the list.');
        return null;
      }
      final state = matches.first.state;
      if (state == null) {
        onError(
            'This address must be within Malaysia. Please select a suggestion from the list.');
        return null;
      }
      return ResolvedAddress(address, state);
    } catch (e) {
      onError('Could not verify address: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Must be a Malaysian address — pick a suggestion for the best match.',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 2,
          minLines: 1,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Address',
            hintText: 'Start typing to search…',
            errorText: widget.errorText,
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.adminPrimary),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 12, endIndent: 12),
              itemBuilder: (ctx, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 18),
                  title:
                      Text(s.displayName, style: const TextStyle(fontSize: 13)),
                  subtitle: s.state == null
                      ? const Text('Outside Malaysia — not selectable',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.critical))
                      : null,
                  enabled: s.state != null,
                  onTap: s.state == null
                      ? null
                      : () {
                          _controller.text = s.displayName;
                          _resolvedState = s.state;
                          setState(() => _suggestions = []);
                        },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
