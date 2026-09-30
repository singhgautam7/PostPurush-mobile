import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_db.dart';
import '../../core/db/collections_repository.dart';
import '../../core/models/api_request.dart';
import '../../core/models/folder.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import '../collections/folder_sheet.dart';

/// What the save sheet decided.
class SaveTarget {
  const SaveTarget({required this.name, required this.folderId});

  final String name;

  /// Null means the top level of Collections.
  final String? folderId;
}

/// Board 2.10. Name it, then pick a folder, a subfolder, no folder at all, or
/// make a new one. The folder the last save went to is preselected.
Future<SaveTarget?> showSaveRequestSheet(
  BuildContext context,
  WidgetRef ref, {
  required ApiRequest request,
}) async {
  final List<Folder> folders = ref.read(foldersProvider).value ??
      const <Folder>[];
  final List<ApiRequest> requests = ref.read(requestsProvider).value ??
      const <ApiRequest>[];
  final String? lastFolder = await ref
      .read(appStateRepositoryProvider)
      .read(StateKeys.lastFolder);
  if (!context.mounted) return null;

  return showAppSheet<SaveTarget>(
    context: context,
    title: 'Save request',
    subtitle: '${request.method.label} · ${request.url}',
    builder: (BuildContext context) => _SaveForm(
      request: request,
      folders: folders,
      requests: requests,
      initialFolder: request.folderId ?? lastFolder,
    ),
  );
}

class _SaveForm extends ConsumerStatefulWidget {
  const _SaveForm({
    required this.request,
    required this.folders,
    required this.requests,
    required this.initialFolder,
  });

  final ApiRequest request;
  final List<Folder> folders;
  final List<ApiRequest> requests;
  final String? initialFolder;

  @override
  ConsumerState<_SaveForm> createState() => _SaveFormState();
}

class _SaveFormState extends ConsumerState<_SaveForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.request.name.isEmpty
        ? _suggestName(widget.request)
        : widget.request.name,
  );
  late String? _folder = _stillExists(widget.initialFolder)
      ? widget.initialFolder
      : null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _stillExists(String? id) =>
      id != null && widget.folders.any((Folder f) => f.id == id);

  /// The last path segment makes a better first guess than "Untitled".
  static String _suggestName(ApiRequest request) {
    final Uri? uri = Uri.tryParse(request.url);
    final List<String> segments = uri?.pathSegments ?? const <String>[];
    for (final String segment in segments.reversed) {
      if (segment.isEmpty || int.tryParse(segment) != null) continue;
      return '${request.method.label} $segment';
    }
    return uri?.host ?? '';
  }

  void _submit() {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(SaveTarget(name: name, folderId: _folder));
  }

  Future<void> _newFolder() async {
    final String? id = await showFolderSheet(context, ref);
    if (id != null && mounted) setState(() => _folder = id);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<Folder> tree = _flatten(widget.folders);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: <Widget>[
        LabelledField(
          label: 'Name',
          controller: _name,
          hint: 'Create post',
          autofocus: true,
          onSurface: true,
          onSubmitted: (_) => _submit(),
        ),
        SectionHeader(
          label: 'Save to',
          note: _folder == widget.initialFolder && _folder != null
              ? 'last used'
              : null,
        ),
        RowGroup(
          onSurface: true,
          children: <Widget>[
            AppRow(
              title: 'No folder',
              subtitle: 'top level of Collections',
              leading: Icon(
                Icons.home_rounded,
                size: IconSpec.size,
                color: c.iconMuted,
              ),
              selected: _folder == null,
              trailing: _Radio(selected: _folder == null),
              onTap: () => setState(() => _folder = null),
            ),
            for (final Folder f in tree)
              AppRow(
                title: f.name,
                count: '${CollectionsRepository.countIn(f.id, widget.folders, widget.requests)}',
                indent: _depthOf(f, widget.folders) * Space.xl,
                leading: Icon(
                  _depthOf(f, widget.folders) == 0
                      ? Icons.folder_rounded
                      : Icons.subdirectory_arrow_right_rounded,
                  size: IconSpec.size,
                  color: _folder == f.id ? c.onPrimaryContainer : c.iconMuted,
                ),
                selected: _folder == f.id,
                trailing: _Radio(selected: _folder == f.id),
                onTap: () => setState(() => _folder = f.id),
              ),
            AddRowButton(
              label: 'New folder',
              icon: Icons.create_new_folder_rounded,
              onPressed: _newFolder,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Row(
            spacing: Space.row,
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  type: AppButtonType.outlined,
                  fullWidth: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (BuildContext context, TextEditingValue value, Widget? _) => AppButton(
                    label: 'Save',
                    icon: Icons.save_rounded,
                    onPressed: value.text.trim().isEmpty ? null : _submit,
                    fullWidth: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Parents before their children, so the indent reads as a tree.
  static List<Folder> _flatten(List<Folder> folders, [String? parent, int depth = 0]) {
    if (depth > 8) return const <Folder>[];
    final List<Folder> out = <Folder>[];
    for (final Folder f in folders) {
      if (f.parentId != parent) continue;
      out
        ..add(f)
        ..addAll(_flatten(folders, f.id, depth + 1));
    }
    return out;
  }

  static int _depthOf(Folder folder, List<Folder> folders) {
    int depth = 0;
    String? parent = folder.parentId;
    while (parent != null && depth < 8) {
      depth++;
      parent = folders
          .where((Folder f) => f.id == parent)
          .map((Folder f) => f.parentId)
          .firstOrNull;
    }
    return depth;
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      width: IconSpec.tapTarget,
      height: IconSpec.tapTarget,
      child: Center(
        child: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          size: IconSpec.size,
          color: selected ? c.primary : c.iconMuted,
        ),
      ),
    );
  }
}
