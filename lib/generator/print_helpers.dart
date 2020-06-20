import 'package:artemis/generator/data/data.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gql_code_gen/gql_code_gen.dart' as dart;

import '../generator/helpers.dart';

/// Generates a [Spec] of a single enum definition.
Spec enumDefinitionToSpec(EnumDefinition definition) =>
    CodeExpression(Code('''enum ${definition.name.namePrintable} {
  ${definition.values.removeDuplicatedBy((i) => i).map((v) => '@JsonValue("${v.name}")${v.namePrintable}, ').join()}
}'''));

/// Generate a [Spec] from single enum extension which will include two values.
Spec enumDefinitionExtensionToSpec(EnumDefinition definition) {
  final enumName = definition.name.namePrintable;
  final buffer = StringBuffer()
    ..writeln('extension ${enumName}Ext on ${enumName} {')
    ..writeln('  String toValue() {')
    ..writeln('    return _\$${enumName}EnumMap[this];')
    ..writeln('  }\n')
    ..writeln('  ${enumName} fromValue(String name) {')
    ..writeln('    return ${enumName}.artemisUnknown;')
    ..writeln('  }')
    ..writeln('}');
  return CodeExpression(Code(buffer.toString()));
}

String _fromJsonBody(ClassDefinition definition) {
  final buffer = StringBuffer();
  buffer.writeln(
      '''switch (json['${definition.typeNameField.name}'].toString()) {''');

  for (final p in definition.factoryPossibilities.entries) {
    buffer.writeln('''      case r'${p.key}':
        return ${p.value.namePrintable}.fromJson(json);''');
  }

  buffer.writeln('''      default:
    }
    return _\$${definition.name.namePrintable}FromJson(json);''');
  return buffer.toString();
}

String _toJsonBody(ClassDefinition definition) {
  final buffer = StringBuffer();
  final typeName = definition.typeNameField.namePrintable;
  buffer.writeln('''switch ($typeName) {''');

  for (final p in definition.factoryPossibilities.entries) {
    buffer.writeln('''      case r'${p.key}':
        return (this as ${p.value.namePrintable}).toJson();''');
  }

  buffer.writeln('''      default:
    }
    return _\$${definition.name.namePrintable}ToJson(this);''');
  return buffer.toString();
}

Method _propsMethod(String body) {
  return Method((m) => m
    ..type = MethodType.getter
    ..returns = refer('List<Object>')
    ..annotations.add(CodeExpression(Code('override')))
    ..name = 'props'
    ..lambda = true
    ..body = Code(body));
}

