
Set<int> selectAllHrRecords(Iterable<int> ids, {required bool selected}) =>
    selected ? ids.toSet() : <int>{};
