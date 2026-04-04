enum PlatformType {
  youtube,
  instagram,
  facebook,
  linkedin,
}

extension PlatformTypeExtension on PlatformType {
  String get name {
    switch (this) {
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.facebook:
        return 'Facebook';
      case PlatformType.linkedin:
        return 'LinkedIn';
    }
  }

  String get iconPath {
    switch (this) {
      case PlatformType.youtube:
        return 'assets/icons/youtube.png';
      case PlatformType.instagram:
        return 'assets/icons/instagram.png';
      case PlatformType.facebook:
        return 'assets/icons/facebook.png';
      case PlatformType.linkedin:
        return 'assets/icons/linkedin.png';
    }
  }
}
