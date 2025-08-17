import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  final bool showAtBottom;
  final EdgeInsets? margin;
  final double? customHeight;
  final bool useStandardSize; // New parameter for consistent sizing
  
  const BannerAdWidget({
    super.key,
    this.showAtBottom = true,
    this.margin,
    this.customHeight,
    this.useStandardSize = true, // Default to standard size
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = true;

  // Standard banner ad dimensions for consistency
  static const double _standardBannerHeight = 50.0; // Standard banner height
  static const double _standardBannerWidth = 320.0; // Standard banner width

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      final ad = await AdsService.loadBannerAd();
      if (ad != null && mounted) {
        setState(() {
          _bannerAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
        });
      } else {
        setState(() {
          _isAdLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads if they're disabled or failed to load
    if (!AdsService.areAdsEnabled || (!_isAdLoaded && !_isAdLoading)) {
      return const SizedBox.shrink();
    }

    // Calculate consistent banner height based on screen size
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Use custom height if provided, otherwise use standard responsive height
    final bannerHeight = widget.customHeight ?? 
        (widget.useStandardSize ? _getStandardHeight(screenWidth) : _calculateResponsiveHeight(screenWidth, screenHeight));
    
    // Calculate responsive margin
    final responsiveMargin = widget.margin ?? EdgeInsets.all(screenWidth * 0.02);

    // Show loading indicator while ad is loading
    if (_isAdLoading) {
      return Container(
        height: bannerHeight,
        width: double.infinity,
        margin: responsiveMargin,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Show the actual banner ad
    if (_bannerAd != null && _isAdLoaded) {
      return Container(
        height: bannerHeight,
        width: double.infinity,
        margin: responsiveMargin,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // If ad failed to load, show a subtle placeholder to maintain layout
    return Container(
      height: bannerHeight,
      width: double.infinity,
      margin: responsiveMargin,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
      child: Center(
        child: Text(
          'Ad',
          style: TextStyle(
            color: Colors.grey,
            fontSize: screenWidth * 0.03,
          ),
        ),
      ),
    );
  }

  /// Get standard height for consistent sizing across all screens
  double _getStandardHeight(double screenWidth) {
    // For very small screens, use minimum height
    if (screenWidth < 320) {
      return _standardBannerHeight * 0.8; // 40px
    }
    
    // For small screens, use standard height
    if (screenWidth < 480) {
      return _standardBannerHeight; // 50px
    }
    
    // For medium screens, scale proportionally
    if (screenWidth < 720) {
      return _standardBannerHeight * 1.1; // 55px
    }
    
    // For large screens, scale proportionally but cap it
    if (screenWidth < 1080) {
      return _standardBannerHeight * 1.2; // 60px
    }
    
    // For very large screens, cap the height
    return _standardBannerHeight * 1.3; // 65px
  }

  /// Calculate responsive banner height that maintains consistency across devices
  double _calculateResponsiveHeight(double screenWidth, double screenHeight) {
    // For very small screens, use minimum height
    if (screenWidth < 320) {
      return _standardBannerHeight * 0.8; // 40px
    }
    
    // For small screens, use standard height
    if (screenWidth < 480) {
      return _standardBannerHeight; // 50px
    }
    
    // For medium screens, scale proportionally
    if (screenWidth < 720) {
      return _standardBannerHeight * 1.1; // 55px
    }
    
    // For large screens, scale proportionally but cap it
    if (screenWidth < 1080) {
      return _standardBannerHeight * 1.2; // 60px
    }
    
    // For very large screens, cap the height
    return _standardBannerHeight * 1.3; // 65px
  }
}
