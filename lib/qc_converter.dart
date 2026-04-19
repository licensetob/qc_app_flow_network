import 'dart:convert';

/// 数据转换器接口
abstract class QcConverter<T> {
  T convert(dynamic data);
}

/// 默认JSON转Map转换器
class QcJsonToMapConverter extends QcConverter<Map<String, dynamic>> {
  @override
  Map<String, dynamic> convert(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(data));
      } catch (e) {
        throw FormatException('无法将字符串转换为Map: $e');
      }
    } else {
      throw TypeError();
    }
  }
}

/// 默认JSON转List转换器
class QcJsonToListConverter<T> extends QcConverter<List<T>> {
  final QcConverter<T> itemConverter;
  
  QcJsonToListConverter(this.itemConverter);
  
  @override
  List<T> convert(dynamic data) {
    if (data is List) {
      return data.map((item) => itemConverter.convert(item)).toList();
    } else if (data is String) {
      try {
        final listData = jsonDecode(data) as List;
        return listData.map((item) => itemConverter.convert(item)).toList();
      } catch (e) {
        throw FormatException('无法将字符串转换为List: $e');
      }
    } else {
      throw TypeError();
    }
  }
}

 