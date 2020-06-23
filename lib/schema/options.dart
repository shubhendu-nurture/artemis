import 'package:artemis/generator/data/class_property.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';

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
    } else if (json is YamlMap) {
      return _$DartTypeFromJson({
        'name': json['name'],
        'imports': (json['imports'] as YamlList).map((s) => s).toList(),
      });
    } else {
      throw 'Invalid YAML: $json';
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

/// The naming scheme to be used on generated classes names.
enum NamingScheme {
  /// Default, where the names of previous types are used as prefix of the
  /// next class. This can generate duplication on certain schemas.
  pathedWithTypes,

  /// The names of previous fields are used as prefix of the next class.
  pathedWithFields,

  /// Considers only the actual GraphQL class name. This will probably lead to
  /// duplication and an Artemis error unless user uses aliases.
  simple,
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

  /// A metadata file this schema mapping to be used.
  final String metadataFile;

  /// A entity file containing the entity definition.
  final String entityOutput;

  /// The resolve type field used on this schema.
  @JsonKey(defaultValue: '__typename')
  final String typeNameField;

  /// The naming scheme to be used.
  ///
  /// - [NamingScheme.pathedWithTypes]: default, where the names of
  /// previous classes are used to generate the prefix.
  /// - [NamingScheme.pathedWithFields]: the field names are joined
  /// together to generate the path.
  /// - [NamingScheme.simple]: considers only the actual GraphQL class name.
  /// This will probably lead to duplication and an Artemis error unless you
  /// use aliases.
  @JsonKey(unknownEnumValue: NamingScheme.pathedWithTypes)
  final NamingScheme namingScheme;

  /// Instantiates a schema mapping.
  SchemaMap({
    this.output,
    this.schema,
    this.queriesGlob,
    this.metadataFile,
    this.entityOutput,
    this.typeNameField = '__typename',
    this.namingScheme = NamingScheme.pathedWithTypes,
  });

  /// Build a schema mapping from a JSON map.
  factory SchemaMap.fromJson(Map<String, dynamic> json) =>
      _$SchemaMapFromJson(json);

  /// Convert this schema mapping instance to JSON.
  Map<String, dynamic> toJson() => _$SchemaMapToJson(this);
}

/// Metadata info detail for mapping response to db entities.
@JsonSerializable(explicitToJson: true)
class DbMetadataInfo {
  /// Table name to use for the response object storage.
  final String tableName;

  /// Result object access property path for fetching rows of database.
  final Map<String, String> rowAccessor;

  /// Primary key field name for the table.
  final String primaryKeyField;

  /// Index field columns for the table.
  final List<String> indexFields;

  /// Info about the detail column for the table.
  final DbDetailFieldInfo detailField;

  /// All fields for this schema map
  Map<String, String> allFields;

  /// Instantiates a DbMetadataInfo.
  DbMetadataInfo(
      {this.tableName,
      this.rowAccessor,
      this.primaryKeyField,
      this.indexFields,
      this.detailField});

  /// Build a metadata info from a JSON map.
  factory DbMetadataInfo.fromJson(Map<String, dynamic> json) =>
      _$DbMetadataInfoFromJson(json);

  /// Convert this meta data instance to JSON.
  Map<String, dynamic> toJson() => _$DbMetadataInfoToJson(this);
}

/// Db field info for table used for storage of response objects.
@JsonSerializable(explicitToJson: true)
class DbDetailFieldInfo {
  /// Field name to be used in the generated entity object for detail object.
  final String fieldName;

  /// Class name to use for mapping detail column from table.
  final String className;

  /// The top level response fields to be moved to the detail column.
  final List<String> detailKeys;

  /// Instantiates a DbFieldInfo.
  DbDetailFieldInfo({this.fieldName, this.className, this.detailKeys});

  /// Build a db field info from a JSON map.
  factory DbDetailFieldInfo.fromJson(Map<String, dynamic> json) =>
      _$DbDetailFieldInfoFromJson(json);

  /// Convert this db field info instance to JSON.
  Map<String, dynamic> toJson() => _$DbDetailFieldInfoToJson(this);
}
