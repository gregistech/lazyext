import 'dart:async';

import 'package:flutter/material.dart' hide Material;
import 'package:go_router/go_router.dart';
import 'package:lazyext/app/document_source.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:mupdf_android/mupdf_android.dart' as mupdf;
import 'package:provider/provider.dart';

class DocumentsScreen extends StatefulWidget {
  final DocumentEntity entity;
  const DocumentsScreen({super.key, required this.entity});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
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
        return FutureBuilder<List<Document>>(
            future: provider.documents.toList(),
            builder: (context, snapshot) {
              List<Document>? documents = snapshot.data;
              return Visibility(
                  visible: documents?.isNotEmpty ?? false,
                  child: FloatingActionButton.extended(
                    label: const Text("Open"),
                    icon: const Icon(Icons.file_open),
                    onPressed: () async {
                      if (documents != null) {
                        setState(() => loading = true);
                        List<Future<mupdf.PDFDocument?>> jobs = documents.fold(
                            [],
                            (previousValue, element) =>
                                previousValue + [element.document]);
                        await context.push("/compare",
                            extra: (await jobs.wait).nonNulls);
                        setState(() => loading = false);
                      }
                    },
                  ));
            });
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: DocumentEntityListView(entity: widget.entity),
    );
  }
}

class DocumentEntityListItem extends StatefulWidget {
  final DocumentEntity entity;
  const DocumentEntityListItem({super.key, required this.entity});

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
        return Checkbox(
            tristate: true,
            value: provider.isSelected(widget.entity),
            onChanged: (bool? value) async {
              provider.updateSelection(widget.entity, value ?? false);
            });
      }),
      onTap: widget.entity is! Document
          ? () async {
              context.push("/sources", extra: widget.entity);
            }
          : null,
    );
  }
}

class DocumentEntityListView<T> extends StatefulWidget {
  final DocumentEntity entity;
  const DocumentEntityListView({super.key, required this.entity});

  @override
  State<DocumentEntityListView> createState() =>
      _DocumentEntityListViewState<T>();
}

class _DocumentEntityListViewState<T> extends State<DocumentEntityListView> {
  final DocumentSelectionProvider selections = DocumentSelectionProvider();
  final List<DocumentEntity> entities = [];

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
        return DocumentEntityListItem(entity: entities[index]);
      },
    );
  }
}

typedef DocumentSelectionMapEntry = (bool, List<DocumentEntity>);

typedef DocumentSelectionMap = Map<DocumentEntity, DocumentSelectionMapEntry>;

class DocumentSelectionProvider extends ChangeNotifier {
  final DocumentSelectionMap _entries = {};

  Stream<Document> get documents async* {
    Stream<Document> yieldUp(List<DocumentEntity> current) async* {
      for (DocumentEntity entity in current) {
        if (entity is Document) yield entity;
        await for (Document document
            in yieldUp(await entity.entities.toList())) {
          yield document;
        }
      }
    }

    for (MapEntry<DocumentEntity, DocumentSelectionMapEntry> entry
        in _entries.entries) {
      DocumentEntity key = entry.key;
      if (key is Document) yield key;
      await for (Document document in yieldUp(entry.value.$2)) {
        yield document;
      }
    }
  }

  bool? isSelected(DocumentEntity entity) {
    if (_entries.keys.contains(entity)) {
      DocumentSelectionMapEntry entry = _entries[entity]!;
      return entry.$1 ? (entry.$2.isEmpty ? true : null) : true;
    } else {
      for (MapEntry<DocumentEntity, DocumentSelectionMapEntry> entry
          in _entries.entries) {
        if (entry.value.$2.contains(entity)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _addToParent(DocumentEntity entity) {
    for (MapEntry<DocumentEntity, DocumentSelectionMapEntry> entry
        in _entries.entries) {
      if (entry.key == entity.parent) {
        _entries[entry.key]!.$2.add(entity);
        return true;
      }
    }
    return false;
  }

  void _freeEntity(DocumentEntity entity) {
    for (MapEntry<DocumentEntity, DocumentSelectionMapEntry> entry
        in _entries.entries) {
      if (entry.key == entity.parent) {
        _entries[entry.key]!.$2.remove(entity);
      }
    }
  }

  void updateSelection(DocumentEntity entity, bool value) {
    DocumentEntity? parent = entity.parent;
    if (parent != null) _freeEntity(parent);
    if (!_addToParent(entity)) {
      _entries[entity] = (value, []);
    }
    notifyListeners();
  }
}
