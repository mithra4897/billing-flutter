import 'package:get/get.dart';

import 'app_format_settings.dart';

String displayTodayDate() => displayDate(DateTime.now().toIso8601String());

String dateFormatHint() {
  final format = Get.isRegistered<AppFormatSettings>()
      ? AppFormatSettings.to.dateFormat.value
      : AppFormatSettings.defaultDateFormat;
  return format.replaceAll('yyyy', 'YYYY').replaceAll('dd', 'DD');
}

String dateTimeFormatHint() => '${dateFormatHint()} HH:MM:SS';

String normalizeDateValue(String? value) {
  final normalized = normalizeDateForApi(value);
  final raw = normalized.split('T').first.split(' ').first.trim();
  if (raw.isEmpty) {
    return '';
  }
  final parts = raw.split('-');
  if (parts.length != 3) {
    return raw;
  }
  final year = parts[0];
  final month = parts[1];
  final day = parts[2];
  final fmt = Get.isRegistered<AppFormatSettings>()
      ? AppFormatSettings.to.dateFormat.value
      : AppFormatSettings.defaultDateFormat;
  return fmt
      .replaceAll('yyyy', year)
      .replaceAll('MM', month)
      .replaceAll('dd', day);
}

String normalizeDateTimeValue(String? value) {
  final normalized = normalizeDateTimeForApi(value);
  final parsed = parseNormalizedDateTimeValue(normalized);
  if (parsed == null) {
    return (value ?? '').trim();
  }

  final date = normalizeDateValue(
    '${parsed.year.toString().padLeft(4, '0')}-'
    '${parsed.month.toString().padLeft(2, '0')}-'
    '${parsed.day.toString().padLeft(2, '0')}',
  );
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  final second = parsed.second.toString().padLeft(2, '0');
  return '$date $hour:$minute:$second';
}

String normalizeDateForApi(String? value) {
  final parsed = parseNormalizedDateValue(value);
  if (parsed == null) {
    return (value ?? '').trim();
  }
  final year = parsed.year.toString().padLeft(4, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String normalizeDateTimeForApi(String? value) {
  final parsed = parseNormalizedDateTimeValue(value);
  if (parsed == null) {
    return (value ?? '').trim();
  }
  final year = parsed.year.toString().padLeft(4, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  final second = parsed.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}

Map<String, dynamic> normalizeDatePayload(Map<String, dynamic> payload) {
  return payload.map(
    (key, value) => MapEntry(key, _normalizeDatePayloadValue(key, value)),
  );
}

dynamic _normalizeDatePayloadValue(String key, dynamic value) {
  if (value is Map<String, dynamic>) {
    return normalizeDatePayload(value);
  }
  if (value is List) {
    return value
        .map(
          (entry) => entry is Map<String, dynamic>
              ? normalizeDatePayload(entry)
              : entry,
        )
        .toList(growable: false);
  }
  if (value is! String) {
    return value;
  }
  if (_isDateTimePayloadKey(key)) {
    final normalized = normalizeDateTimeForApi(value);
    return normalized.isEmpty ? value : normalized;
  }
  if (!_isDatePayloadKey(key)) {
    return value;
  }
  final normalized = normalizeDateForApi(value);
  return normalized.isEmpty ? value : normalized;
}

bool _isDateTimePayloadKey(String key) {
  final words = _payloadKeyWords(key);
  return words.contains('datetime') || words.contains('followup');
}

bool _isDatePayloadKey(String key) {
  final words = _payloadKeyWords(key);
  if (words.contains('datetime')) {
    return false;
  }
  return words.contains('date') || words.contains('until');
}

List<String> _payloadKeyWords(String key) {
  return key
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part.toLowerCase())
      .toList(growable: false);
}

DateTime? parseNormalizedDateValue(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return null;
  }

  final raw = text.split('T').first.split(' ').first.trim();
  if (raw.isEmpty) {
    return null;
  }

  final isoParsed = DateTime.tryParse(raw);
  if (isoParsed != null) {
    return DateTime(isoParsed.year, isoParsed.month, isoParsed.day);
  }

  final fmt = Get.isRegistered<AppFormatSettings>()
      ? AppFormatSettings.to.dateFormat.value
      : AppFormatSettings.defaultDateFormat;
  final separatorMatch = RegExp(r'[^A-Za-z]').firstMatch(fmt);
  final separator = separatorMatch?.group(0);
  if (separator == null || separator.isEmpty) {
    return null;
  }

  final formatParts = fmt.split(separator);
  final valueParts = raw.split(separator);
  if (formatParts.length != 3 || valueParts.length != 3) {
    return null;
  }

  int? year;
  int? month;
  int? day;
  for (var index = 0; index < 3; index++) {
    final token = formatParts[index];
    final part = valueParts[index].trim();
    final parsed = int.tryParse(part);
    if (parsed == null) {
      return null;
    }
    switch (token) {
      case 'yyyy':
        year = parsed;
        break;
      case 'MM':
        month = parsed;
        break;
      case 'dd':
        day = parsed;
        break;
      default:
        return null;
    }
  }

  if (year == null || month == null || day == null) {
    return null;
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

DateTime? parseNormalizedDateTimeValue(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return null;
  }

  final direct = DateTime.tryParse(text.replaceFirst(' ', 'T'));
  if (direct != null) {
    return direct.isUtc ? direct.toLocal() : direct;
  }

  final parts = text.split(RegExp(r'\s+'));
  if (parts.length < 2) {
    return null;
  }

  final date = parseNormalizedDateValue(parts.first);
  if (date == null) {
    return null;
  }

  final timeParts = parts[1].split(':');
  if (timeParts.length < 2 || timeParts.length > 3) {
    return null;
  }

  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  final second = timeParts.length == 3 ? int.tryParse(timeParts[2]) : 0;
  if (hour == null ||
      minute == null ||
      second == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59 ||
      second < 0 ||
      second > 59) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
    second,
  );
}

bool matchesDateValueRange(
  String? value, {
  String? fromValue,
  String? toValue,
}) {
  final fromDate = parseNormalizedDateValue(fromValue);
  final toDate = parseNormalizedDateValue(toValue);
  if (fromDate == null && toDate == null) {
    return true;
  }

  final candidate = parseNormalizedDateValue(value);
  if (candidate == null) {
    return false;
  }

  if (fromDate != null && candidate.isBefore(fromDate)) {
    return false;
  }
  if (toDate != null && candidate.isAfter(toDate)) {
    return false;
  }
  return true;
}
