const genderOptions = ['Male', 'Female', 'Prefer not to say'];

/// Validates a Malaysian mobile number in any common spacing/format
/// (e.g. "012-345 6789", "+60123456789", "0123456789").
bool isValidMalaysianPhone(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('60')) digits = digits.substring(2);
  if (!digits.startsWith('0')) digits = '0$digits';
  return RegExp(r'^01[0-9]\d{6,8}$').hasMatch(digits);
}
