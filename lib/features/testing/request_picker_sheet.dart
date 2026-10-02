import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/api_request.dart';
import '../../core/models/folder.dart';
import '../../core/providers.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';

/// Picks a saved request. Used by Testing and by API docs, so the two show the
/// same list in the same order.
Future<ApiRequest?> showRequestPickerSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final List<ApiRequest> requests = ref.read(requestsProvider).value ??
      const <ApiRequest>[];
  final List<Folder> folders = ref.read(foldersProvider).value ??
      const <Folder>[];
  final Map<String, String> names = <String, String>{
    for (final Folder f in folders) f.id: f.name,
  };

  return showAppSheet<ApiRequest>(
    context: context,
    title: 'Pick a request',
    note: '${requests.length} saved',
    expand: requests.length > 6,
    builder: (BuildContext context) => RowGroup(
      onSurface: true,
      children: <Widget>[
        for (final ApiRequest r in requests)
          AppRow(
            title: r.displayName,
            subtitle: <String>[
              if (r.folderId != null) names[r.folderId] ?? 'Deleted folder',
              Fmt.bareUrl(r.url),
            ].join(' · '),
            minHeight: 60,
            leading: MethodChip(r.method),
            onTap: () => Navigator.of(context).pop(r),
          ),
      ],
    ),
  );
}
