import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

typedef GoogleGetPage<T, R> = Future<(List<R>, T?)> Function(int, T?);

class GPaginatedListView<T, R> extends StatefulWidget {
  final GoogleGetPage<T, R> getPage;
  final ItemWidgetBuilder<R> itemBuilder;
  final int pageSize;
  final int Function(R, R)? comparator;
  final bool shouldSort;

  const GPaginatedListView(
      {super.key,
      required this.getPage,
      required this.itemBuilder,
      this.comparator,
      this.shouldSort = false,
      this.pageSize = 20});

  @override
  State<GPaginatedListView> createState() => _GPaginatedListViewState<T, R>();
}

class _GPaginatedListViewState<T, R> extends State<GPaginatedListView<T, R>> {
  final PagingController<T?, R> _pagingController =
      PagingController(firstPageKey: null, invisibleItemsThreshold: 25);

  Future<void> _handlePageRequest(T? token) async {
    (List<R>, T?) page = await widget.getPage(widget.pageSize, token);
    try {
      _pagingController.appendPage(page.$1, page.$2);
    } on Exception {
      // Could be scheduled after dispose, which causes a crash.
      return;
    } on FlutterError {
      // Could be scheduled after dispose, which causes a crash.
      return;
    }
    if (widget.shouldSort) {
      _pagingController.itemList?.sort(widget.comparator);
    }
  }

  @override
  void initState() {
    _pagingController.addPageRequestListener((token) {
      _handlePageRequest(token);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<T?, R>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<R>(
          itemBuilder: widget.itemBuilder,
        ));
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
