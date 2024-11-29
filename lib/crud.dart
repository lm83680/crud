library crud;

import 'package:crud/utils.dart';
import 'package:flutter/material.dart';

/// 使用方式 ：
/// 1. 全局覆盖 PaginatedRequest 配置
/// 2. 全局覆盖 PaginatedDialog 配置
/// 3. 全局覆盖 RGetMoreResult 配置
/// 4. 使用 e.g:
///  ```
///  late Crud useCrud = Crud(
///      options: CrudOptions(
///          dataListUrl: '/app/page',
///          commonUrl: '/app',
///          params: {"bizType": 0, "bizId": "5333"}
///      ),
///      onChange: () => setState((){}));
/// ```
class Crud {
  final CrudOptions _metaOptions;

  ///列表变化后触发
  final void Function() onChange;

  dynamic cursor;

  List<dynamic> _list = [];

  int currentPage;

  int limit;

  int total = 0;

  /// 查询条件
  Map<String, dynamic>? params;

  ///当前列表数据
  List<dynamic> get list => _list;

  Crud({required CrudOptions options, required Function() this.onChange})
      : _metaOptions = options,
        params = options.params,
        currentPage = options.page,
        limit = options.limit {
    if (_metaOptions.createdIsNeed) onRefresh();
  }

  ///重头刷新
  Future<bool> onRefresh() async {
    final int lastKey = currentPage; //如果调用失败将回溯
    try {
      currentPage = 1;
      String onRefreshUrl = setUrlParams(_metaOptions.getListUrl,
          {"page": "$currentPage", "limit": "$limit", ...?params});
      RGetModel getResult = await PaginatedRequest.get(onRefreshUrl);
      _list = getResult.list;
      total = getResult.total;
      cursor = getResult.cursor;
      onChange();
      return true;
    } catch (e) {
      currentPage = lastKey;
      debugPrint(e.toString());
      return false;
    }
  }

  ///加载更多
  Future<RGetMoreResult> onLoad() async {
    if (_list.length >= total) {
      return RGetMoreResult.noMore;
    }
    final int lastKey = currentPage; //如果调用失败将回溯
    currentPage += 1;
    try {
      String onLoadUrl = setUrlParams(_metaOptions.getListUrl,
          {"page": "$currentPage", "limit": "$limit", ...?params});
      RGetModel getResult = await PaginatedRequest.get(onLoadUrl);
      _list.addAll(getResult.list);
      total = getResult.total;
      cursor = getResult.cursor;
      onChange();
      if (_list.length >= total) {
        return RGetMoreResult.noMore;
      } else {
        return RGetMoreResult.ok;
      }
    } catch (e) {
      currentPage = lastKey;
      debugPrint(e.toString());
      return RGetMoreResult.error;
    }
  }

  /// 批量删除  删除完成后会从列表中删除根据_options.primaryKey查找对应的项目,如果未覆盖Dialog，务必传入 BuildContext context,
  Future<bool> deleteBatchHandle({
    BuildContext? context,
    required List<String> keys,
  }) async {
    if (await PaginatedDialog.showDeleteDialog(context)) {
      List<String> delectKeys = keys;
      RDeleteModel value = await PaginatedRequest.deleteBatch(
          _metaOptions.commonUrl!,
          keys: delectKeys);
      if (value.isSuccessed) {
        PaginatedDialog.showSuccess();
        _deleteItemForList(delectKeys);
        return true;
      } else {
        PaginatedDialog.showError();
        return false;
      }
    }
    return false;
  }

  /// 新增 - 要求后端返回 VO实体，否则 会将data作为VO实体填入
  ///
  /// 该函数保持list的长度，能保留滑动视图的位置不变。
  ///
  /// insertPosition 插入位置，为空默认最后一个 ，0 = 最前一个
  Future<void> postHandle(Map data, {int? insertPosition}) async {
    try {
      RPostModel value =
          await PaginatedRequest.post(_metaOptions.commonUrl!, data);
      insertPosition != null
          ? _list.insert(insertPosition, value.data ?? data)
          : _list.add(value.data ?? data);
      PaginatedDialog.showSuccess();
      onChange();
    } catch (e) {
      PaginatedDialog.showError();
    }
  }

