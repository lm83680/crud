import 'package:flutter/material.dart';

class CrudInitializer {
  static CrudConfig? _config;

  static void register(CrudConfig config) {
    _config = config;
  }

  static CrudConfig get curdConfigure {
    assert(_config != null, "Curd 没有初始化，调用register()完成配置");
    return _config!;
  }
}

///统一配置入口
class CrudConfig {
  ///参数已拼接到url
  ///
  ///如果使用游标，需要将游标字段传输给 cursor ，后续返回给后端服务时则使用 PaginatedCrudOptions.curssorKey 指定
  final Future<RGetModel> Function(String url) get;

  ///接收任何的data，返回新的实体，会根据输入函数指定它插入的位置;
  final Future<RPostModel> Function(String url, Map<dynamic, dynamic> data)
      post;

  ///接收任何的data，返回新的实体，他会替换对应的旧实体
  final Future<RPutModel> Function(String url, Map<dynamic, dynamic> data) put;

  ///接收传入keys，删除完成后从列表中移除这些实体
  final Future<RDeleteModel> Function(String url, List<String> keys)
      deleteBatch;

  /// 覆盖返回值以实现加载更多后返回指定类型的结果 对应ok, error, noMore
  final dynamic getOk;
  final dynamic getError;
  final dynamic getNoMore;

  /// 预设反馈框，你可以将其覆盖。
  final Future<bool> Function([BuildContext? context, dynamic])
      showDeleteDialog;
  final void Function([BuildContext? context]) showSuccess;
  final void Function([BuildContext? context]) showError;

  CrudConfig({
    required this.get,
    required this.post,
    required this.put,
    required this.deleteBatch,
    this.getOk = RGetMoreResult.ok,
    this.getError = RGetMoreResult.error,
    this.getNoMore = RGetMoreResult.noMore,
    Future<bool> Function([BuildContext? context, dynamic])? showDeleteDialog,
    void Function([BuildContext? context])? showSuccess,
    void Function([BuildContext? context])? showError,
  })  : showDeleteDialog = (showDeleteDialog ??
            ([BuildContext? context, dynamic]) => Future.value(true)),
        showSuccess = (showSuccess ?? ([BuildContext? context]) {}),
        showError = (showError ?? ([BuildContext? context]) {});
}

// ===========
class RGetModel {
  int total;
  List list;
  dynamic cursor; //游标
  RGetModel({required this.total, required this.list, this.cursor});
}

class RPostModel {
  Map? data;
  RPostModel({required this.data});
}

class RPutModel {
  Map? data;
  RPutModel({required this.data});
}

class RDeleteModel {
  bool isSuccessed;
  RDeleteModel({required this.isSuccessed});
}

/// 默认的GetMore返回值
enum RGetMoreResult {
  ok,
  error,
  noMore;
}
