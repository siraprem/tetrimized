package com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview;

import android.os.Build;
import android.webkit.WebResourceResponse;

import com.pichillilorenzo.flutter_inappwebview_android.types.WebResourceRequestExt;

import java.io.ByteArrayInputStream;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/** Fast, local-only request filter for the Tetrimized WebView. */
final class TetrimizedAdRequestBlocker {
  // Keep in sync with lib/main.dart. The existing subframe-regex setting acts as
  // the opt-in signal, so no extra platform channel or per-request Dart call is needed.
  static final String ENABLE_PATTERN =
      "^https?://([a-z0-9-]+\\.)*(pub\\.network|doubleclick\\.net|googletagservices\\.com|amazon-adsystem\\.com|intentiq\\.com|gum\\.criteo\\.com|id5-sync\\.com|id\\.hadron\\.ad\\.gt|match\\.adsrvr\\.org|id\\.a-mx\\.com|live\\.primis\\.tech|tag\\.durationmedia\\.net|s0\\.2mdn\\.net|googlesyndication\\.com|cdn\\.hadronid\\.net)(:[0-9]+)?/.*$";

  private static final Set<String> AD_HOSTS = new HashSet<>(Arrays.asList(
      "pub.network",
      "doubleclick.net",
      "googletagservices.com",
      "amazon-adsystem.com",
      "intentiq.com",
      "gum.criteo.com",
      "id5-sync.com",
      "id.hadron.ad.gt",
      "match.adsrvr.org",
      "id.a-mx.com",
      "live.primis.tech",
      "tag.durationmedia.net",
      "s0.2mdn.net",
      "googlesyndication.com",
      "cdn.hadronid.net"
  ));

  private TetrimizedAdRequestBlocker() {}

  static WebResourceResponse interceptIfEnabled(InAppWebView webView, WebResourceRequestExt request) {
    String configuredPattern = webView.customSettings.regexToCancelSubFramesLoading;
    if (!ENABLE_PATTERN.equals(configuredPattern) || !isAdHostUrl(request.getUrl())) {
      return null;
    }

    // A local empty response prevents the network request before it is sent.
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      return new WebResourceResponse(
          "text/plain",
          "UTF-8",
          204,
          "No Content",
          Collections.<String, String>emptyMap(),
          new ByteArrayInputStream(new byte[0]));
    }
    return new WebResourceResponse(
        "text/plain", "UTF-8", new ByteArrayInputStream(new byte[0]));
  }

  private static boolean isAdHostUrl(String url) {
    if (url == null) return false;
    int schemeEnd = url.indexOf("://");
    if (schemeEnd < 0) return false;
    String scheme = url.substring(0, schemeEnd).toLowerCase(Locale.ROOT);
    if (!"http".equals(scheme) && !"https".equals(scheme)) return false;

    int hostStart = schemeEnd + 3;
    int hostEnd = url.length();
    for (int i = hostStart; i < url.length(); i++) {
      char c = url.charAt(i);
      if (c == '/' || c == ':' || c == '?' || c == '#') {
        hostEnd = i;
        break;
      }
    }
    if (hostEnd <= hostStart) return false;

    String host = url.substring(hostStart, hostEnd).toLowerCase(Locale.ROOT);
    while (!host.isEmpty()) {
      if (AD_HOSTS.contains(host)) return true;
      int firstDot = host.indexOf('.');
      if (firstDot < 0) return false;
      host = host.substring(firstDot + 1);
    }
    return false;
  }
}
