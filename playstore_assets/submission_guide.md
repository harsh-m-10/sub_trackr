# Play Store Submission Guide for SubTrackr

## 🚀 Pre-Submission Checklist

### ✅ Technical Requirements
- [x] Application ID: `com.harshm.subtrackr`
- [x] Version: 1.0.0
- [x] App Name: "SubTrackr"
- [x] Error handling implemented
- [x] Loading states added
- [x] Currency options available
- [x] Privacy policy created
- [x] Terms of service created

### ✅ App Signing Setup

#### Option 1: Google Play App Signing (Recommended)
1. **In Play Console:**
   - Go to Setup → App Signing
   - Choose "Google Play App Signing"
   - Google will handle your keys automatically

2. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```

#### Option 2: Manual Key Management
1. **Generate Keystore:**
   ```bash
   keytool -genkey -v -keystore subtrackr.keystore -alias subtrackr -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Configure in build.gradle.kts:**
   ```kotlin
   signingConfigs {
       create("release") {
           storeFile = file("subtrackr.keystore")
           storePassword = "your_store_password"
           keyAlias = "subtrackr"
           keyPassword = "your_key_password"
       }
   }
   ```

3. **Build Signed APK:**
   ```bash
   flutter build apk --release
   ```

## 📱 Play Store Assets Required

### 1. App Icon
- **Size:** 512x512 pixels
- **Format:** PNG
- **Background:** Transparent or solid color
- **Design:** Professional, recognizable logo

### 2. Feature Graphic
- **Size:** 1024x500 pixels
- **Format:** PNG or JPG
- **Content:** App name, tagline, key features
- **Style:** Modern, clean design

### 3. Screenshots
- **Devices:** Phone (minimum 2), 7-inch tablet, 10-inch tablet
- **Count:** Minimum 2 per device type
- **Content:** Key app screens (Home, Analytics, Add Subscription)
- **Quality:** High resolution, clear text

### 4. App Preview Video (Optional but Recommended)
- **Duration:** 30 seconds to 2 minutes
- **Format:** MP4
- **Content:** App walkthrough, key features
- **Quality:** 1080p minimum

## 📝 Store Listing Content

### App Name
- **Primary:** SubTrackr
- **Short:** SubTrackr - Subscription Manager

### Short Description
```
Track subscriptions, analyze spending, and get renewal reminders. Simple, powerful, and privacy-focused.
```

### Full Description
Use the content from `app_description.txt` in the playstore_assets folder.

### Keywords
Use the keywords from `keywords.txt` in the playstore_assets folder.

## 🔒 Privacy & Legal

### Privacy Policy
- **File:** `privacy_policy.md`
- **Hosting:** Upload to your website (harshm.dev/subtrackr/privacy-policy)
- **Content:** Comprehensive privacy policy covering all app features

### Terms of Service
- **File:** `terms_of_service.md`
- **Hosting:** Upload to your website (harshm.dev/subtrackr/terms-of-service)
- **Content:** Legal terms covering app usage and user rights

## 📊 Content Rating

### Questionnaire Answers
1. **Violence:** No
2. **Sexual Content:** No
3. **Language:** No
4. **Controlled Substances:** No
5. **Purchases:** No (app is free)
6. **User Generated Content:** No
7. **Location:** No
8. **Personal Information:** No

**Expected Rating:** 3+ (Everyone)

## 🎯 Target Audience

### Primary
- Age: 18-45
- Interests: Finance, productivity, organization
- Devices: Android smartphones and tablets

### Secondary
- Small business owners
- Budget-conscious individuals
- Subscription-heavy users

## 💰 Monetization Strategy

### Current Version
- **Model:** Free with no ads
- **Features:** All features available
- **Goal:** Build user base and gather feedback

### Future Versions
- **Premium Tier:** Advanced features, cloud backup
- **Ad Integration:** Non-intrusive banner ads
- **In-App Purchases:** Premium themes, export features

## 🚀 Submission Steps

### 1. Create Play Console Account
- Go to [Google Play Console](https://play.google.com/console)
- Pay $25 one-time registration fee
- Complete account verification

### 2. Create New App
- Click "Create app"
- Enter app name: "SubTrackr"
- Choose "App or game"
- Select "Free" or "Paid"

### 3. Complete Store Listing
- Upload all required assets
- Fill in app description
- Add screenshots and videos
- Set content rating

### 4. Upload APK
- Go to "Production" track
- Upload your signed APK
- Add release notes

### 5. Submit for Review
- Review all information
- Click "Review release"
- Submit for Google review

## ⏱️ Review Timeline

### Typical Review Time
- **First submission:** 1-3 days
- **Updates:** 1-2 days
- **Rejections:** Fix and resubmit within 1-2 days

### Common Rejection Reasons
1. **App crashes** - Test thoroughly on multiple devices
2. **Poor performance** - Optimize app performance
3. **Incomplete information** - Fill all required fields
4. **Policy violations** - Review Google Play policies

## 🔍 Post-Submission

### Monitor Review Status
- Check Play Console regularly
- Respond to any Google feedback quickly
- Be prepared to make changes if needed

### Prepare for Launch
- Plan marketing strategy
- Set up social media presence
- Prepare user support system
- Monitor app performance

## 📈 Success Metrics

### Launch Goals
- **Week 1:** 100+ downloads
- **Month 1:** 1,000+ downloads
- **Month 3:** 5,000+ downloads
- **Month 6:** 10,000+ downloads

### User Engagement
- **Daily Active Users:** Target 20% of total users
- **Retention:** 30-day retention > 40%
- **Rating:** Maintain 4.0+ stars

## 🆘 Support & Help

### Google Play Console Help
- [Official Documentation](https://support.google.com/googleplay/android-developer)
- [Policy Center](https://play.google.com/about/developer-content-policy)
- [Developer Support](https://support.google.com/googleplay/android-developer/answer/7218994)

### Community Resources
- [Flutter Community](https://flutter.dev/community)
- [Android Developers](https://developer.android.com)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## 🎉 Final Checklist

Before submitting, ensure:
- [ ] App builds successfully in release mode
- [ ] All assets are properly sized and formatted
- [ ] Privacy policy and terms are hosted and accessible
- [ ] App has been tested on multiple devices
- [ ] All required permissions are justified
- [ ] Content rating questionnaire is completed
- [ ] Store listing is complete and compelling

**Good luck with your Play Store submission! 🚀**