/// Generates a [Spec] of a single class definition.
Spec classDefinitionToSpec(
    ClassDefinition definition, Iterable<FragmentClassDefinition> fragments) {
  final fromJson = definition.factoryPossibilities.isNotEmpty
      ? Constructor(
          (b) => b
            ..factory = true
            ..name = 'fromJson'
            ..requiredParameters.add(Parameter(
              (p) => p
                ..type = refer('Map<String, dynamic>')
                ..name = 'json',
            ))
            ..body = Code(_fromJsonBody(definition)),
        )
      : Constructor(
          (b) => b
            ..factory = true
            ..name = 'fromJson'
            ..lambda = true
            ..requiredParameters.add(Parameter(
              (p) => p
                ..type = refer('Map<String, dynamic>')
                ..name = 'json',
            ))
            ..body = Code('_\$${definition.name.namePrintable}FromJson(json)'),
        );

  final toJson = definition.factoryPossibilities.isNotEmpty
      ? Method(
          (m) => m
            ..name = 'toJson'
            ..returns = refer('Map<String, dynamic>')
            ..body = Code(_toJsonBody(definition)),
        )
      : Method(
          (m) => m
            ..name = 'toJson'
            ..lambda = true
            ..returns = refer('Map<String, dynamic>')
            ..body = Code('_\$${definition.name.namePrintable}ToJson(this)'),
        );

  final props = definition.mixins
      .map((i) {
        return fragments
            .firstWhere((f) {
              return f.name == i;
            })
            .properties
            .map((p) => p.name.namePrintable);
      })
      .expand((i) => i)
      .followedBy(definition.properties.map((p) => p.name.namePrintable));

  var classExtension = definition.extension != null
      ? refer(definition.extension.namePrintable)
      : null;

  final _responseTypes = [
    'FetchBookingById\$QueryType\$GetBookingsByID\$Bookings',
    'FetchBookings\$QueryType\$GetBookingsByActor\$Bookings',
    'CreateBooking\$MutationType\$CreateBooking\$Bookings',
    'RescheduleBooking\$MutationType\$UpdateService\$Bookings',
    'CancelBooking\$MutationType\$UpdateBooking\$Bookings',
  ];
  final List<Method> customOverrides = [];
  if (_responseTypes.contains(definition.name.namePrintable)) {
    classExtension = refer('QueryResponse');

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('Map<String, dynamic>')
      ..name = 'bookingDetail'
      ..lambda = true
      ..body = Code('''{\'actorCounterId\': actorCounterId,
    \'farmId\': farmId,
    \'farmCropId\': farmCropId,
    \'services\': services?.map((e) => e?.toJson())?.toList()}''')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('Map<String, dynamic>')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'columnValues'
      ..lambda = true
      ..body = Code('''{\'booking_id\': bookingId,
        'booking_type':
            _\$FarmNurtureCoreContractsCommonBookingTypeEnumMap[bookingType],
        'booking_source':
            _\$FarmNurtureCoreContractsCommonBookingSourceEnumMap[bookingSource],
        'booking_status':
            _\$FarmNurtureCoreContractsCommonBookingStatusEnumMap[bookingStatus],
        'actor_id': actorId,
        'actor_type':
            _\$FarmNurtureCoreContractsCommonActorTypeEnumMap[actorType],
        'booking_detail': jsonEncode(bookingDetail)}''')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('int')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'fetchedTimestamp'
      ..lambda = true
      ..body = Code('0')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('String')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'tableName'
      ..lambda = true
      ..body = Code('\'booking\'')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('String')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'primaryKeyFieldName'
      ..lambda = true
      ..body = Code('\'booking_id\'')));
  }

  final _queryTypes = [
    'FetchBookingById\$QueryType',
    'FetchBookings\$QueryType',
    'CreateBooking\$MutationType',
    'RescheduleBooking\$MutationType',
    'CancelBooking\$MutationType',
  ];
  if (_queryTypes.contains(definition.name.namePrintable)) {
    classExtension = refer('QueryListResponse');

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('List<int>')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'deleteIds'
      ..lambda = true
      ..body = Code('[]')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('String')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'primaryKeyFieldName'
      ..lambda = true
      ..body = Code('\'booking_id\'')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('List<QueryResponse>')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'rows'
      ..lambda = true
      ..body =
          Code('${definition.properties.first.name.namePrintable}.bookings')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('String')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'tableName'
      ..lambda = true
      ..body = Code('\'booking\'')));
  }

  return Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('JsonSerializable(explicitToJson: true, includeIfNull: false)')))
      ..name = definition.name.namePrintable
      ..mixins.add(refer('EquatableMixin'))
      ..mixins.addAll(definition.mixins.map((i) => refer(i.namePrintable)))
      ..methods.add(_propsMethod('[${props.join(',')}]'))
      ..extend = classExtension
      ..implements.addAll(definition.implementations.map((i) => refer(i)))
      ..constructors.add(Constructor((b) {
        if (definition.isInput) {
          b
            ..optionalParameters.addAll(definition.properties
                .where((property) =>
                    !property.isOverride && !property.isResolveType)
                .map(
                  (property) => Parameter(
                    (p) {
                      p
                        ..name = property.name.namePrintable
                        ..named = true
                        ..toThis = true;

                      if (property.isNonNull) {
                        p.annotations.add(refer('required'));
                      }
                    },
                  ),
                ));
        }
      }))
      ..constructors.add(fromJson)
      ..methods.add(toJson)
      ..methods.addAll(customOverrides)
      ..fields.addAll(definition.properties.map((p) {
        final field = Field(
          (f) => f
            ..name = p.name.namePrintable
            ..type = refer(p.type.namePrintable)
            ..annotations.addAll(
              p.annotations.map((e) => CodeExpression(Code(e))),
            ),
        );
        return field;
      })),
  );
}

