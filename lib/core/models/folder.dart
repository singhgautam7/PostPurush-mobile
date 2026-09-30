import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

/// A collection, or a subfolder of one. The board draws both the same way and
/// only indents the child (2.10), so there is one model and no depth limit.
@freezed
abstract class Folder with _$Folder {
  const factory Folder({
    required String id,
    @Default('') String name,
    @Default('') String description,

    /// Null for a top-level collection.
    String? parentId,
    @Default(0) int order,
    @Default(1) int schemaVersion,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  /// The current shape. Keep this and the `@Default` above in step: the
  /// generated code copies that annotation verbatim, where a static on this
  /// class is not in scope, so the literal cannot be replaced by the constant.
  static const int schema = 1;
}
