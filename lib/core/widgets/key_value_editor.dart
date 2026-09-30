import 'package:flutter/material.dart';

import '../models/environment.dart';
import '../models/key_value.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../util/ids.dart';
import 'app_button.dart';
import 'app_icon_button.dart';
import 'app_menu.dart';
import 'app_snackbar.dart';
import 'cards.dart';
import 'dashed_border.dart';
import 'variable_text.dart';

/// The list of key/value rows: params, headers and form fields.
///
/// The board's three desktop columns become one stacked row per entry. A tap
/// opens it for editing in place, a swipe left deletes it with an undo strip,
/// and the overflow's Bulk edit swaps the whole list for a `key: value` text
/// area, which is quicker for pasting.
class KeyValueEditor extends StatefulWidget {
  const KeyValueEditor({
    required this.rows,
    required this.onChanged,
    required this.addLabel,
    this.env,
    this.emptyNote,
    this.reorderable = true,
    this.onSurface = false,
    super.key,
  });

  final List<KeyValueRow> rows;
  final ValueChanged<List<KeyValueRow>> onChanged;

  /// "Add header", "Add parameter", "Add field".
  final String addLabel;
  final Environment? env;

  /// Shown above the add row when the list is empty, in a dashed panel.
  final String? emptyNote;
  final bool reorderable;
  final bool onSurface;

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  /// Which row is open for editing. At most one at a time, which is what keeps
  /// the list readable on a phone.
  String? _editing;
  bool _bulk = false;
  TextEditingController? _bulkController;

  @override
  void dispose() {
    _bulkController?.dispose();
    super.dispose();
  }

  void _emit(List<KeyValueRow> rows) => widget.onChanged(rows);

  void _add() {
    final KeyValueRow row = KeyValueRow(id: newId());
    _emit(<KeyValueRow>[...widget.rows, row]);
    setState(() => _editing = row.id);
  }

  void _update(KeyValueRow row) => _emit(<KeyValueRow>[
    for (final KeyValueRow r in widget.rows) if (r.id == row.id) row else r,
  ]);

  void _delete(KeyValueRow row) {
    final int at = widget.rows.indexWhere((KeyValueRow r) => r.id == row.id);
    if (at < 0) return;
    final List<KeyValueRow> without = <KeyValueRow>[...widget.rows]
      ..removeAt(at);
    _emit(without);
    if (_editing == row.id) setState(() => _editing = null);
    AppSnackbar.undo(
      context,
      message: row.key.isEmpty ? 'Row deleted' : '${row.key} deleted',
      onUndo: () => _emit(<KeyValueRow>[...without]..insert(at, row)),
    );
  }

  /// `onReorderItem` already accounts for the removed item, so the new index
  /// is used as given.
  void _reorder(int from, int to) {
    final List<KeyValueRow> next = <KeyValueRow>[...widget.rows];
    next.insert(to, next.removeAt(from));
    _emit(next);
  }

  void _openBulk() {
    _bulkController?.dispose();
    _bulkController = TextEditingController(text: toBulkText(widget.rows));
    setState(() => _bulk = true);
  }

