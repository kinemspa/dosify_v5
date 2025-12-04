import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/expiry_tracking_service.dart';

void main() {
  group('ExpiryTrackingService', () {
    group('isExpiringSoon', () {
      test('returns true when expiry is within 30 days', () {
        final expiry = DateTime.now().add(const Duration(days: 20));
        expect(ExpiryTrackingService.isExpiringSoon(expiry), true);
      });

      test('returns false when expiry is more than 30 days away', () {
        final expiry = DateTime.now().add(const Duration(days: 40));
        expect(ExpiryTrackingService.isExpiringSoon(expiry), false);
      });

      test('returns false when expiry is null', () {
        expect(ExpiryTrackingService.isExpiringSoon(null), false);
      });

      test('returns false when already expired', () {
        final expiry = DateTime.now().subtract(const Duration(days: 5));
        expect(ExpiryTrackingService.isExpiringSoon(expiry), false);
      });
    });

    group('isExpired', () {
      test('returns true when date is in the past', () {
        final expiry = DateTime.now().subtract(const Duration(days: 1));
        expect(ExpiryTrackingService.isExpired(expiry), true);
      });

      test('returns false when date is in the future', () {
        final expiry = DateTime.now().add(const Duration(days: 1));
        expect(ExpiryTrackingService.isExpired(expiry), false);
      });

      test('returns false when expiry is null', () {
        expect(ExpiryTrackingService.isExpired(null), false);
      });
    });

    group('daysUntilExpiry', () {
      test('returns positive number for future date', () {
        final expiry = DateTime.now().add(const Duration(days: 10));
        final days = ExpiryTrackingService.daysUntilExpiry(expiry);
        expect(days, greaterThanOrEqualTo(9)); // Account for time of day
        expect(days, lessThanOrEqualTo(10));
      });

      test('returns negative number for past date', () {
        final expiry = DateTime.now().subtract(const Duration(days: 5));
        final days = ExpiryTrackingService.daysUntilExpiry(expiry);
        expect(days, lessThan(0));
      });

      test('returns large number when expiry is null', () {
        expect(ExpiryTrackingService.daysUntilExpiry(null), 999999);
      });
    });

    group('willExpireBeforeStockout', () {
      test('returns true when expiry is before stockout', () {
        final expiry = DateTime.now().add(const Duration(days: 10));
        final stockout = DateTime.now().add(const Duration(days: 20));
        
        expect(
          ExpiryTrackingService.willExpireBeforeStockout(expiry, stockout),
          true,
        );
      });

      test('returns false when expiry is after stockout', () {
        final expiry = DateTime.now().add(const Duration(days: 30));
        final stockout = DateTime.now().add(const Duration(days: 20));
        
        expect(
          ExpiryTrackingService.willExpireBeforeStockout(expiry, stockout),
          false,
        );
      });

      test('returns false when either date is null', () {
        final expiry = DateTime.now().add(const Duration(days: 10));
        
        expect(
          ExpiryTrackingService.willExpireBeforeStockout(null, expiry),
          false,
        );
        expect(
          ExpiryTrackingService.willExpireBeforeStockout(expiry, null),
          false,
        );
      });
    });

    group('getExpiryStatus', () {
      test('returns "No expiry set" when null', () {
        expect(ExpiryTrackingService.getExpiryStatus(null), 'No expiry set');
      });

      test('returns "Expired" when in past', () {
        final expiry = DateTime.now().subtract(const Duration(days: 5));
        expect(ExpiryTrackingService.getExpiryStatus(expiry), 'Expired');
      });

      test('returns "Expires today" when expiring today', () {
        final expiry = DateTime.now();
        expect(ExpiryTrackingService.getExpiryStatus(expiry), 'Expires today');
      });

      test('returns day count for near future', () {
        final expiry = DateTime.now().add(const Duration(days: 5));
        final status = ExpiryTrackingService.getExpiryStatus(expiry);
        expect(status, contains('days'));
      });
    });

    group('getWarningLevel', () {
      test('returns none when no expiry', () {
        expect(
          ExpiryTrackingService.getWarningLevel(null),
          ExpiryWarningLevel.none,
        );
      });

      test('returns expired when in past', () {
        final expiry = DateTime.now().subtract(const Duration(days: 1));
        expect(
          ExpiryTrackingService.getWarningLevel(expiry),
          ExpiryWarningLevel.expired,
        );
      });

      test('returns critical when within 7 days', () {
        final expiry = DateTime.now().add(const Duration(days: 5));
        expect(
          ExpiryTrackingService.getWarningLevel(expiry),
          ExpiryWarningLevel.critical,
        );
      });

      test('returns warning when within 30 days', () {
        final expiry = DateTime.now().add(const Duration(days: 20));
        expect(
          ExpiryTrackingService.getWarningLevel(expiry),
          ExpiryWarningLevel.warning,
        );
      });

      test('returns notice when within 90 days', () {
        final expiry = DateTime.now().add(const Duration(days: 60));
        expect(
          ExpiryTrackingService.getWarningLevel(expiry),
          ExpiryWarningLevel.notice,
        );
      });

      test('returns none when far in future', () {
        final expiry = DateTime.now().add(const Duration(days: 365));
        expect(
          ExpiryTrackingService.getWarningLevel(expiry),
          ExpiryWarningLevel.none,
        );
      });
    });

    group('formatExpiryDate', () {
      test('returns "Not set" when null', () {
        expect(ExpiryTrackingService.formatExpiryDate(null), 'Not set');
      });

      test('returns "Today" for today', () {
        final expiry = DateTime.now();
        expect(ExpiryTrackingService.formatExpiryDate(expiry), 'Today');
      });

      test('returns "Tomorrow" for tomorrow', () {
        final expiry = DateTime.now().add(const Duration(days: 1));
        expect(ExpiryTrackingService.formatExpiryDate(expiry), 'Tomorrow');
      });

      test('formats date correctly', () {
        final expiry = DateTime(2025, 6, 15);
        expect(ExpiryTrackingService.formatExpiryDate(expiry), 'Jun 15, 2025');
      });
    });
  });
}
