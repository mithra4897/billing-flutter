import 'package:flutter/widgets.dart';

List<T> normalizeDisposableDraftEntries<T>(
  List<T> entries,
  T Function() createEmpty,
) {
  return entries.isEmpty ? <T>[createEmpty()] : entries;
}

void disposeDraftEntriesNextFrame<T>(
  Iterable<T> entries,
  void Function(T entry) dispose,
) {
  final capturedEntries = entries.toList(growable: false);
  if (capturedEntries.isEmpty) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final entry in capturedEntries) {
      dispose(entry);
    }
  });
}

void replaceDisposableDraftEntries<T>({
  required List<T> previous,
  required List<T> next,
  required T Function() createEmpty,
  required void Function(List<T> entries) assign,
  required void Function(T entry) dispose,
  VoidCallback? notify,
}) {
  final normalizedEntries = normalizeDisposableDraftEntries(next, createEmpty);
  assign(normalizedEntries);
  notify?.call();
  final removedEntries = previous
      .where(
        (previousEntry) => !normalizedEntries.any(
          (nextEntry) => identical(previousEntry, nextEntry),
        ),
      )
      .toList(growable: false);
  disposeDraftEntriesNextFrame(removedEntries, dispose);
}
