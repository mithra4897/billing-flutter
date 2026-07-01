import 'external_url_actions_stub.dart'
    if (dart.library.html) 'external_url_actions_web.dart'
    as impl;

Future<bool> openExternalUrl(String url, {String? target}) {
  return impl.openExternalUrl(url, target: target);
}
