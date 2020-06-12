import 'package:json_annotation/json_annotation.dart';

// I can't use the default json_serializable flow because the artemis generator
// would crash when importing options.dart file.
part 'options.g2.dart';

/// This generator options, gathered from `build.yaml` file.
@JsonSerializable(fieldRename: FieldRename.snake, anyMap: true)
class GeneratorOptions {
  /// If instances of [GraphQLQuery] should be generated.
  @JsonKey(defaultValue: true)
  final bool generateHelpers;

  /// A list of scalar mappings.
  @JsonKey(defaultValue: [])
  final List<ScalarMap> scalarMapping;

  /// A list of fragments apply for all query files without declare them.
  final String fragmentsGlob;

  /// A list of schema mappings.
  @JsonKey(defaultValue: [])
  final List<SchemaMap> schemaMapping;

  /// Instantiate generator options.
  GeneratorOptions({
    this.generateHelpers = true,
    this.scalarMapping = const [],
    this.fragmentsGlob,
    this.schemaMapping = const [],
  });

  /// Build options from a JSON map.
  factory GeneratorOptions.fromJson(Map<String, dynamic> json) =>
      _$GeneratorOptionsFromJson(json);

  /// Convert this options instance to JSON.
  Map<String, dynamic> toJson() => _$GeneratorOptionsToJson(this);
}

/// Define a Dart type.
@JsonSerializable()
class DartType {
  /// Dart type name.
  final String name;

  /// Package imports related to this type.
  @JsonKey(defaultValue: <String>[])
  final List<String> imports;

  /// Instantiate a Dart type.
  const DartType({
    this.name,
    this.imports = const [],
  });

  /// Build a Dart type from a JSON string or map.
  factory DartType.fromJson(dynamic json) {
    if (json is String) {
      return DartType(name: json);
    } else if (json is Map<String, dynamic>) {
      return _$DartTypeFromJson(json);
    } else {
      throw 'Invalid json: $json';
    }
  }

  /// Convert this Dart type instance to JSON.
  Map<String, dynamic> toJson() => _$DartTypeToJson(this);
}

/// Maps a GraphQL scalar to a Dart type.
@JsonSerializable(fieldRename: FieldRename.snake)
class ScalarMap {
  /// The GraphQL type name.
  @JsonKey(name: 'graphql_type')
  final String graphQLType;

  /// The Dart type linked to this GraphQL type.
  final DartType dartType;

  /// If custom parser would be used.
  final String customParserImport;

  /// Instatiates a scalar mapping.
  ScalarMap({
    this.graphQLType,
    this.dartType,
    this.customParserImport,
  });

  /// Build a scalar mapping from a JSON map.
  factory ScalarMap.fromJson(Map<String, dynamic> json) =>
      _$ScalarMapFromJson(json);

  /// Convert this scalar mapping instance to JSON.
  Map<String, dynamic> toJson() => _$ScalarMapToJson(this);
}

/// Maps a GraphQL schema to queries files.
@JsonSerializable(fieldRename: FieldRename.snake)
class SchemaMap {
  /// The output file of this queries glob.
  final String output;

  /// The GraphQL schema string.
  final String schema;

  /// A [Glob] to find queries files.
  final String queriesGlob;

  /// The resolve type field used on this schema.
  @JsonKey(defaultValue: '__typename')
  final String typeNameField;

  /// Instantiates a schema mapping.
  SchemaMap({
    this.output,
    this.schema,
    this.queriesGlob,
    this.typeNameField = '__typename',
  });

  /// Build a schema mapping from a JSON map.
  factory SchemaMap.fromJson(Map<String, dynamic> json) =>
      _$SchemaMapFromJson(json);

  /// Convert this schema mapping instance to JSON.
  Map<String, dynamic> toJson() => _$SchemaMapToJson(this);
}

/// Info for mapping a GraphQL queries to db objects
@JsonSerializable(fieldRename: FieldRename.snake)
class DBInfo {
  /// The table name to store the current query data.
  final String tableName;

  /// Instantiates DBInfo.
  DBInfo({
    this.tableName,
  });

  /// Build a DBInfo from a JSON map.
  factory DBInfo.fromJson(Map<String, dynamic> json) => _$DBInfoFromJson(json);

  /// Convert this DBInfo instance to JSON.
  Map<String, dynamic> toJson() => _$DBInfoToJson(this);
}