  void _applyBulk() {
    final String text = _bulkController?.text ?? '';
    _emit(fromBulkText(text, widget.rows));
    setState(() => _bulk = false);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    if (_bulk) {
      return _BulkEditor(
        controller: _bulkController!,
        onApply: _applyBulk,
        onCancel: () => setState(() => _bulk = false),
        onSurface: widget.onSurface,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.row,
      children: <Widget>[
        if (widget.rows.isEmpty && widget.emptyNote != null)
          _EmptyPanel(note: widget.emptyNote!, onAdd: _add, label: widget.addLabel)
        else
          RowGroup(
            onSurface: widget.onSurface,
            children: <Widget>[
              // A ReorderableListView inside a scrolling page needs its own
              // shrink-wrapped viewport; these lists are short (a handful of
              // headers), so the cost is bounded and the drag stays native.
              if (widget.reorderable)
                _ReorderableRows(
                  rows: widget.rows,
                  editing: _editing,
                  env: widget.env,
                  onReorder: _reorder,
                  onTap: (KeyValueRow r) => setState(
                    () => _editing = _editing == r.id ? null : r.id,
                  ),
                  onChanged: _update,
                  onDelete: _delete,
                  onDone: () => setState(() => _editing = null),
                )
              else
                for (final KeyValueRow row in widget.rows)
                  _Row(
                    row: row,
                    env: widget.env,
                    editing: _editing == row.id,
                    onTap: () => setState(
                      () => _editing = _editing == row.id ? null : row.id,
                    ),
                    onChanged: _update,
                    onDelete: () => _delete(row),
                    onDone: () => setState(() => _editing = null),
                  ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AddRowButton(label: widget.addLabel, onPressed: _add),
                  ),
                  Builder(
                    builder: (BuildContext anchor) => AppIconButton(
                      icon: Icons.more_horiz_rounded,
                      onPressed: () => _showOverflow(anchor),
                      semanticLabel: 'More options',
                      filled: false,
                      tint: c.iconMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _showOverflow(BuildContext anchor) async {
    final String? choice = await showAppMenu<String>(
      context: anchor,
      entries: const <AppMenuEntry<String>>[
        AppMenuEntry<String>(
          value: 'bulk',
          label: 'Bulk edit',
          icon: Icons.notes_rounded,
          note: 'key: value, one per line',
        ),
        AppMenuEntry<String>(
          value: 'enableAll',
          label: 'Enable all',
          icon: Icons.check_box_rounded,
        ),
        AppMenuEntry<String>(
          value: 'disableAll',
          label: 'Disable all',
          icon: Icons.check_box_outline_blank_rounded,
        ),
        AppMenuEntry<String>.divider(),
        AppMenuEntry<String>(
          value: 'clear',
          label: 'Remove all',
          icon: Icons.delete_outline_rounded,
          danger: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'bulk':
        _openBulk();
      case 'enableAll':
        _emit(<KeyValueRow>[
          for (final KeyValueRow r in widget.rows) r.copyWith(enabled: true),
        ]);
      case 'disableAll':
        _emit(<KeyValueRow>[
          for (final KeyValueRow r in widget.rows) r.copyWith(enabled: false),
        ]);
      case 'clear':
        final List<KeyValueRow> previous = List<KeyValueRow>.of(widget.rows);
        _emit(const <KeyValueRow>[]);
        if (!mounted) return;
        AppSnackbar.undo(
          context,
          message: 'All rows removed',
          onUndo: () => _emit(previous),
        );
    }
  }

  /// `key: value` per line, which is what the bulk editor shows and accepts.
  /// A disabled row keeps its `#` so a round trip does not enable it.
  static String toBulkText(List<KeyValueRow> rows) => rows
      .map(
        (KeyValueRow r) => '${r.enabled ? '' : '# '}${r.key}: ${r.value}',
      )
      .join('\n');

  /// Parses the bulk text back into rows, reusing the ids of rows whose key is
  /// unchanged so a bulk edit does not look like a delete and an insert.
  static List<KeyValueRow> fromBulkText(
    String text,
    List<KeyValueRow> existing,
  ) {
    final Map<String, KeyValueRow> byKey = <String, KeyValueRow>{
      for (final KeyValueRow r in existing) r.key: r,
    };
    final List<KeyValueRow> out = <KeyValueRow>[];
    for (final String line in text.split('\n')) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final bool off = trimmed.startsWith('#');
      final String body = off ? trimmed.substring(1).trim() : trimmed;
      final int colon = body.indexOf(':');
      final String key = (colon < 0 ? body : body.substring(0, colon)).trim();
      final String value = colon < 0 ? '' : body.substring(colon + 1).trim();
      if (key.isEmpty) continue;
      final KeyValueRow? old = byKey[key];
      out.add(
        (old ?? KeyValueRow(id: newId())).copyWith(
          key: key,
          value: value,
          enabled: !off,
        ),
      );
    }
    return out;
  }
}

class _ReorderableRows extends StatelessWidget {
  const _ReorderableRows({
    required this.rows,
    required this.editing,
    required this.env,
    required this.onReorder,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
    required this.onDone,
  });

  final List<KeyValueRow> rows;
  final String? editing;
  final Environment? env;
  final void Function(int from, int to) onReorder;
  final void Function(KeyValueRow) onTap;
  final void Function(KeyValueRow) onChanged;
  final void Function(KeyValueRow) onDelete;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: rows.length,
      onReorderItem: (int from, int to) => onReorder(from, to),
      // Dragging: 1.02 scale, no shadow, a 2dp primary outline (board 13).
      proxyDecorator:
          (Widget child, int index, Animation<double> animation) =>
              AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? _) => Transform.scale(
                  scale: 1 + 0.02 * animation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surfaceContainerHigh,
                      borderRadius: Radii.cardR,
                      border: Border.all(color: c.primary, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ),
      itemBuilder: (BuildContext context, int i) {
        final KeyValueRow row = rows[i];
        return Column(
          key: ValueKey<String>(row.id),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (i > 0) Divider(color: c.divider, height: 1),
            ReorderableDelayedDragStartListener(
              index: i,
              child: _Row(
                row: row,
                env: env,
                editing: editing == row.id,
                onTap: () => onTap(row),
                onChanged: onChanged,
                onDelete: () => onDelete(row),
                onDone: onDone,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.env,
    required this.editing,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
    required this.onDone,
  });

  final KeyValueRow row;
  final Environment? env;
  final bool editing;
  final VoidCallback onTap;
  final void Function(KeyValueRow) onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return _EditingRow(row: row, onChanged: onChanged, onDone: onDone);
    }
    final AppColors c = context.colors;
    return Dismissible(
      key: ValueKey<String>('dismiss-${row.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: c.dangerContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            Icon(
              Icons.delete_outline_rounded,
              size: IconSpec.size,
              color: c.onDangerContainer,
            ),
            Text(
              'Delete',
              style: AppType.titleMedium.copyWith(color: c.onDangerContainer),
            ),
          ],
        ),
      ),
      child: _CollapsedRow(
        row: row,
        env: env,
        onTap: onTap,
        onToggle: () => onChanged(row.copyWith(enabled: !row.enabled)),
        onDelete: onDelete,
      ),
    );
  }
}

class _CollapsedRow extends StatelessWidget {
  const _CollapsedRow({
    required this.row,
    required this.env,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final KeyValueRow row;
  final Environment? env;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color keyColour = row.enabled ? c.onSurface : c.onSurfaceMuted;
    final Color valueColour = row.enabled ? c.onSurfaceVariant : c.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          spacing: Space.xs,
          children: <Widget>[
            AppIconButton(
              icon: row.enabled
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              onPressed: onToggle,
              semanticLabel: row.enabled
                  ? 'Disable ${row.key}'
                  : 'Enable ${row.key}',
              filled: false,
              tint: row.enabled ? c.primary : c.iconMuted,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(
                    row.key.isEmpty ? 'New row' : row.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.monoTabular.copyWith(
                      color: keyColour,
                      fontWeight: FontWeight.w600,
                      decoration: row.enabled ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  VariableText.display(
                    text: row.value,
                    env: env,
                    colors: c,
                    base: AppType.monoTabular.copyWith(color: valueColour),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (row.description != null && row.description!.isNotEmpty)
                    Text(
                      row.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodySmall.copyWith(color: valueColour),
                    ),
                ],
              ),
            ),
            Builder(
              builder: (BuildContext anchor) => AppIconButton(
                icon: Icons.more_vert_rounded,
                onPressed: () async {
                  final String? choice = await showAppMenu<String>(
                    context: anchor,
                    entries: const <AppMenuEntry<String>>[
                      AppMenuEntry<String>(
                        value: 'edit',
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                      ),
                      AppMenuEntry<String>(
                        value: 'delete',
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        danger: true,
                      ),
                    ],
                  );
                  if (choice == 'edit') onTap();
                  if (choice == 'delete') onDelete();
                },
                semanticLabel: 'Options for ${row.key}',
                filled: false,
                tint: c.iconMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The open row: three stacked 44dp wells on a `surface` panel with a 2dp
/// `primary` edge down the left.
class _EditingRow extends StatefulWidget {
  const _EditingRow({
    required this.row,
    required this.onChanged,
    required this.onDone,
  });

  final KeyValueRow row;
  final void Function(KeyValueRow) onChanged;
  final VoidCallback onDone;

  @override
  State<_EditingRow> createState() => _EditingRowState();
}

class _EditingRowState extends State<_EditingRow> {
  late final TextEditingController _key = TextEditingController(
    text: widget.row.key,
  );
  late final TextEditingController _value = TextEditingController(
    text: widget.row.value,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.row.description ?? '',
  );

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    _description.dispose();
    super.dispose();
  }

  void _push() => widget.onChanged(
    widget.row.copyWith(
      key: _key.text,
      value: _value.text,
      description: _description.text.isEmpty ? null : _description.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(left: BorderSide(color: c.primary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'EDITING',
                  style: AppType.sectionHeader.copyWith(color: c.accent),
                ),
              ),
              AppIconButton(
                icon: Icons.check_rounded,
                onPressed: () {
                  _push();
                  widget.onDone();
                },
                semanticLabel: 'Done editing',
                filled: false,
                size: 40,
                glyphSize: IconSpec.small,
                tint: c.accent,
              ),
            ],
          ),
          _Well(controller: _key, hint: 'Key', mono: true, onChanged: _push),
          _Well(
            controller: _value,
            hint: 'Value',
            mono: true,
            autofocus: widget.row.key.isEmpty,
            onChanged: _push,
          ),
          _Well(
            controller: _description,
            hint: 'Description (optional)',
            mono: false,
            onChanged: _push,
          ),
        ],
      ),
    );
  }
}

class _Well extends StatefulWidget {
  const _Well({
    required this.controller,
    required this.hint,
    required this.mono,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool mono;
  final VoidCallback onChanged;
  final bool autofocus;

  @override
  State<_Well> createState() => _WellState();
}

class _WellState extends State<_Well> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_sync);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_sync)
      ..dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool focused = _focus.hasFocus;
    final TextStyle style = (widget.mono ? AppType.monoTabular : AppType.bodyMedium)
        .copyWith(color: c.onSurface);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: Radii.thumbR,
        border: Border.all(
          color: focused ? c.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        style: style,
        onChanged: (_) => widget.onChanged(),
        cursorColor: c.primary,
        cursorWidth: 2,
        autocorrect: !widget.mono,
        enableSuggestions: !widget.mono,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: Space.md),
          hintText: widget.hint,
          hintStyle: style.copyWith(color: c.onSurfaceMuted),
        ),
      ),
    );
  }
}

class _BulkEditor extends StatelessWidget {
  const _BulkEditor({
    required this.controller,
    required this.onApply,
    required this.onCancel,
    required this.onSurface,
  });

  final TextEditingController controller;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.row,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: onSurface ? c.surface : c.surfaceContainer,
            borderRadius: Radii.cardR,
            border: Border.all(color: c.outline),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            minLines: 5,
            autofocus: true,
            style: AppType.monoTabular.copyWith(color: c.onSurface),
            cursorColor: c.primary,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Content-Type: application/json\n# X-Debug: true',
              hintStyle: AppType.monoTabular.copyWith(color: c.onSurfaceMuted),
            ),
          ),
        ),
        Text(
          'One per line, as key: value. A line starting with # is off.',
          style: AppType.bodySmall.copyWith(color: c.onSurfaceVariant),
        ),
        Row(
          spacing: Space.row,
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Cancel',
                onPressed: onCancel,
                type: AppButtonType.outlined,
                fullWidth: true,
              ),
            ),
            Expanded(
              child: AppButton(
                label: 'Apply',
                onPressed: onApply,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The dashed panel the board draws where params will appear.
class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.note,
    required this.onAdd,
    required this.label,
  });

  final String note;
  final VoidCallback onAdd;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(c.outline, radius: Radii.card),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.screen,
          Space.screen,
          Space.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.md,
          children: <Widget>[
            Text(
              note,
              style: AppType.note.copyWith(color: c.onSurfaceVariant),
            ),
            AddRowButton(label: label, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