  /// 修改 - 要求后端返回 VO实体，否则 会将data作为VO实体填入
  ///
  /// 该函数保持list的长度，能保留滑动视图的位置不变。
  Future<void> putHandle(Map data) async {
    final index = _list.indexWhere((element) =>
        element[_metaOptions.primaryKey] == data[_metaOptions.primaryKey]);
    assert(index != -1, "不存在该元素，请检查_options.primaryKey");
    try {
      RPutModel value = await PaginatedRequest.put(_metaOptions.commonUrl!, data);
      _list[index] = value.data ?? data;
      PaginatedDialog.showSuccess();
      onChange();
    } catch (e) {
      PaginatedDialog.showError();
    }
  }

  ///修改 params 的内容
  ///
  ///```params = {...?params, ...?map};```
  setParams(Map<String, dynamic>? map) {
    params = {...?params, ...?map};
    onRefresh();
  }

  ///清空params
  cleanParams() {
    if (params != null && params!.isNotEmpty) {
      params = params!.map((key, value) => MapEntry(key, null));
    }
    onRefresh();
  }

  ///根据键值将列表中的数据删除
  ///
  ///这个函数会触发onChange
  _deleteItemForList(List<String> keys) {
    _list.removeWhere(
        (map) => keys.contains(map[_metaOptions.primaryKey].toString()));
    onChange();
  }
}

class CrudOptions {
  /// 查询数据列表Url
  final String getListUrl;

  /// RESTful风格 增删改
  final String? commonUrl;

  /// 是否在创建类时，调用数据列表接口
  bool createdIsNeed;

  /// 主键key，一般都是'id',不用改
  String primaryKey;

  /// 查询条件
  Map<String, dynamic>? params;

  /// 当前页码
  int page;

  /// 每页数
  int limit;

  /// 游标的queryKey，向服务端发送cursor时以此字段作为字段名
  String cursorKey;

  CrudOptions({
    required this.getListUrl,
    this.createdIsNeed = true,
    this.commonUrl,
    this.primaryKey = 'id',
    this.cursorKey = 'cursor',
    this.params,
    this.page = 1,
    this.limit = 20,
  });
}

///使用PaginatedCrud前需要补全具体函数的实现方法。根据后台的业务实现处理后返回指定的内容
///
///支持游标分页
class PaginatedRequest {
  ///参数已拼接到url
  ///
  ///如果使用游标，需要将游标字段传输给 cursor ，后续返回给后端服务时则使用 PaginatedCrudOptions.curssorKey 指定
  static late Future<RGetModel> Function(String url) get;

  ///接收任何的data，返回新的实体，会根据输入函数指定它插入的位置;
  static late Future<RPostModel> Function(
      String url, Map<dynamic, dynamic> data) post;

  ///接收任何的data，返回新的实体，他会替换对应的旧实体;
  static late Future<RPutModel> Function(String url, Map<dynamic, dynamic> data)
      put;

  ///接收传入keys，删除完成后从列表中移除这些实体
  static late Future<RDeleteModel> Function(String url, {List<String>? keys})
      deleteBatch;
}

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

/// 覆盖返回值以实现加载更多后返回指定类型的结果 对应ok, error, noMore
class RGetMoreResult {
  static late dynamic ok;
  static late dynamic error;
  static late dynamic noMore;
}

/// 预设反馈框，你可以将其覆盖。
class PaginatedDialog {
  ///询问是否删除
  static Future<bool> Function([BuildContext? context]) showDeleteDialog =
      ([BuildContext? context]) => Future.value(true);

  ///成功提示
  static void Function([BuildContext? context]) showSuccess =
      ([BuildContext? context]) {};

  ///成功失败
  static void Function([BuildContext? context]) showError =
      ([BuildContext? context]) {};
}