/// Generates a [Spec] of a single fragment class definition.
Spec fragmentClassDefinitionToSpec(FragmentClassDefinition definition) {
  final fields = (definition.properties ?? []).map((p) {
    final lines = <String>[];
    lines.addAll(p.annotations.map((e) => '@${e}'));
    lines.add('${p.type.namePrintable} ${p.name.namePrintable};');
    return lines.join('\n');
  });

  return CodeExpression(Code('''mixin ${definition.name.namePrintable} {
  ${fields.join('\n')}
}'''));
}

/// Generates a [Spec] of a detail model class.
Spec generateModelDetailClassSpec() {
  final List<Field> detailFieldDefinitions = [];
  detailFieldDefinitions.add(Field((f) => f
    ..type = refer('int')
    ..name = 'actorCounterId'));
  detailFieldDefinitions.add(Field((f) => f
    ..type = refer('int')
    ..name = 'farmId'));
  detailFieldDefinitions.add(Field((f) => f
    ..type = refer('int')
    ..name = 'farmCropId'));
  detailFieldDefinitions.add(Field((f) => f
    ..type = refer(
        'List<FetchBookings\$QueryType\$GetBookingsByActor\$Bookings\$Services>')
    ..name = 'services'));
  return Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('JsonSerializable(explicitToJson: true, includeIfNull: false)')))
      ..name = 'BookingDetail'
      ..constructors.add(Constructor(
        (b) => b,
      ))
      ..constructors.add(Constructor(
        (b) => b
          ..factory = true
          ..name = 'fromJson'
          ..lambda = true
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..body = Code('_\$BookingDetailFromJson(json)'),
      ))
      ..methods.add(Method(
        (m) => m
          ..name = 'toJson'
          ..lambda = true
          ..returns = refer('Map<String, dynamic>')
          ..body = Code('_\$BookingDetailToJson(this)'),
      ))
      ..fields.addAll(detailFieldDefinitions),
  );
}

/// Generates a [Spec] of a mutation argument class.
Spec generateArgumentClassSpec(QueryDefinition definition) {
  return Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('JsonSerializable(explicitToJson: true, includeIfNull: false)')))
      ..name = '${definition.className}Arguments'
      ..extend = refer('JsonSerializable')
      ..mixins.add(refer('EquatableMixin'))
      ..methods.add(_propsMethod(
          '[${definition.inputs.map((input) => input.name.namePrintable).join(',')}]'))
      ..constructors.add(Constructor(
        (b) => b
          ..optionalParameters.addAll(definition.inputs.map(
            (input) => Parameter(
              (p) {
                p
                  ..name = input.name.namePrintable
                  ..named = true
                  ..toThis = true;

                if (input.isNonNull) {
                  p.annotations.add(refer('required'));
                }
              },
            ),
          )),
      ))
      ..constructors.add(Constructor(
        (b) => b
          ..factory = true
          ..name = 'fromJson'
          ..lambda = true
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..body = Code('_\$${definition.className}ArgumentsFromJson(json)'),
      ))
      ..methods.add(Method(
        (m) => m
          ..name = 'toJson'
          ..lambda = true
          ..returns = refer('Map<String, dynamic>')
          ..body = Code('_\$${definition.className}ArgumentsToJson(this)'),
      ))
      ..fields.addAll(definition.inputs.map(
        (p) => Field(
          (f) => f
            ..name = p.name.namePrintable
            ..type = refer(p.type.namePrintable)
            ..modifier = FieldModifier.final$
            ..annotations
                .addAll(p.annotations.map((e) => CodeExpression(Code(e)))),
        ),
      )),
  );
}

