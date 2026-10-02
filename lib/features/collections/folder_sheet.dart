import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/folder.dart';
import '../../core/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/fields.dart';

/// New folder, or rename one. A name and, optionally, a parent.
Future<String?> showFolderSheet(
  BuildContext context,
  WidgetRef ref, {
  Folder? existing,
  String? parentId,
}) async {
  final List<Folder> folders = ref.read(foldersProvider).value ??
      const <Folder>[];
  return showAppSheet<String>(
    context: context,
    title: existing == null ? 'New folder' : 'Rename folder',
    note: existing == null && folders.isNotEmpty
        ? '${folders.length} so far'
        : null,
    builder: (BuildContext context) => _FolderForm(
      existing: existing,
      parentId: parentId ?? existing?.parentId,
      folders: folders,
      onSave: (String name, String? parent) async {
        final Folder folder = (existing ?? Folder(id: newId())).copyWith(
          name: name,
          parentId: parent,
          order: existing?.order ?? folders.length,
        );
        await ref.read(collectionsRepositoryProvider).saveFolder(folder);
        return folder.id;
      },
    ),
  );
}

class _FolderForm extends StatefulWidget {
  const _FolderForm({
    required this.existing,
    required this.parentId,
    required this.folders,
    required this.onSave,
  });

  final Folder? existing;
  final String? parentId;
  final List<Folder> folders;
  final Future<String> Function(String name, String? parentId) onSave;

  @override
  State<_FolderForm> createState() => _FolderFormState();
}

class _FolderFormState extends State<_FolderForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String? _parent = widget.parentId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final String id = await widget.onSave(name, _parent);
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    // A folder cannot be its own parent, nor sit inside its own subtree.
    final Set<String> forbidden = <String>{
      if (widget.existing != null) widget.existing!.id,
    };
    bool grew = true;
    while (grew) {
      grew = false;
      for (final Folder f in widget.folders) {
        if (f.parentId != null &&
            forbidden.contains(f.parentId) &&
            forbidden.add(f.id)) {
          grew = true;
        }
      }
    }
    final List<Folder> options = <Folder>[
      for (final Folder f in widget.folders)
        if (!forbidden.contains(f.id)) f,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: <Widget>[
        LabelledField(
          label: 'Name',
          controller: _name,
          hint: 'Testing APIs',
          autofocus: true,
          onSurface: true,
          onSubmitted: (_) => _submit(),
        ),
        if (options.isNotEmpty)
          RowGroup(
            onSurface: true,
            children: <Widget>[
              AppRow(
                title: 'No parent',
                subtitle: 'top level of Folders',
                leading: const Icon(Icons.home_rounded, size: IconSpec.size),
                selected: _parent == null,
                trailing: Icon(
                  _parent == null
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: IconSpec.size,
                ),
                onTap: () => setState(() => _parent = null),
              ),
              for (final Folder f in options)
                AppRow(
                  title: f.name,
                  leading: const Icon(
                    Icons.folder_rounded,
                    size: IconSpec.size,
                  ),
                  selected: _parent == f.id,
                  trailing: Icon(
                    _parent == f.id
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: IconSpec.size,
                  ),
                  onTap: () => setState(() => _parent = f.id),
                ),
            ],
          ),
        Row(
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
                  label: widget.existing == null ? 'Create' : 'Rename',
                  icon: Icons.check_rounded,
                  onPressed: value.text.trim().isEmpty ? null : _submit,
                  fullWidth: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
