import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/http/code_export.dart';
import '../../core/http/request_builder.dart';
import '../../core/http/variable_resolver.dart';
import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/fields.dart';
import '../settings/settings_controller.dart';

/// Board 9. Variables are resolved from the active environment; secrets stay
/// masked unless the switch is turned on, so a pasted snippet cannot leak a
/// token by accident. The language used last is remembered.
Future<void> showCodeExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required ApiRequest request,
}) => showAppSheet<void>(
  context: context,
  title: 'Export code',
  subtitle: _subtitle(request, ref.read(activeEnvironmentProvider)),
  builder: (BuildContext context) => _CodeExportBody(request: request),
);

String _subtitle(ApiRequest request, Environment? env) {
  final String name = request.displayName;
  final String where = env == null
      ? 'no environment'
      : 'resolved with ${env.name}';
  return '${request.method.label} $name · $where';
}

class _CodeExportBody extends ConsumerStatefulWidget {
  const _CodeExportBody({required this.request});

  final ApiRequest request;

  @override
  ConsumerState<_CodeExportBody> createState() => _CodeExportBodyState();
}

class _CodeExportBodyState extends ConsumerState<_CodeExportBody> {
  late CodeLanguage _language = ref.read(settingsProvider).lastExportLanguage;
  bool _includeSecrets = false;

  /// Which variables in this request came from secret values, so the sheet can
  /// name them rather than saying "some are hidden".
  List<String> _secretNames(Environment? env) {
    if (env == null) return const <String>[];
    final Set<String> names = <String>{};
    for (final String template in RequestBuilder.templateStrings(
      widget.request,
    )) {
      for (final VariableSpan span in VariableResolver.scan(template, env)) {
        if (span.secret && span.resolved) names.add(span.name);
      }
    }
    return names.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Environment? env = ref.watch(activeEnvironmentProvider);
    final List<String> secrets = _secretNames(env);
    final WireRequest wire = RequestBuilder.build(
      widget.request,
      env,
      maskSecrets: !_includeSecrets,
    );
    final String snippet = CodeExport.render(wire, _language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: Space.sm,
            children: <Widget>[
              for (final CodeLanguage language in CodeLanguage.values)
                PillChip(
                  label: language.label,
                  selected: language == _language,
                  onTap: () {
                    setState(() => _language = language);
                    ref
                        .read(settingsProvider.notifier)
                        .setExportLanguage(language);
                  },
                ),
            ],
          ),
        ),
        CodeBlock(
          source: snippet,
          onSurface: true,
          maxHeight: MediaQuery.sizeOf(context).height * 0.34,
        ),
        if (secrets.isNotEmpty)
          SwitchRow(
            label: 'Include secrets',
            note: '${secrets.length} masked: ${secrets.join(', ')}',
            icon: Icons.lock_outline_rounded,
            value: _includeSecrets,
            onChanged: (bool value) => setState(() => _includeSecrets = value),
          ),
        if (wire.missing.isNotEmpty)
          Text(
            '${wire.missing.join(', ')} ${wire.missing.length == 1 ? 'is' : 'are'} '
            'not in ${env?.name ?? 'any environment'}, so the snippet still '
            'carries the braces.',
            style: AppType.bodySmall.copyWith(color: c.onSurfaceVariant),
          ),
        Row(
          spacing: Space.row,
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Share',
                icon: Icons.share_outlined,
                type: AppButtonType.outlined,
                fullWidth: true,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: snippet,
                    subject:
                        '${widget.request.displayName} · ${_language.label}',
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Copy ${_language.label}',
                icon: Icons.content_copy_rounded,
                fullWidth: true,
                onPressed: () async {
                  await copyToClipboard(snippet);
                  if (context.mounted) {
                    AppSnackbar.info(context, '${_language.label} copied');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
