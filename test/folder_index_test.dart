import 'package:flutter_test/flutter_test.dart';
import 'package:postpurush/core/db/collections_repository.dart';
import 'package:postpurush/core/models/api_request.dart';
import 'package:postpurush/core/models/folder.dart';

Folder _folder(String id, {String? parent}) =>
    Folder(id: id, name: id, parentId: parent);

ApiRequest _request(String id, {String? folder}) => ApiRequest(
  id: id,
  url: 'https://example.com/$id',
  folderId: folder,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('counts a folder, its subfolders and nothing else', () {
    final FolderIndex index = FolderIndex.of(
      <Folder>[
        _folder('a'),
        _folder('a1', parent: 'a'),
        _folder('a2', parent: 'a'),
        _folder('b'),
      ],
      <ApiRequest>[
        _request('1', folder: 'a'),
        _request('2', folder: 'a1'),
        _request('3', folder: 'a2'),
        _request('4', folder: 'b'),
        _request('5'),
      ],
    );

    expect(index.totalIn('a'), 3);
    expect(index.totalIn('a1'), 1);
    expect(index.totalIn('b'), 1);
    expect(index.roots.map((Folder f) => f.id), <String>['a', 'b']);
    expect(index.unfiled.single.id, '5');
    expect(index.childrenOf('a').map((Folder f) => f.id), <String>['a1', 'a2']);
    expect(index.requestsOf('a').single.id, '1');
  });

  test('counts through more than one level', () {
    final FolderIndex index = FolderIndex.of(
      <Folder>[
        _folder('a'),
        _folder('b', parent: 'a'),
        _folder('c', parent: 'b'),
      ],
      <ApiRequest>[_request('1', folder: 'c'), _request('2', folder: 'b')],
    );
    expect(index.totalIn('a'), 2);
    expect(index.totalIn('b'), 2);
    expect(index.totalIn('c'), 1);
  });

  test('a parent cycle in a corrupt payload terminates', () {
    // Not reachable through the app, but a payload written by a newer build
    // could say this, and the home screen must still draw.
    final FolderIndex index = FolderIndex.of(
      <Folder>[_folder('a', parent: 'b'), _folder('b', parent: 'a')],
      <ApiRequest>[_request('1', folder: 'a')],
    );
    expect(index.totalIn('a'), greaterThanOrEqualTo(1));
    expect(index.roots, isEmpty);
  });

  test('agrees with the single-folder count it replaces', () {
    final List<Folder> folders = <Folder>[
      _folder('a'),
      _folder('a1', parent: 'a'),
      _folder('b'),
    ];
    final List<ApiRequest> requests = <ApiRequest>[
      _request('1', folder: 'a'),
      _request('2', folder: 'a1'),
      _request('3', folder: 'b'),
    ];
    final FolderIndex index = FolderIndex.of(folders, requests);
    for (final Folder f in folders) {
      expect(
        index.totalIn(f.id),
        CollectionsRepository.countIn(f.id, folders, requests),
        reason: f.id,
      );
    }
  });
}
