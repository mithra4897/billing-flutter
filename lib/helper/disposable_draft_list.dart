import 'package:flutter/widgets.dart';

final Expando<bool> _draftEntryPendingDispose = Expando<bool>(
  'draftEntryPendingDispose',
);

List<T> normalizeDisposableDraftEntries<T extends Object>(
  List<T> entries,
  T Function() createEmpty,
) {
  return entries.isEmpty ? <T>[createEmpty()] : entries;
}

void disposeDraftEntriesNextFrame<T extends Object>(
  Iterable<T> entries,
  void Function(T entry) dispose,
) {
  final capturedEntries = entries
      .where((entry) {
        final pending = _draftEntryPendingDispose[entry] ?? false;
        if (pending) {
          return false;
        }
        _draftEntryPendingDispose[entry] = true;
        return true;
      })
      .toList(growable: false);
  if (capturedEntries.isEmpty) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final entry in capturedEntries) {
      try {
        dispose(entry);
      } finally {
        _draftEntryPendingDispose[entry] = false;
      }
    }
  });
}

void disposeChangeNotifiersNextFrame<T extends ChangeNotifier>(
  Iterable<T> notifiers,
) {
  final captured = notifiers.toList(growable: false);
  if (captured.isEmpty) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final notifier in captured) {
      try {
        notifier.dispose();
      } catch (_) {}
    }
  });
}

void replaceDisposableDraftEntries<T extends Object>({
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
