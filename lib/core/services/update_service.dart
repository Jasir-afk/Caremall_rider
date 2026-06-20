import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';

/// Service to handle app updates for the Caremall Rider app
class UpdateService {
  /// Play Store package ID for Caremall Rider
  static const String _packageName = 'com.caremall.rider';

  /// Play Store URL for Caremall Rider
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_packageName';

  /// Show a mandatory update dialog (users MUST update to continue)
  static Future<bool> checkForUpdates(
    BuildContext context, {
    bool force = false,
  }) async {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════╗');
    debugPrint('║       🔄 UPDATE SERVICE — CHECK STARTED          ║');
    debugPrint('╚══════════════════════════════════════════════════╝');

    try {
      // Get actual app version
      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('📱 App Package    : ${packageInfo.packageName}');
      debugPrint('📱 App Version    : ${packageInfo.version}');
      debugPrint('📱 Build Number   : ${packageInfo.buildNumber}');

      if (force) {
        debugPrint(
          '⚠️  FORCE MODE = true → Showing dialog immediately (bypassing all checks)',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          _showUpdateDialog();
        }
        return true;
      }

      final installedBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Parallel checks for speed
      bool officialUpdateAvailable = false;
      final upgrader = Upgrader(
        debugLogging: false,
        debugDisplayAlways: false,
        durationUntilAlertAgain: const Duration(days: 1),
      );

      debugPrint('');
      debugPrint('┌─────────────────────────────────────────────────');
      debugPrint('│  🔍 Step 1/2 — Google Play In-App Update Check');
      debugPrint('└─────────────────────────────────────────────────');

      await Future.wait([
        // Check via Google Play In-App Update API (Android only)
        if (Platform.isAndroid)
          InAppUpdate.checkForUpdate()
              .then((info) {
                debugPrint(
                  '   Play Store availability : ${info.updateAvailability}',
                );
                debugPrint(
                  '   Store version code      : ${info.availableVersionCode ?? 'N/A'}',
                );
                debugPrint(
                  '   Immediate update allowed: ${info.immediateUpdateAllowed}',
                );
                debugPrint(
                  '   Flexible update allowed : ${info.flexibleUpdateAllowed}',
                );

                if (info.updateAvailability ==
                    UpdateAvailability.updateAvailable) {
                  if ((info.availableVersionCode ?? 0) > installedBuildNumber) {
                    officialUpdateAvailable = true;
                    debugPrint(
                      '   ✅ Official API → UPDATE AVAILABLE (store build > installed build)',
                    );
                  } else {
                    debugPrint(
                      '   🛡️  Caching bug guard → Ignoring false positive '
                      '(store: ${info.availableVersionCode}, installed: $installedBuildNumber)',
                    );
                  }
                } else {
                  debugPrint('   ✅ Official API → App is up to date');
                }
              })
              .timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  debugPrint(
                    '   ⏱️  InAppUpdate timed out after 2s — skipping this check',
                  );
                  return null;
                },
              )
              .catchError((e) {
                debugPrint('   ❌ InAppUpdate check failed: $e');
                debugPrint('   ℹ️  This is normal on debug/sideloaded APKs');
                return null;
              })
        else
          Future.value(null),

        // Check via Upgrader (cross-platform, reads store metadata)
        upgrader
            .initialize()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('   ⏱️  Upgrader initialization timed out after 3s');
                return false;
              },
            )
            .catchError((e) {
              debugPrint('   ❌ Upgrader initialization failed: $e');
              return false;
            }),
      ]);

      debugPrint('');
      debugPrint('┌─────────────────────────────────────────────────');
      debugPrint('│  🔍 Step 2/2 — Upgrader Package Version Check');
      debugPrint('└─────────────────────────────────────────────────');

      final storeVersion = upgrader.currentAppStoreVersion;
      final installedVersion = upgrader.currentInstalledVersion;

      // Parse store build number from version string if available
      int storeBuildNumber = 0;
      if (storeVersion != null) {
        if (storeVersion.contains('+')) {
          storeBuildNumber = int.tryParse(storeVersion.split('+').last) ?? 0;
        } else if (storeVersion.contains('(') && storeVersion.contains(')')) {
          final start = storeVersion.indexOf('(') + 1;
          final end = storeVersion.indexOf(')');
          storeBuildNumber =
              int.tryParse(storeVersion.substring(start, end)) ?? 0;
        }
      }

      final updateAvailableByPackage = upgrader.isUpdateAvailable();
      final buildUpdateNeeded = storeBuildNumber > installedBuildNumber;

      debugPrint(
        '   Installed version  : $installedVersion (build $installedBuildNumber)',
      );
      debugPrint(
        '   Store version      : ${storeVersion ?? 'N/A'} (build $storeBuildNumber)',
      );
      debugPrint(
        '   Upgrader detects   : ${updateAvailableByPackage ? '⬆️  UPDATE AVAILABLE' : '✅ Up to date'}',
      );
      debugPrint(
        '   Build diff check   : ${buildUpdateNeeded ? '⬆️  Store build > installed' : '✅ Same or lower'}',
      );

      debugPrint('');
      debugPrint('┌─────────────────────────────────────────────────');
      debugPrint('│  📊 Decision Summary');
      debugPrint('└─────────────────────────────────────────────────');
      debugPrint(
        '   InAppUpdate API    : ${officialUpdateAvailable ? '🔴 UPDATE NEEDED' : '🟢 OK'}',
      );
      debugPrint(
        '   Upgrader package   : ${updateAvailableByPackage ? '🔴 UPDATE NEEDED' : '🟢 OK'}',
      );
      debugPrint(
        '   Build comparison   : ${buildUpdateNeeded ? '🔴 UPDATE NEEDED' : '🟢 OK'}',
      );
      debugPrint('   Force flag         : ${force ? '🔴 YES' : '🟢 NO'}');

      final shouldShow =
          officialUpdateAvailable ||
          updateAvailableByPackage ||
          buildUpdateNeeded ||
          force;

      debugPrint('');
      if (shouldShow) {
        debugPrint('🚨 RESULT → UPDATE REQUIRED — Showing update popup now!');
      } else {
        debugPrint('✅ RESULT → No update needed — Proceeding to app normally.');
      }
      debugPrint('══════════════════════════════════════════════════');
      debugPrint('');

      if (!shouldShow) {
        return false;
      }

      if (context.mounted) {
        _showUpdateDialog();
      }
      return true;
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
    }
    return false;
  }

  /// Shows the premium "Update Required" bottom-sheet/dialog
  static void _showUpdateDialog() {
    Get.dialog(
      barrierDismissible: false,
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient Header ──────────────────────────────────────
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primarycolor,
                        AppColors.textnaturalcolor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -15,
                        left: -10,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      // Icon
                      const Center(
                        child: Icon(
                          Icons.system_update_rounded,
                          size: 62,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
                      Text(
                        'Update Required',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textnaturalcolor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A new version of Caremall Rider is available with important fixes and exciting new features. Please update to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textDefaultSecondarycolor,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              167,
                              5,
                              5,
                            ),
                            foregroundColor: AppColors.whitecolor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.download_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Update Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the Caremall Rider Play Store listing
  static Future<void> _launchPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Could not open Play Store. Please update manually.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
