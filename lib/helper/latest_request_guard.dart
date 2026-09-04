class LatestRequestGuard {
  int _revision = 0;

  int get checkpoint => _revision;

  int begin() => ++_revision;

  void invalidate() {
    _revision++;
  }

  bool isCurrent(int revision) => revision == _revision;
}
