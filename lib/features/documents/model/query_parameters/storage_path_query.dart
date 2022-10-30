import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/id_query_parameter.dart';

class StoragePathQuery extends IdQueryParameter {
  const StoragePathQuery.fromId(super.id) : super.fromId();
  const StoragePathQuery.unset() : super.unset();
  const StoragePathQuery.notAssigned() : super.notAssigned();

  @override
  String get queryParameterKey => 'storage_path';
}
