import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/explore_api.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import 'explore_repository.dart';
import 'explore_screen.dart';

/// Board 3.3. A pushed page, so the nav leaves and the primary action floats
/// where it was. Docs open in the browser, which is the OS handoff and the only
/// other traffic this app makes.
class ExploreApiScreen extends ConsumerStatefulWidget {
  const ExploreApiScreen({required this.name, super.key});

  final String name;

  @override
  ConsumerState<ExploreApiScreen> createState() => _ExploreApiScreenState();
}

class _ExploreApiScreenState extends ConsumerState<ExploreApiScreen> {
  int _sample = 0;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<ExploreApi> all = ref.watch(exploreApisProvider).value ??
        const <ExploreApi>[];
    final ExploreApi? api = all
        .where((ExploreApi a) => a.name == widget.name)
        .firstOrNull;

    if (api == null) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'API', onBack: () => context.pop()),
              const Expanded(
                child: ErrorStateView(
                  message: 'That API is not in the bundled catalogue.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int index = _sample.clamp(
      0,
      api.samples.isEmpty ? 0 : api.samples.length - 1,
    );

    return PageScaffold(
      title: api.name,
      subtitle: api.category,
      actions: <Widget>[
        if (api.docsUrl.isNotEmpty)
          AppIconButton(
            icon: Icons.open_in_new_rounded,
            onPressed: () => _openDocs(api.docsUrl),
            semanticLabel: 'Open the documentation',
          ),
      ],
      floating: AppButton(
        label: 'Open as request',
        icon: Icons.bolt_rounded,
        filledIcon: true,
        fullWidth: true,
        onPressed: () => openAsRequest(
          context,
          ref,
          api,
          sample: api.samples.isEmpty ? null : api.samples[index],
        ),
      ),
      bottomPadding: 120,
      children: <Widget>[
        Text(
          api.description,
          style: AppType.body.copyWith(color: c.onSurface),
        ),
        const SizedBox(height: Space.xl),
        RowGroup(
          children: <Widget>[
            AppRow(
              title: 'Auth',
              count: api.auth.filterLabel,
              minHeight: 52,
            ),
            AppRow(
              title: 'HTTPS',
              count: api.https ? 'Yes' : 'No',
              minHeight: 52,
              leading: Icon(
                api.https ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: IconSpec.small,
                color: api.https ? c.success : c.iconMuted,
              ),
            ),
            AppRow(
              title: 'Base URL',
              subtitle: api.baseUrl,
              minHeight: 60,
              trailing: AppIconButton(
                icon: Icons.content_copy_rounded,
                onPressed: () async {
                  await copyToClipboard(api.baseUrl);
                  if (context.mounted) {
                    AppSnackbar.info(context, 'Base URL copied');
                  }
                },
                semanticLabel: 'Copy the base URL',
                filled: false,
                tint: c.iconMuted,
              ),
            ),
            if (api.docsUrl.isNotEmpty)
              AppRow(
                title: 'Docs',
                subtitle: Fmt.bareUrl(api.docsUrl),
                minHeight: 60,
                trailing: AppIconButton(
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => _openDocs(api.docsUrl),
                  semanticLabel: 'Open the documentation',
                  filled: false,
                  tint: c.iconMuted,
                ),
              ),
          ],
        ),
        if (api.samples.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.xl),
          SectionHeader(
            label: 'Start from',
            note: '${api.samples.length} '
                '${api.samples.length == 1 ? 'endpoint' : 'endpoints'}',
          ),
          const SizedBox(height: Space.row),
          RowGroup(
            children: <Widget>[
              for (int i = 0; i < api.samples.length; i++)
                AppRow(
                  title: api.samples[i].path,
                  subtitle: api.samples[i].description,
                  minHeight: 60,
                  leading: MethodChip(api.samples[i].method),
                  selected: i == index,
                  trailing: SizedBox(
                    width: IconSpec.tapTarget,
                    height: IconSpec.tapTarget,
                    child: Center(
                      child: Icon(
                        i == index
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: IconSpec.size,
                        color: i == index ? c.primary : c.iconMuted,
                      ),
                    ),
                  ),
                  onTap: () => setState(() => _sample = i),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openDocs(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      AppSnackbar.info(context, 'No app could open that link');
    }
  }
}
