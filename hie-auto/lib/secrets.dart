class Secrets {
  // MapBox configuration
  static const String mapboxAccessToken =
      'pk.eyJ1IjoidmFydW5tZW5vbiIsImEiOiJjbTM3MjNmZWMwNGJlMm1xdXg1OTk1NHlnIn0.5yLCFGI6Mr3tMzcjJZgYlg';
  static const String lightMapStyle = 'mapbox/light-v11'; // Light theme style
  static const String darkMapStyle = 'mapbox/dark-v11'; // Dark theme style
  static const String mapboxStyleId = 'mapbox/streets-v12';

  // API configuration
  static const String apiBaseUrl = 'https://helloauto-zwjd.onrender.com';

  // Validate token format
  static bool isValidMapboxToken() {
    return mapboxAccessToken.startsWith('pk.') &&
        mapboxAccessToken.length > 50 &&
        mapboxAccessToken != 'YOUR_MAPBOX_TOKEN_HERE';
  }
}
