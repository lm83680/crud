///给一个url追加参数
String setUrlParams(String baseUrl, Map<String, dynamic> params) {
  if (params.isEmpty) return baseUrl;

  final buffer = StringBuffer(baseUrl);
  if (!baseUrl.contains("?")) {
    buffer.write("?");
  } else if (!baseUrl.endsWith("&") && !baseUrl.endsWith("?")) {
    buffer.write("&");
  }

  params.forEach((key, value) {
    if (value is List) {
      buffer.write( "${Uri.encodeComponent(key)}=${value.map((v) => Uri.encodeComponent(v.toString())).join(',')}&");
    } else {
      buffer.write("${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}&");
    }
  });

  String urlWithParams = buffer.toString();
  // 移除最后一个多余的"&"
  if (urlWithParams.endsWith("&")) {
    urlWithParams = urlWithParams.substring(0, urlWithParams.length - 1);
  }

  return urlWithParams;
}