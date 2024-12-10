library crud;

import 'package:flutter/material.dart';
import 'package:flutter_crud/config.dart';
import 'package:flutter_crud/utils.dart';

/// 无限下拉
/// 使用方式 ：
/// 1. 调用CrudInitializer.register() 完成配置
/// 2. 使用:
///  ```
///  late Crud useCrud = CrudInfinitely(
///      options: CrudOptions(
///          dataListUrl: '/app/page',
///          params: {"bizType": 0, "bizId": "5333"}
///      ),
///      onChange: () => setState((){}));
/// ```
class CrudInfinitely {
  final CrudOptions _metaOptions;

  ///列表变化后触发
  final void Function() onChange;

  dynamic cursor;

  List<dynamic> list = [];

  int currentPage;

  int total = 0;

  /// 查询条件
  Map<String, dynamic>? params;

  final int limit;

  CrudConfig get config => CrudInitializer.curdConfigure;

  CrudInfinitely(
      {required CrudOptions options, required Function() this.onChange})
      : _metaOptions = options,
        params = options.params,
        currentPage = options.page,
        limit = options.limit {
    if (_metaOptions.createdIsNeed) onRefresh();
  }

  ///重头刷新
  Future<bool> onRefresh() async {
    try {
      String onRefreshUrl = setUrlParams(
          _metaOptions.getListUrl, {"page": 1, "limit": "$limit", ...?params});
      RGetModel getResult = await config.get(onRefreshUrl);
      currentPage = 1;
      list = getResult.list;
      total = getResult.total;
      cursor = getResult.cursor;
      onChange();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  ///加载更多
  Future<T> onLoad<T>() async {
    if (list.length >= total) {
      return config.getNoMore;
    }
    try {
      String onLoadUrl = setUrlParams(_metaOptions.getListUrl,
          {"page": "${currentPage + 1}", "limit": "$limit", ...?params});
      RGetModel getResult = await config.get(onLoadUrl);
      list.addAll(getResult.list);
      currentPage += 1;
      total = getResult.total;
      cursor = getResult.cursor;
      onChange();
      if (list.length >= total) {
        return config.getNoMore;
      } else {
        return config.getOk;
      }
    } catch (e) {
      debugPrint(e.toString());
      return config.getError;
    }
  }

  /// 批量删除  删除完成后会从列表中删除根据_options.primaryKey查找对应的项目,如果未覆盖Dialog，务必传入 BuildContext context,
  Future<bool> deleteBatchHandle({
    BuildContext? context,
    required List<String> keys,
  }) async {
    if (await config.showDeleteDialog(context)) {
      RDeleteModel value =
          await config.deleteBatch(_metaOptions.commonUrl, keys);
      if (value.isSuccessed) {
        config.showSuccess();
        _deleteItemForList(keys);
        return true;
      } else {
        config.showError();
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
      RPostModel value = await config.post(_metaOptions.commonUrl, data);
      insertPosition != null
          ? list.insert(insertPosition, value.data ?? data)
          : list.add(value.data ?? data);
      config.showSuccess();
      onChange();
    } catch (e) {
      config.showError();
    }
  }

  /// 修改 - 要求后端返回 VO实体，否则 会将data作为VO实体填入
  ///
  /// 该函数保持list的长度，能保留滑动视图的位置不变。
  Future<void> putHandle(Map data) async {
    final index = list.indexWhere((element) =>
        element[_metaOptions.primaryKey] == data[_metaOptions.primaryKey]);
    assert(index != -1, "不存在该元素，请检查_options.primaryKey");
    try {
      RPutModel value = await config.put(_metaOptions.commonUrl, data);
      list[index] = value.data ?? data;
      config.showSuccess();
      onChange();
    } catch (e) {
      config.showError();
    }
  }

  ///修改 params 的内容
  ///
  ///```params = {...?params, ...?newParams};```
  setParams(Map<String, dynamic>? newParams) {
    params = {...?params, ...?newParams};
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
    list.removeWhere(
        (map) => keys.contains(map[_metaOptions.primaryKey].toString()));
    onChange();
  }
}

/// 分页式
/// 使用方式 ：
/// 1. 调用CrudInitializer.register() 完成配置
/// 2. 使用:
///  ```
///  late Crud useCrud = CrudPages(
///      options: CrudOptions(
///          dataListUrl: '/app/page',
///          params: {"bizType": 0, "bizId": "5333"}
///      ),
///      onChange: () => setState((){}));
/// ```
class CrudPages {
  final CrudOptions _metaOptions;

  ///列表变化后触发
  final void Function() onChange;

  List<dynamic> list = [];

  int currentPage;

  int total = 0;

  /// 查询条件
  Map<String, dynamic>? params;

  final int limit;

  CrudConfig get config => CrudInitializer.curdConfigure;

  CrudPages({required CrudOptions options, required Function() this.onChange})
      : _metaOptions = options,
        params = options.params,
        currentPage = options.page,
        limit = options.limit {
    if (_metaOptions.createdIsNeed) getForIndex(1);
  }

  ///获取某一页
  Future<bool> getForIndex(int page) async {
    try {
      String onRefreshUrl = setUrlParams(_metaOptions.getListUrl,
          {"page": page, "limit": "$limit", ...?params});
      RGetModel getResult = await config.get(onRefreshUrl);
      currentPage = page;
      list = getResult.list;
      total = getResult.total;
      onChange();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  ///下一页
  Future<bool> next() async {
    return getForIndex(currentPage + 1);
  }

  ///上一页
  Future<bool> last() async {
    return getForIndex(currentPage - 1);
  }

  /// 批量删除  删除完成后会从刷新当前页,如果未覆盖Dialog，务必传入 BuildContext context,
  Future<bool> deleteBatchHandle({
    BuildContext? context,
    required List<String> keys,
  }) async {
    if (await config.showDeleteDialog(context)) {
      RDeleteModel value = await config.deleteBatch(_metaOptions.commonUrl, keys);
      if (value.isSuccessed) {
        config.showSuccess();
        getForIndex(currentPage);
        return true;
      } else {
        config.showError();
        return false;
      }
    }
    return false;
  }

  /// 新增
  /// toFirst 是否将数据转回第一页
  Future<void> postHandle(Map data, {bool? toFirst}) async {
    try {
      await config.post(_metaOptions.commonUrl, data);
      if (toFirst == true || currentPage == 1) {
        await getForIndex(1);
      }
      config.showSuccess();
      onChange();
    } catch (e) {
      config.showError();
    }
  }

  /// 修改 - 要求后端返回 VO实体，否则 会将data作为VO实体填入
  ///
  /// 该函数保持list的长度，能保留滑动视图的位置不变。
  Future<void> putHandle(Map data) async {
    final index = list.indexWhere((element) => element[_metaOptions.primaryKey] == data[_metaOptions.primaryKey]);
    assert(index != -1, "不存在该元素，请检查_options.primaryKey");
    try {
      RPutModel value = await config.put(_metaOptions.commonUrl, data);
      list[index] = value.data ?? data;
      config.showSuccess();
      onChange();
    } catch (e) {
      config.showError();
    }
  }

  ///修改 params 的内容
  ///
  ///```params = {...?params, ...?newParams};```
  setParams(Map<String, dynamic>? newParams) {
    params = {...?params, ...?newParams};
    getForIndex(currentPage);
  }

  ///清空params
  cleanParams() {
    if (params != null && params!.isNotEmpty) {
      params = params!.map((key, value) => MapEntry(key, null));
    }
    getForIndex(currentPage);
  }
}

class CrudOptions {
  /// 查询数据列表Url
  final String getListUrl;

  /// restful风格 增删改
  final String commonUrl;

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
    String? commonUrl,
    this.primaryKey = 'id',
    this.cursorKey = 'cursor',
    this.params,
    this.page = 1,
    this.limit = 20,
  }) : commonUrl = (commonUrl ?? getLastSegment(getListUrl));
}
