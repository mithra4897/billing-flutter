import '../model/masters/document_series_model.dart';
import '../model/masters/party_model.dart';
import '../model/masters/party_type_model.dart';

String partyCodePrefix(PartyTypeModel? partyType) {
  final source = (partyType?.code ?? '').trim().isNotEmpty
      ? partyType!.code!
      : (partyType?.name ?? 'PTY');
  final normalized = source.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final prefix = normalized.isEmpty ? 'PTY' : normalized.toUpperCase();

  return prefix.length <= 3 ? prefix : prefix.substring(0, 3);
}

bool partyCodeUsesPrefix(String? partyCode, String typeCode) {
  final normalizedCode = (partyCode ?? '').trim().toUpperCase();
  final normalizedType = typeCode.trim().toUpperCase();
  if (normalizedCode.isEmpty || normalizedType.isEmpty) {
    return false;
  }

  return normalizedCode.startsWith('$normalizedType/');
}

Map<String, dynamic> partyCodeLookupFilters(String typeCode) {
  return <String, dynamic>{
    'page': 1,
    'per_page': 200,
    'search': '${typeCode.trim().toUpperCase()}/',
    'sort_by': 'party_code',
    'sort_order': 'desc',
  };
}

String generatePartyCode({
  required String typeCode,
  required DocumentSeriesModel? series,
  required Iterable<PartyModel> parties,
}) {
  final pattern = RegExp('^${RegExp.escape(typeCode)}/(\\d+)');
  var nextNumber = series?.nextNumber ?? 1;

  for (final party in parties) {
    final match = pattern.firstMatch(
      (party.partyCode ?? '').trim().toUpperCase(),
    );
    if (match == null) {
      continue;
    }

    final value = int.tryParse(match.group(1) ?? '');
    if (value != null && value >= nextNumber) {
      nextNumber = value + 1;
    }
  }

  final number = nextNumber.toString().padLeft(series?.numberLength ?? 5, '0');
  final suffix = (series?.suffix ?? '').trim();

  return '$typeCode/$number$suffix';
}

String? savedPartyCodeForOriginalType(
  PartyModel? selectedParty,
  int? partyTypeId,
) {
  if (selectedParty?.partyTypeId != partyTypeId) {
    return null;
  }

  final savedCode = (selectedParty?.partyCode ?? '').trim();
  return savedCode.isEmpty ? null : savedCode;
}

bool isCurrentPartyCodeRefresh({
  required int requestToken,
  required int latestRequestToken,
  required int? requestedPartyTypeId,
  required int? currentPartyTypeId,
}) {
  return requestToken == latestRequestToken &&
      requestedPartyTypeId == currentPartyTypeId;
}
