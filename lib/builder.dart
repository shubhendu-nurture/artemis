import 'dart:async';
import 'dart:convert';

import 'package:artemis/generator/data/data.dart';
import 'package:artemis/generator/helpers.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

import './generator.dart';
import './generator/print_helpers.dart';
import './schema/options.dart';
import 'generator/errors.dart';

/// [GraphQLQueryBuilder] instance, to be used by `build_runner`.
GraphQLQueryBuilder graphQLQueryBuilder(BuilderOptions options) =>
    GraphQLQueryBuilder(options);

String _addGraphQLExtensionToPathIfNeeded(String path) {
  if (!path.endsWith('.graphql.dart')) {
    return path.replaceAll(RegExp(r'\.dart$'), '.graphql.dart');
  }
  return path;
}

List<String> _builderOptionsToExpectedOutputs(BuilderOptions builderOptions) {
  final schemaMaps =
      GeneratorOptions.fromJson(builderOptions.config).schemaMapping;

  if (schemaMaps.any((s) => s.output == null)) {
    throw Exception('''One or more SchemaMap configurations miss an output!
                       Please check your build.yaml file.''');
  }

  return schemaMaps
      .map((s) {
        final outputWithoutLib = s.output.replaceAll(RegExp(r'^lib/'), '');
        final outputs = [
          outputWithoutLib,
          _addGraphQLExtensionToPathIfNeeded(outputWithoutLib)
        ];
        if (null != s.entityOutput) {
          outputs.add(s.entityOutput.replaceAll(RegExp(r'^lib/'), ''));
        }
        return outputs;
      })
      .expand((e) => e)
      .toList();
}

/// Main Artemis builder.
class GraphQLQueryBuilder implements Builder {
  /// Creates a builder from [BuilderOptions].
  GraphQLQueryBuilder(BuilderOptions builderOptions)
      : options = GeneratorOptions.fromJson(builderOptions.config),
        expectedOutputs = _builderOptionsToExpectedOutputs(builderOptions);

  /// This generator options, gathered from `build.yaml` file.
  final GeneratorOptions options;

  /// List FragmentDefinitionNode in fragments_glob.
  final List<FragmentDefinitionNode> fragmentsCommon = [];

  /// The generated output file.
  final List<String> expectedOutputs;

  /// Callback fired when the generator processes a [QueryDefinition].
  OnBuildQuery onBuild;

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': expectedOutputs,
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (options.fragmentsGlob != null) {
      final fragmentStream = buildStep.findAssets(Glob(options.fragmentsGlob));
      final fDocs = await fragmentStream
          .asyncMap(
            (asset) async => parseString(
              await buildStep.readAsString(asset),
              url: asset.path,
            ),
          )
          .toList();
      fDocs.forEach((fDoc) => fragmentsCommon.addAll(
          fDoc.definitions.whereType<FragmentDefinitionNode>().toList()));
    }

    for (final schemaMap in options.schemaMapping) {
      final buffer = StringBuffer();
      final outputFileId = AssetId(buildStep.inputId.package,
          _addGraphQLExtensionToPathIfNeeded(schemaMap.output));

      // Loop through all files in glob
      if (schemaMap.queriesGlob == null) {
        throw Exception('''No queries were considered on this generation!
                          Make sure that `queries_glob` your build.yaml 
                          file include GraphQL queries files.''');
      } else if (Glob(schemaMap.queriesGlob).matches(schemaMap.schema)) {
        throw QueryGlobsSchemaException();
      } else if (Glob(schemaMap.queriesGlob).matches(schemaMap.output)) {
        throw QueryGlobsOutputException();
      }

      final assetStream = buildStep.findAssets(Glob(schemaMap.queriesGlob));
      final gqlDocs = await assetStream
          .asyncMap(
            (asset) async => parseString(
              await buildStep.readAsString(asset),
              url: asset.path,
            ),
          )
          .toList();

      final schemaAssetStream = buildStep.findAssets(Glob(schemaMap.schema));

      DocumentNode gqlSchema;

      try {
        gqlSchema = await schemaAssetStream
            .asyncMap(
              (asset) async => parseString(
                await buildStep.readAsString(asset),
                url: asset.path,
              ),
            )
            .first;
      } catch (e) {
        throw Exception('''Schema `${schemaMap.schema}` was not found or 
                          doesn't have a proper format! Make sure the file 
                          exists and you've typed it correctly on build.yaml.
                          ${e}''');
      }

      final libDefinition = generateLibrary(
        _addGraphQLExtensionToPathIfNeeded(schemaMap.output),
        gqlDocs,
        options,
        schemaMap,
        fragmentsCommon,
        gqlSchema,
      );
      if (onBuild != null) {
        onBuild(libDefinition);
      }
      writeLibraryDefinitionToBuffer(buffer, libDefinition);

      await buildStep.writeAsString(outputFileId, buffer.toString());

      if (!schemaMap.output.endsWith('.graphql.dart')) {
        final forwarderOutputFileId =
            AssetId(buildStep.inputId.package, schemaMap.output);
        await buildStep.writeAsString(
            forwarderOutputFileId, writeLibraryForwarder(libDefinition));
      }

      // Check if metadata file is provided for generating DB objects
      if (null != schemaMap.metadataFile && schemaMap.metadataFile.isNotEmpty) {
        print('Generate db entities for config in ${schemaMap.metadataFile}');
        final dbMetadataInfo = await _getDbMetadataInfo(
            buildStep, schemaMap.metadataFile, libDefinition);
        //generate db entity for this schema map
        buffer.clear();
        final entityOutputFileId = AssetId(
          buildStep.inputId.package,
          schemaMap.entityOutput,
        );
        writeEntityObjectToBuffer(
          buffer,
          buildStep.inputId.package,
          schemaMap.output,
          schemaMap.entityOutput,
          dbMetadataInfo,
        );
        await buildStep.writeAsString(entityOutputFileId, buffer.toString());
      }
    }
  }

  Future<DbMetadataInfo> _getDbMetadataInfo(
    BuildStep buildStep,
    String metadataFile,
    LibraryDefinition definition,
  ) async {
    final metadataAssetStream = buildStep.findAssets(Glob(metadataFile));
    try {
      final dbMetadataInfo = await metadataAssetStream.asyncMap(
        (asset) async {
          final jsonString = await buildStep.readAsString(asset);
          return DbMetadataInfo.fromJson(
              jsonDecode(jsonString) as Map<String, dynamic>);
        },
      ).first;
      dbMetadataInfo.allFields = getFieldMappings(definition.queries);
      return dbMetadataInfo;
    } catch (e) {
      throw Exception('''Could not parse metadata file $metadataFile ${e}''');
    }
  }
}
