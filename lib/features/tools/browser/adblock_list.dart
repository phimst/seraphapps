/// Daftar domain iklan & tracker umum yang diblok pas request masuk,
/// SEBELUM kekirim (bukan cuma nyembunyiin elemen kayak adblock cosmetic).
/// Bukan filter-list selengkap uBlock Origin, tapi cover mayoritas
/// ad-network & tracker paling umum.
class AdBlockList {
  static const List<String> domains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'google-analytics.com',
    'googletagmanager.com',
    'googletagservices.com',
    'adnxs.com',
    'adsrvr.org',
    'taboola.com',
    'outbrain.com',
    'criteo.com',
    'criteo.net',
    'amazon-adsystem.com',
    'media.net',
    'pubmatic.com',
    'rubiconproject.com',
    'casalemedia.com',
    'moatads.com',
    'scorecardresearch.com',
    'quantserve.com',
    'adsafeprotected.com',
    'adform.net',
    'adroll.com',
    'bidswitch.net',
    'openx.net',
    'smartadserver.com',
    'yieldmo.com',
    'popads.net',
    'propellerads.com',
    'exoclick.com',
    'juicyads.com',
  ];

  static bool isBlocked(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      return domains.any((d) => host == d || host.endsWith('.$d'));
    } catch (_) {
      return false;
    }
  }
}
