class EmailValidator {
  static const List<String> allowedDomains = [
    '@cmrcet.ac.in',
    '@gmail.com',
  ];
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your email';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }

    bool isAllowedDomain = allowedDomains.any((domain) => value.endsWith(domain));
    
    if (!isAllowedDomain) {
      String allowedDomainsText = allowedDomains.join(', ');
      return 'Email must end with: $allowedDomainsText';
    }

    return null; // Valid email
  }

  /// Quick check if email domain is allowed (without full validation)
  static bool isAllowedDomain(String email) {
    return allowedDomains.any((domain) => email.endsWith(domain));
  }

  /// Get list of allowed domains for display purposes
  static List<String> getAllowedDomains() {
    return List.from(allowedDomains);
  }
}