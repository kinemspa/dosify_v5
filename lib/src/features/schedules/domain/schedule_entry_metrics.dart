import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

class ScheduleEntryMetrics {
  const ScheduleEntryMetrics._();

  static String format(Schedule schedule) {
    String trimZerosNumber(double value, {int decimals = 3}) {
      var s = value.toStringAsFixed(decimals);
      if (s.contains('.')) {
        s = s.replaceAll(RegExp(r'0+$'), '');
        if (s.endsWith('.')) s = s.substring(0, s.length - 1);
      }
      return s;
    }

    String formatMass(int mcg) {
      if (mcg >= 1000000) {
        final g = mcg / 1000000.0;
        return '${trimZerosNumber(g, decimals: 2)} g';
      }
      if (mcg >= 1000) {
        final mg = mcg / 1000.0;
        return '${trimZerosNumber(mg, decimals: 2)} mg';
      }
      return '${trimZerosNumber(mcg.toDouble(), decimals: 0)} mcg';
    }

    String formatVolume(int microliters) {
      final ml = microliters / 1000.0;
      return '${trimZerosNumber(ml, decimals: 3)} mL';
    }

    String formatCount(double count, String singular) {
      final label = (count == 1) ? singular : '${singular}s';
      return '${trimZerosNumber(count, decimals: 3)} $label';
    }

    String? countPart;
    final q = schedule.entryTabletQuarters;
    if (q != null) {
      final count = q / 4.0;
      String amount;
      if (q == 1) {
        amount = '1/4';
      } else if (q == 2) {
        amount = '1/2';
      } else if (q == 3) {
        amount = '3/4';
      } else if (q % 4 == 0) {
        amount = (q ~/ 4).toString();
      } else {
        amount = trimZerosNumber(count, decimals: 3);
      }

      final label = (count == 1) ? 'tablet' : 'tablets';
      countPart = '$amount $label';
    } else if (schedule.entryCapsules != null) {
      countPart = formatCount(schedule.entryCapsules!.toDouble(), 'capsule');
    } else if (schedule.entrySyringes != null) {
      countPart = formatCount(schedule.entrySyringes!.toDouble(), 'syringe');
    } else if (schedule.entryVials != null) {
      countPart = formatCount(schedule.entryVials!.toDouble(), 'vial');
    }

    final parts = <String>[];
    if (countPart != null && countPart.isNotEmpty) {
      parts.add(countPart);
    }

    if (schedule.entryMassMcg != null) {
      parts.add(formatMass(schedule.entryMassMcg!));
    }

    if (schedule.entryVolumeMicroliter != null) {
      parts.add(formatVolume(schedule.entryVolumeMicroliter!));
    }

    if (schedule.entryIU != null) {
      parts.add('${schedule.entryIU} units');
    }

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    // Fallback (legacy)
    final legacy = '${trimZerosNumber(schedule.entryValue, decimals: 3)} ${schedule.entryUnit}'.trim();
    return legacy;
  }
}