/// Generates a [Spec] of a query/mutation class.
Spec generateQueryClassSpec(QueryDefinition definition) {
  final typeDeclaration = definition.inputs.isEmpty
      ? '${definition.name.namePrintable}, JsonSerializable'
      : '${definition.name.namePrintable}, ${definition.className}Arguments';

  final constructor = definition.inputs.isEmpty
      ? Constructor()
      : Constructor((b) => b
        ..optionalParameters.add(Parameter(
          (p) => p
            ..name = 'variables'
            ..toThis = true
            ..named = true,
        )));

  final fields = [
    Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('DocumentNode', 'package:gql/ast.dart')
        ..name = 'document'
        ..assignment = dart.fromNode(definition.document).code,
    ),
    Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('String')
        ..name = 'operationName'
        ..assignment = Code('\'${definition.operationName}\''),
    ),
  ];

  if (definition.inputs.isNotEmpty) {
    fields.add(Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('${definition.className}Arguments')
        ..name = 'variables',
    ));
  }

  return Class(
    (b) => b
      ..name = '${definition.className}${definition.suffix}'
      ..extend = refer('GraphQLQuery<$typeDeclaration>')
      ..constructors.add(constructor)
      ..fields.addAll(fields)
      ..methods.add(_propsMethod(
          '[document, operationName${definition.inputs.isNotEmpty ? ', variables' : ''}]'))
      ..methods.add(Method(
        (m) => m
          ..annotations.add(CodeExpression(Code('override')))
          ..returns = refer(definition.name.namePrintable)
          ..name = 'parse'
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..lambda = true
          ..body = Code('${definition.name.namePrintable}.fromJson(json)'),
      )),
  );
}

/// Gathers and generates a [Spec] of a whole query/mutation and its
/// dependencies into a single library file.
Spec generateLibrarySpec(LibraryDefinition definition) {
  final importDirectives = [
    Directive.import('package:json_annotation/json_annotation.dart'),
    Directive.import('package:equatable/equatable.dart'),
    Directive.import('package:gql/ast.dart'),
    Directive.import('dart:convert'),
    Directive.import('package:nf_gql_client/nf_gql_client_lib.dart'),
  ];

  if (definition.queries.any((q) => q.generateHelpers)) {
    importDirectives.insertAll(
      0,
      [
        Directive.import('package:artemis/artemis.dart'),
      ],
    );
  }

  // inserts import of meta package only if there is at least one non nullable input
  // see this link for details https://github.com/dart-lang/sdk/issues/4188#issuecomment-240322222
  if (hasNonNullableInput(definition.queries)) {
    importDirectives.insertAll(
      0,
      [
        Directive.import('package:meta/meta.dart'),
      ],
    );
  }

  importDirectives.addAll(definition.customImports
      .map((customImport) => Directive.import(customImport)));

  final bodyDirectives = <Spec>[
    CodeExpression(Code('part \'${definition.basename}.g.dart\';')),
  ];

  final uniqueDefinitions = definition.queries
      .map((e) => e.classes.map((e) => e))
      .expand((e) => e)
      .fold<Map<String, Definition>>(<String, Definition>{}, (acc, element) {
    acc[element.name.name] = element;

    return acc;
  }).values;

  final fragments = uniqueDefinitions.whereType<FragmentClassDefinition>();
  final classes = uniqueDefinitions.whereType<ClassDefinition>();
  final enums = uniqueDefinitions.whereType<EnumDefinition>();

  bodyDirectives.addAll(fragments.map(fragmentClassDefinitionToSpec));
  bodyDirectives
      .addAll(classes.map((cDef) => classDefinitionToSpec(cDef, fragments)));
  bodyDirectives.addAll(enums.map(enumDefinitionToSpec));
  bodyDirectives.addAll(enums.map(enumDefinitionExtensionToSpec));

  for (final queryDef in definition.queries) {
    if (queryDef.inputs.isNotEmpty && queryDef.generateHelpers) {
      bodyDirectives.add(generateArgumentClassSpec(queryDef));
    }
    if (queryDef.generateHelpers) {
      bodyDirectives.add(generateQueryClassSpec(queryDef));
    }
  }

  bodyDirectives.add(generateModelDetailClassSpec());

  return Library(
    (b) => b..directives.addAll(importDirectives)..body.addAll(bodyDirectives),
  );
}

/// Emit a [Spec] into a String, considering Dart formatting.
String specToString(Spec spec) {
  final emitter = DartEmitter();
  return DartFormatter().format(spec.accept(emitter).toString());
}

/// Generate Dart code typings from a query or mutation and its response from
/// a [QueryDefinition] into a buffer.
void writeLibraryDefinitionToBuffer(
    StringBuffer buffer, LibraryDefinition definition) {
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
  buffer.write(specToString(generateLibrarySpec(definition)));
}

/// Generate an empty file just exporting the library. This is used to avoid
/// a breaking change on file generation.
String writeLibraryForwarder(LibraryDefinition definition) =>
    '''// GENERATED CODE - DO NOT MODIFY BY HAND
export '${definition.basename}.dart';
''';
