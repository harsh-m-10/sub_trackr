import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static bool _isInitialized = false;
  
  // Your real AdMob IDs
  static const String _appId = 'ca-app-pub-3517039109190451~6774620235';
  static const String _bannerAdUnitId = 'ca-app-pub-3517039109190451/1154342485';

  // Standard banner ad dimensions for consistency
  static const double standardBannerHeight = 50.0;
  static const double standardBannerWidth = 320.0;

  /// Initialize Google Mobile Ads SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      print('AdMob initialized successfully');
    } catch (e) {
      print('Failed to initialize AdMob: $e');
    }
  }

  /// Get banner ad unit ID
  static String get bannerAdUnitId => _bannerAdUnitId;

  /// Check if ads are enabled (you can add user preference here)
  static bool get areAdsEnabled => true;

  /// Create a banner ad with consistent dimensions
  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner, // Standard 320x50 banner
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          // Only log non-common errors to reduce console spam
          if (error.code != 3) { // Skip "No fill" errors
            print('Banner ad failed to load: $error');
          }
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
      ),
    );
  }

  /// Load a banner ad
  static Future<BannerAd?> loadBannerAd() async {
    if (!areAdsEnabled) return null;
    
    try {
      final ad = createBannerAd();
      await ad.load();
      return ad;
    } catch (e) {
      print('Error loading banner ad: $e');
      return null;
    }
  }

  /// Get responsive banner height based on screen width
  static double getResponsiveBannerHeight(double screenWidth) {
    // For very small screens, use minimum height
    if (screenWidth < 320) {
      return standardBannerHeight * 0.8; // 40px
    }
    
    // For small screens, use standard height
    if (screenWidth < 480) {
      return standardBannerHeight; // 50px
    }
    
    // For medium screens, scale proportionally
    if (screenWidth < 720) {
      return standardBannerHeight * 1.1; // 55px
    }
    
    // For large screens, scale proportionally but cap it
    if (screenWidth < 1080) {
      return standardBannerHeight * 1.2; // 60px
    }
    
    // For very large screens, cap the height
    return standardBannerHeight * 1.3; // 65px
  }

  /// Dispose all ads
  static void dispose() {
    // This will be called when the app is closed
    print('Ads service disposed');
  }
}
