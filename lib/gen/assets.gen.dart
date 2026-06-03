import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// MAIN ACCESS POINT
class Assets {
  Assets._();

  static const icons = _AssetsIconsGen();
  static const images = _AssetsImagesGen();
}

/// -----------------------------
/// ICONS (SVG)
/// -----------------------------
class _AssetsIconsGen {
  const _AssetsIconsGen();

  SvgGenImage get appLogo => const SvgGenImage('assets/icons/app_logo.png');

  SvgGenImage get mail => const SvgGenImage('assets/icons/mail.svg');

  SvgGenImage get phone => const SvgGenImage('assets/icons/phone.svg');

  SvgGenImage get user => const SvgGenImage('assets/icons/user.svg');

  // PNG logo as fallback
  AssetGenImage get appLogoPng =>
      const AssetGenImage('assets/icons/app_logo.png');
}

/// -----------------------------
/// IMAGES (PNG/JPG)
/// -----------------------------
class _AssetsImagesGen {
  const _AssetsImagesGen();

  AssetGenImage get example => const AssetGenImage('assets/images/example.png');
}

/// -----------------------------
/// SVG HELPER
/// -----------------------------
class SvgGenImage {
  const SvgGenImage(this._assetName);

  final String _assetName;

  SvgPicture svg({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return SvgPicture.asset(
      _assetName,
      key: key,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  String get path => _assetName;
}

/// -----------------------------
/// IMAGE HELPER (PNG/JPG)
/// -----------------------------
class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  Image image({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  String get path => _assetName;
}
