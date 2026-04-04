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
}
