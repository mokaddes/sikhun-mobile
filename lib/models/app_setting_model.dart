class AppSettingModel {
  final String siteName;
  final String siteNameBn;
  final String? siteTagline;
  final String? siteTaglineBn;
  final String? logoUrl;
  final String? faviconUrl;
  final String? seoImageUrl;
  final String? siteEmail;
  final String? sitePhone;
  final String? facebookUrl;
  final String? youtubeUrl;
  final String appVersion;

  AppSettingModel({
    this.siteName = 'SIKHUN',
    this.siteNameBn = 'শিখুন',
    this.siteTagline,
    this.siteTaglineBn = 'আপনার এআই পড়ার টেবিল',
    this.logoUrl,
    this.faviconUrl,
    this.seoImageUrl,
    this.siteEmail = 'support@sikhun.com',
    this.sitePhone,
    this.facebookUrl,
    this.youtubeUrl,
    this.appVersion = '1.0.0',
  });

  factory AppSettingModel.fromJson(Map<String, dynamic> json) {
    return AppSettingModel(
      siteName: json['site_name']?.toString() ?? 'SIKHUN',
      siteNameBn: json['site_name_bn']?.toString() ?? 'শিখুন',
      siteTagline: json['site_tagline']?.toString(),
      siteTaglineBn: json['site_tagline_bn']?.toString() ?? 'আপনার এআই পড়ার টেবিল',
      logoUrl: json['logo_url']?.toString(),
      faviconUrl: json['favicon_url']?.toString(),
      seoImageUrl: json['seo_image_url']?.toString(),
      siteEmail: json['site_email']?.toString() ?? 'support@sikhun.com',
      sitePhone: json['site_phone']?.toString(),
      facebookUrl: json['facebook_url']?.toString(),
      youtubeUrl: json['youtube_url']?.toString(),
      appVersion: json['app_version']?.toString() ?? '1.0.0',
    );
  }
}
