// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorOptions _$GeneratorOptionsFromJson(Map json) {
  return GeneratorOptions(
    generateHelpers: json['generate_helpers'] as bool ?? true,
    scalarMapping: (json['scalar_mapping'] as List)
            ?.map((e) => e == null
                ? null
                : ScalarMap.fromJson((e as Map)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )))
            ?.toList() ??
        [],
    fragmentsGlob: json['fragments_glob'] as String,
    schemaMapping: (json['schema_mapping'] as List)
            ?.map((e) => e == null
                ? null
                : SchemaMap.fromJson((e as Map)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )))
            ?.toList() ??
        [],
  );
}

Map<String, dynamic> _$GeneratorOptionsToJson(GeneratorOptions instance) =>
    <String, dynamic>{
      'generate_helpers': instance.generateHelpers,
      'scalar_mapping': instance.scalarMapping,
      'fragments_glob': instance.fragmentsGlob,
      'schema_mapping': instance.schemaMapping,
    };

DartType _$DartTypeFromJson(Map<String, dynamic> json) {
  return DartType(
    name: json['name'] as String,
    imports: (json['imports'] as List)?.map((e) => e as String)?.toList() ?? [],
  );
}

Map<String, dynamic> _$DartTypeToJson(DartType instance) => <String, dynamic>{
      'name': instance.name,
      'imports': instance.imports,
    };

ScalarMap _$ScalarMapFromJson(Map<String, dynamic> json) {
  return ScalarMap(
    graphQLType: json['graphql_type'] as String,
    dartType:
        json['dart_type'] == null ? null : DartType.fromJson(json['dart_type']),
    customParserImport: json['custom_parser_import'] as String,
  );
}

Map<String, dynamic> _$ScalarMapToJson(ScalarMap instance) => <String, dynamic>{
      'graphql_type': instance.graphQLType,
      'dart_type': instance.dartType,
      'custom_parser_import': instance.customParserImport,
    };

SchemaMap _$SchemaMapFromJson(Map<String, dynamic> json) {
  return SchemaMap(
    output: json['output'] as String,
    schema: json['schema'] as String,
    queriesGlob: json['queries_glob'] as String,
    metadataFile: json['metadata_file'] as String,
    entityOutput: json['entity_output'] as String,
    typeNameField: json['type_name_field'] as String ?? '__typename',
    namingScheme: _$enumDecodeNullable(
        _$NamingSchemeEnumMap, json['naming_scheme'],
        unknownValue: NamingScheme.pathedWithTypes),
  );
}

Map<String, dynamic> _$SchemaMapToJson(SchemaMap instance) => <String, dynamic>{
      'output': instance.output,
      'schema': instance.schema,
      'queries_glob': instance.queriesGlob,
      'metadata_file': instance.metadataFile,
      'entity_output': instance.entityOutput,
      'type_name_field': instance.typeNameField,
      'naming_scheme': _$NamingSchemeEnumMap[instance.namingScheme],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$NamingSchemeEnumMap = {
  NamingScheme.pathedWithTypes: 'pathedWithTypes',
  NamingScheme.pathedWithFields: 'pathedWithFields',
  NamingScheme.simple: 'simple',
};

DbMetadataInfo _$DbMetadataInfoFromJson(Map<String, dynamic> json) {
  return DbMetadataInfo(
    tableName: json['tableName'] as String,
    rowAccessor: (json['rowAccessor'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    primaryKeyField: json['primaryKeyField'] as String,
    indexFields:
        (json['indexFields'] as List)?.map((e) => e as String)?.toList(),
    detailField: json['detailField'] == null
        ? null
        : DbDetailFieldInfo.fromJson(
            json['detailField'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$DbMetadataInfoToJson(DbMetadataInfo instance) =>
    <String, dynamic>{
      'tableName': instance.tableName,
      'rowAccessor': instance.rowAccessor,
      'primaryKeyField': instance.primaryKeyField,
      'indexFields': instance.indexFields?.map((e) => e)?.toList(),
      'detailField': instance.detailField?.toJson(),
    };

DbDetailFieldInfo _$DbDetailFieldInfoFromJson(Map<String, dynamic> json) {
  return DbDetailFieldInfo(
    fieldName: json['fieldName'] as String,
    className: json['className'] as String,
    detailKeys: (json['detailKeys'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$DbDetailFieldInfoToJson(DbDetailFieldInfo instance) =>
    <String, dynamic>{
      'fieldName': instance.fieldName,
      'className': instance.className,
      'detailKeys': instance.detailKeys,
    };
