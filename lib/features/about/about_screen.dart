import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../more/more_screen.dart';
import 'app_mark.dart';

/// Board 8. The local-first statement is the main content, with the usual rows
/// below it.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
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
                    'v${AboutInfo.version} · build ${AboutInfo.build}',
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
        RowGroup(
          children: <Widget>[
            AppRow(
              title: 'Share PostPurush',
              leading: Icon(
                Icons.share_outlined,
                size: IconSpec.small,
                color: c.icon,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: IconSpec.small,
                color: c.onSurfaceMuted,
              ),
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      'PostPurush, a local-first API client for Android. '
                      '${AboutInfo.repository}',
                  subject: 'PostPurush',
                ),
              ),
            ),
            AppRow(
              title: 'Source',
              subtitle: AboutInfo.repository.replaceFirst(
                RegExp('^https?://'),
                '',
              ),
              leading: Icon(
                Icons.code_rounded,
                size: IconSpec.small,
                color: c.icon,
              ),
              trailing: Icon(
                Icons.open_in_new_rounded,
                size: IconSpec.small,
                color: c.onSurfaceMuted,
              ),
              onTap: () async {
                final Uri uri = Uri.parse(AboutInfo.repository);
                final bool opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && context.mounted) {
                  await Clipboard.setData(
                    const ClipboardData(text: AboutInfo.repository),
                  );
                  if (context.mounted) {
                    AppSnackbar.info(context, 'Link copied instead');
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        Text(
          'Built with Flutter. The bundled catalogue of public APIs comes from '
          'the public-apis project.',
          style: AppType.bodySmall.copyWith(color: c.onSurfaceVariant),
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
          'Your requests, collections, environments and history are stored on '
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
