import 'dart:async';

import 'package:flutter/material.dart' hide Material;
import 'package:go_router/go_router.dart';
import 'package:lazyext/app/document_source.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/google/drive.dart';
import 'package:lazyext/google/oauth.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:mupdf_android/mupdf_android.dart' as mupdf;
import 'package:provider/provider.dart';

class DocumentsScreen extends StatefulWidget {
  final (int, DocumentEntity)? entity;
  const DocumentsScreen({super.key, this.entity});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    entities = [
      ClassroomRootDocumentEntity(
          null,
          Provider.of<Classroom>(context, listen: false),
          Provider.of<CachedTeacherProvider>(context, listen: false),
          Provider.of<Drive>(context, listen: false),
          Provider.of<OAuth>(context, listen: false))
    ];
    current = List.from(entities);
    (int, DocumentEntity)? entity = widget.entity;
    if (entity != null) {
      current[entity.$1] = entity.$2;
    }
  }

  late final List<DocumentEntity> entities;
  late final List<DocumentEntity> current;

  @override
  void didUpdateWidget(covariant DocumentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    (int, DocumentEntity)? entity = widget.entity;
    if (entity != null) {
      current[entity.$1] = entity.$2;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [];
    for (int i = 0; i < current.length; i++) {
      tabs.add(DocumentEntityListView(
        index: i,
        entity: current[i],
      ));
    }
    return ScreenWidget(
      title: "Documents",
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Visibility(
            visible: loading,
            child: const LinearProgressIndicator(),
          )),
      floatingActionButton: Consumer<DocumentSelectionProvider>(
          builder: (context, provider, child) {
        return Visibility(
            visible: provider._entries.isNotEmpty,
            child: FloatingActionButton.extended(
              label: const Text("Open"),
              icon: const Icon(Icons.file_open),
              onPressed: () async {
                setState(() => loading = true);
                List<Document> documents = await provider.documents.toList();
                List<Future<mupdf.PDFDocument?>> jobs = documents.fold(
                    [],
                    (previousValue, element) =>
                        previousValue + [element.document]);
                if (!mounted) return;
                await context.push("/compare",
                    extra: (await jobs.wait).nonNulls);
                setState(() => loading = false);
              },
            ));
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: DefaultTabController(
        length: entities.length,
        child: Column(
          children: [
            TabBar(
                tabs: entities
                    .map((e) => FutureBuilder<String?>(
                        future: e.title,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Tab(text: snapshot.data);
                          } else {
                            return const Tab(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                        }))
                    .toList()),
            Expanded(
              child: TabBarView(
                children: tabs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentEntityListItem extends StatefulWidget {
  final DocumentEntity entity;
  final int index;
  const DocumentEntityListItem({
    super.key,
    required this.entity,
    required this.index,
  });

  @override
  State<DocumentEntityListItem> createState() => _DocumentEntityListItemState();
}

class _DocumentEntityListItemState extends State<DocumentEntityListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: FutureBuilder<String?>(
          future: widget.entity.title,
          builder: (context, snapshot) {
            String? data = snapshot.data;
            if (data != null) {
              return Text(data);
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
      subtitle: widget.entity is! Document
          ? FutureBuilder<String?>(
              future: widget.entity.subtitle,
              builder: (context, snapshot) {
                String? data = snapshot.data;
                if (data != null) {
                  return Text(data);
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })
          : null,
      trailing: Consumer<DocumentSelectionProvider>(
          builder: (context, provider, child) {
        return FutureBuilder<bool?>(
            future: provider.isSelected(widget.entity),
            builder: (context, snapshot) {
              return Checkbox(
                  tristate: true,
                  value: snapshot.data,
                  onChanged: (bool? value) async {
                    if (value == null) {
                      value = false;
                      DocumentEntity? parent = widget.entity.parent;
                      if (parent != null) {
                        bool? isParentSelected =
                            await provider.isSelected(parent);
                        if (isParentSelected ?? false) {
                          value = false;
                        } else {
                          value = false;
                        }
                      }
                    }
                    await provider.updateSelection(widget.entity, value);
                  });
            });
      }),
      onTap: widget.entity
              is! Document // TODO: handle if Document contains entities...
          ? () async {
              context.push("/sources", extra: (widget.index, widget.entity));
            }
          : null,
    );
  }
}

class DocumentEntityListView<T> extends StatefulWidget {
  final DocumentEntity entity;
  final int index;
  const DocumentEntityListView({
    super.key,
    required this.entity,
    required this.index,
  });

  @override
  State<DocumentEntityListView> createState() =>
      _DocumentEntityListViewState<T>();
}

class _DocumentEntityListViewState<T> extends State<DocumentEntityListView> {
  List<DocumentEntity> entities = [];

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    sub = widget.entity.entities
        .listen((event) => setState(() => entities.add(event)));
  }

  @override
  void didUpdateWidget(DocumentEntityListView replacement) {
    super.didUpdateWidget(replacement);
    if (widget.entity != replacement.entity) {
      entities = [];
      sub?.cancel();
      sub = replacement.entity.entities
          .listen((event) => setState(() => entities.add(event)));
    }
  }

  @override
  void dispose() {
    super.dispose();
    sub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entities.length,
      itemBuilder: (context, index) {
        return DocumentEntityListItem(
          entity: entities[index],
          index: widget.index,
        );
      },
    );
  }
}

typedef DocumentSelectionMap = Map<DocumentEntity, (bool, Set<DocumentEntity>)>;
typedef DocumentSelectionMapEntry
    = MapEntry<DocumentEntity, (bool, Set<DocumentEntity>)>;

extension on DocumentSelectionMap {
  Future<void> delete(DocumentEntity entity) async {
    for (DocumentSelectionMapEntry entry in List.from(entries)) {
      DocumentEntity? parent = entity.parent;
      if (parent != null) {
        if (await entry.key.isEqual(entity)) {
          remove(entry.key);
        }
      }
    }
  }

  Future<void> add(DocumentEntity entity) async {
    for (DocumentSelectionMapEntry entry in List.from(entries)) {
      if (await entry.key.isEqual(entity)) {
        this[entry.key] = (true, {});
        return;
      }
    }
    this[entity] = (true, {});
  }

  Future<void> exclude(DocumentEntity entity) async {
    DocumentEntity? parent = entity.parent;
    if (parent != null) {
      if (!await containsEntity(parent, keys)) {
        this[parent] = (false, {});
      }
      for (DocumentSelectionMapEntry entry in List.from(entries)) {
        if (await entry.key.isEqual(parent)) {
          if (!await containsEntity(entity, entry.value.$2)) {
            this[entry.key]?.$2.add(entity);
            exclude(parent);
          }
          return;
        }
      }
    }
  }

  Future<bool> containsEntity(
          DocumentEntity entity, Iterable<DocumentEntity> entities) async =>
      (await entities
              .map((element) async => await element.isEqual(entity))
              .wait)
          .any((element) => element);

  Future<(bool, Set<DocumentEntity>)?> getExcluded(
      DocumentEntity entity) async {
    for (DocumentSelectionMapEntry entry in entries) {
      if (await entry.key.isEqual(entity)) return entry.value;
    }
    return null;
  }

  Future<bool> isExcluded(DocumentEntity entity) async {
    DocumentEntity? parent = entity.parent;
    if (parent != null) {
      Iterable<DocumentEntity>? excluded = (await getExcluded(parent))?.$2;
      if (excluded == null) {
        return false;
      } else {
        return entity.isInList(excluded);
      }
    } else {
      return false;
    }
  }
}

extension on DocumentEntity {
  Future<bool> isInList(Iterable<DocumentEntity> entities) async =>
      (await entities.map((element) async => await element.isEqual(this)).wait)
          .any((element) => element);
}

class DocumentSelectionProvider extends ChangeNotifier {
  final DocumentSelectionMap _entries = {};

  void excludeRootChildren(DocumentEntity root) async {
    await for (DocumentEntity entity in root.entities) {
      _entries.exclude(entity);
    }
  }

  Stream<Document> get documents async* {
    Stream<Document> yieldEntity(
        DocumentEntity entity, (bool, Set<DocumentEntity>) excluded) async* {
      if (excluded.$1) {
        await for (DocumentEntity children in entity.entities) {
          if (!await children.isInList(excluded.$2) && children is Document) {
            yield children;
          }
          await for (DocumentEntity result
              in yieldEntity(children, (true, {}))) {
            if (result is Document) yield result;
          }
        }
      }
    }

    for (DocumentSelectionMapEntry entry in List.from(_entries.entries)) {
      DocumentEntity key = entry.key;
      if (key is Document) yield key;
      await for (Document result in yieldEntity(key, entry.value)) {
        yield result;
      }
    }
  }

  Future<bool?> isSelected(DocumentEntity entity) async {
    // ignore: no_leading_underscores_for_local_identifiers
    DocumentSelectionMap _entries = Map.from(this._entries);
    bool isContained =
        await _entries.containsEntity(entity, _entries.keys.toSet());
    if (isContained) {
      (bool, Set<DocumentEntity>)? excluded =
          await _entries.getExcluded(entity);
      bool hasExcluded = excluded?.$2.isNotEmpty ?? false;
      if (hasExcluded) {
        return null;
      } else {
        return true;
      }
    } else {
      bool isExcluded = await _entries.isExcluded(entity);
      if (isExcluded) {
        return false;
      } else {
        DocumentEntity? parent = entity.parent;
        if (parent != null) {
          (bool, Set<DocumentEntity>)? excluded =
              await _entries.getExcluded(parent);
          return await isSelected(parent) ?? excluded?.$1 ?? false;
        } else {
          return false;
        }
      }
    }
  }

  Future<void> updateSelection(DocumentEntity entity, bool value) async {
    await _entries.exclude(entity);
    if (value) {
      await _entries.add(entity);
    } else {
      await _entries.delete(entity);
    }
    notifyListeners();
  }
}
