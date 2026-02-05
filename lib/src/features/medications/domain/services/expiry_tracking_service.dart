/// Service for tracking medication expiry dates and warnings
class ExpiryTrackingService {
  /// Check if a medication will expire soon (within 30 days)
  static bool isExpiringSoon(DateTime? expiry) {
    if (expiry == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiry.difference(now).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }

  /// Check if a medication is already expired
  static bool isExpired(DateTime? expiry) {
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  /// Calculate days until expiry
  /// Returns negative number if already expired
  static int daysUntilExpiry(DateTime? expiry) {
    if (expiry == null) return 999999; // Far future
    return expiry.difference(DateTime.now()).inDays;
  }

  /// Check if medication will expire before running out of stock
  /// This is important for warning users about potential waste
  static bool willExpireBeforeStockout(
    DateTime? expiry,
    DateTime? stockoutDate,
  ) {
    if (expiry == null || stockoutDate == null) return false;
    return expiry.isBefore(stockoutDate);
  }

  /// Get expiry status as a human-readable string
  static String getExpiryStatus(DateTime? expiry) {
    if (expiry == null) return 'No expiry set';
    
    final days = daysUntilExpiry(expiry);
    
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    if (days <= 30) return 'Expires in ${(days / 7).ceil()} weeks';
    if (days <= 90) return 'Expires in ${(days / 30).ceil()} months';
    return 'Expires in ${(days / 365).ceil()} years';
  }

  /// Get expiry warning level
  static ExpiryWarningLevel getWarningLevel(DateTime? expiry) {
    if (expiry == null) return ExpiryWarningLevel.none;
    
    final days = daysUntilExpiry(expiry);
    
    if (days < 0) return ExpiryWarningLevel.expired;
    if (days <= 7) return ExpiryWarningLevel.critical;
    if (days <= 30) return ExpiryWarningLevel.warning;
    if (days <= 90) return ExpiryWarningLevel.notice;
    return ExpiryWarningLevel.none;
  }

  /// Format expiry date for display
  static String formatExpiryDate(DateTime? expiry) {
    if (expiry == null) return 'Not set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    
    if (expiryDay.isAtSameMomentAs(today)) {
      return 'Today';
    }
    
    final tomorrow = today.add(const Duration(days: 1));
    if (expiryDay.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    }
    
    // Format as "MMM d, yyyy"
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[expiry.month - 1]} ${expiry.day}, ${expiry.year}';
  }
}

/// Expiry warning level for color coding
enum ExpiryWarningLevel {
  none,      // > 90 days
  notice,    // 31-90 days
  warning,   // 8-30 days
  critical,  // 1-7 days
  expired,   // < 0 days
}
