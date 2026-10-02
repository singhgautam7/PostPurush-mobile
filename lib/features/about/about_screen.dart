import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/platform_surfaces.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/section_header.dart';
import '../more/more_screen.dart';
import 'app_mark.dart';

/// Board 8. The local-first statement is the main content, with the usual rows
/// below it.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    // Null until the channel answers, and off-device for good: the constants
    // are the fallback, never the source.
    final AppVersion? version = ref.watch(appVersionProvider).value;
    return PageScaffold(
      title: 'About',
      children: <Widget>[
        Row(
          spacing: Space.lg,
          children: <Widget>[
            const AppMark(size: 64),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(
                    'PostPurush',
                    style: AppType.headerTitle.copyWith(color: c.onSurface),
                  ),
                  Text(
                    version?.toString() ?? AboutInfo.fallbackVersion,
                    style: AppType.monoLabel.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text(
          'PostPurush stores everything on your device. No accounts, no sync, '
          'no tracking. It makes only the API requests you send.',
          style: AppType.body.copyWith(height: 1.6, color: c.onSurface),
        ),
        const SizedBox(height: Space.section),
        const SectionHeader(label: 'Legal'),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            _AboutRow(
              icon: Icons.shield_outlined,
              title: 'Privacy policy',
              subtitle: 'On device only',
              onTap: () => context.push(Routes.privacy),
            ),
            _AboutRow(
              icon: Icons.lock_outline_rounded,
              title: 'Permissions',
              subtitle: 'One, and what it is for',
              onTap: () => context.push(Routes.permissions),
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        const SectionHeader(label: 'The developer'),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            _AboutRow(
              icon: Icons.person_outline_rounded,
              title: 'Gautam Rajeev Singh',
              subtitle: 'singhgautam.com',
              external: true,
              onTap: () => _open(context, AboutInfo.portfolio),
            ),
            _AboutRow(
              icon: Icons.apps_rounded,
              title: 'More apps',
              subtitle: 'Everything else on Google Play',
              external: true,
              onTap: () => _open(context, AboutInfo.moreApps),
            ),
            _AboutRow(
              icon: Icons.star_outline_rounded,
              title: 'Rate PostPurush',
              subtitle: 'Helps others find it',
              external: true,
              onTap: () => _open(context, AboutInfo.listing),
            ),
            _AboutRow(
              icon: Icons.share_outlined,
              title: 'Share PostPurush',
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      'PostPurush, a local-first API client for Android. '
                      '${AboutInfo.listing}',
                  subject: 'PostPurush',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        Text(
          'Built with Flutter. The bundled catalogue of public APIs comes from '
          'the public-apis project.',
          style: AppType.bodySmall.copyWith(color: c.onSurfaceVariant),
        ),
        const SizedBox(height: Space.lg),
        const MadeInIndia(),
      ],
    );
  }

  /// Hands the link to the browser, and falls back to the clipboard on a
  /// device with nothing registered to open it.
  static Future<void> _open(BuildContext context, String url) async {
    final bool opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) AppSnackbar.info(context, 'Link copied instead');
  }
}

/// One row of About: a glyph, a label, an optional line, and the chevron that
/// says whether the tap stays in the app or leaves it.
class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.external = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool external;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return AppRow(
      title: title,
      subtitle: subtitle,
      leading: Icon(icon, size: IconSpec.small, color: c.icon),
      trailing: Icon(
        external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
        size: IconSpec.small,
        color: c.onSurfaceMuted,
      ),
      onTap: onTap,
    );
  }
}

/// The line that closes About, as it does in the rest of the family.
class MadeInIndia extends StatelessWidget {
  const MadeInIndia({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'Made with \u2764\ufe0f in India',
    textAlign: TextAlign.center,
    style: AppType.monoLabel.copyWith(color: context.colors.onSurfaceMuted),
  );
}

/// What the app asks Android for, and what each one buys. One permission, so
/// the page is short on purpose: a list of one is the point being made.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  static const List<(IconData, String, String)> _entries =
      <(IconData, String, String)>[
        (
          Icons.cloud_outlined,
          'Internet',
          'The one permission PostPurush declares. It is what sends the '
              'requests you compose, and it is used for nothing else: no '
              'account, no sync, no analytics, no ads. A request goes to the '
              'host you typed and nowhere near a server of ours, because there '
              'is no server of ours.',
        ),
        (
          Icons.folder_open_outlined,
          'Files',
          'Not declared. Importing a folder and saving an export both go '
              'through the Android file picker, which hands over the one file '
              'you chose and nothing around it.',
        ),
        (
          Icons.notifications_none_rounded,
          'Notifications',
          'Not requested. PostPurush never notifies you.',
        ),
        (
          Icons.my_location_outlined,
          'Location, contacts, camera, microphone',
          'None of them are requested, and none are used.',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return PageScaffold(
      title: 'Permissions',
      children: <Widget>[
        for (final (IconData icon, String title, String body) in _entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Space.sm,
              children: <Widget>[
                Row(
                  spacing: Space.sm,
                  children: <Widget>[
                    Icon(icon, size: IconSpec.small, color: c.iconMuted),
                    Text(
                      title,
                      style: AppType.titleMedium.copyWith(color: c.onSurface),
                    ),
                  ],
                ),
                Text(
                  body,
                  style: AppType.body.copyWith(
                    height: 1.6,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Android settings can revoke any of this at any time. Without '
          'internet access the app still opens, and every request fails.',
          style: AppType.monoLabel.copyWith(color: c.onSurfaceMuted),
        ),
      ],
    );
  }
}

/// The privacy page, which is the policy in the repository, said briefly.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    Widget paragraph(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.sm,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: AppType.sectionHeader.copyWith(color: c.onSurfaceVariant),
          ),
          Text(
            body,
            style: AppType.body.copyWith(height: 1.6, color: c.onSurface),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: 'Privacy',
      children: <Widget>[
        paragraph(
          'The short version',
          'Your requests, folders, environments and history are stored on '
              'this device and nowhere else. There is no account, no sync, and no '
              'server of ours for them to go to.',
        ),
        paragraph(
          'What leaves the device',
          'Three things, and you start all of them. The API requests you press '
              'Send on, which go to the server whose URL you typed. A '
              'documentation link, when you tap one, which opens in your browser. '
              'And whatever you choose to share through the Android share sheet. '
              'Nothing else.',
        ),
        paragraph(
          'Variables and secrets',
          'A variable is stored as you typed it, braces and all. It is filled '
              'in at the moment of sending, and the filled-in text is discarded '
              'afterwards, so a secret does not end up copied through your '
              'history. A variable marked secret is masked in the app and left out '
              'of exports unless you turn that off for one export.',
        ),
        paragraph(
          'What is never collected',
          'No name, email address or phone number. No location. No advertising '
              'identifier. No usage statistics, and no record of which APIs you '
              'call. PostPurush contains no analytics, crash reporting or '
              'advertising library of any kind.',
        ),
        paragraph(
          'Permissions',
          'One: internet access, because sending HTTP requests is what this '
              'app is for. Nothing else is requested.',
        ),
        paragraph(
          'Certificate verification',
          'Settings can turn off TLS certificate verification, so you can test '
              'a local server with a self-signed certificate. While it is off, a '
              'request could be intercepted without warning you. Turn it back on '
              'afterwards.',
        ),
        paragraph(
          'Your control',
          'Delete any request, folder, environment or history entry from '
              'inside the app. Clear all history from Settings. Uninstalling '
              'removes the local database and every preference with it. There is '
              'no account to close, because there was never one to open.',
        ),
      ],
    );
  }
}
