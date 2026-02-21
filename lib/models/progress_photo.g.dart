// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressPhotoCollection on Isar {
  IsarCollection<ProgressPhoto> get progressPhotos => this.collection();
}

const ProgressPhotoSchema = CollectionSchema(
  name: r'ProgressPhoto',
  id: 2551591099620620851,
  properties: {
    r'analysisComplete': PropertySchema(
      id: 0,
      name: r'analysisComplete',
      type: IsarType.bool,
    ),
    r'analysisJson': PropertySchema(
      id: 1,
      name: r'analysisJson',
      type: IsarType.string,
    ),
    r'analysisRequested': PropertySchema(
      id: 2,
      name: r'analysisRequested',
      type: IsarType.bool,
    ),
    r'imagePath': PropertySchema(
      id: 3,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 4,
      name: r'notes',
      type: IsarType.string,
    ),
    r'pose': PropertySchema(
      id: 5,
      name: r'pose',
      type: IsarType.string,
    ),
    r'ts': PropertySchema(
      id: 6,
      name: r'ts',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _progressPhotoEstimateSize,
  serialize: _progressPhotoSerialize,
  deserialize: _progressPhotoDeserialize,
  deserializeProp: _progressPhotoDeserializeProp,
  idName: r'id',
  indexes: {
    r'ts': IndexSchema(
      id: -1208453773318402379,
      name: r'ts',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ts',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _progressPhotoGetId,
  getLinks: _progressPhotoGetLinks,
  attach: _progressPhotoAttach,
  version: '3.1.0+1',
);

int _progressPhotoEstimateSize(
  ProgressPhoto object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.analysisJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.imagePath.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.pose;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _progressPhotoSerialize(
  ProgressPhoto object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.analysisComplete);
  writer.writeString(offsets[1], object.analysisJson);
  writer.writeBool(offsets[2], object.analysisRequested);
  writer.writeString(offsets[3], object.imagePath);
  writer.writeString(offsets[4], object.notes);
  writer.writeString(offsets[5], object.pose);
  writer.writeDateTime(offsets[6], object.ts);
}

ProgressPhoto _progressPhotoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressPhoto();
  object.analysisComplete = reader.readBool(offsets[0]);
  object.analysisJson = reader.readStringOrNull(offsets[1]);
  object.analysisRequested = reader.readBool(offsets[2]);
  object.id = id;
  object.imagePath = reader.readString(offsets[3]);
  object.notes = reader.readStringOrNull(offsets[4]);
  object.pose = reader.readStringOrNull(offsets[5]);
  object.ts = reader.readDateTime(offsets[6]);
  return object;
}

P _progressPhotoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressPhotoGetId(ProgressPhoto object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressPhotoGetLinks(ProgressPhoto object) {
  return [];
}

void _progressPhotoAttach(
    IsarCollection<dynamic> col, Id id, ProgressPhoto object) {
  object.id = id;
}

extension ProgressPhotoQueryWhereSort
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QWhere> {
  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhere> anyTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ts'),
      );
    });
  }
}

extension ProgressPhotoQueryWhere
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QWhereClause> {
  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> tsEqualTo(
      DateTime ts) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ts',
        value: [ts],
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> tsNotEqualTo(
      DateTime ts) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ts',
              lower: [],
              upper: [ts],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ts',
              lower: [ts],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ts',
              lower: [ts],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ts',
              lower: [],
              upper: [ts],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> tsGreaterThan(
    DateTime ts, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ts',
        lower: [ts],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> tsLessThan(
    DateTime ts, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ts',
        lower: [],
        upper: [ts],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterWhereClause> tsBetween(
    DateTime lowerTs,
    DateTime upperTs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ts',
        lower: [lowerTs],
        includeLower: includeLower,
        upper: [upperTs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressPhotoQueryFilter
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QFilterCondition> {
  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'analysisComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'analysisJson',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'analysisJson',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'analysisJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'analysisJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'analysisJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'analysisJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'analysisJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'analysisJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'analysisJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'analysisJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'analysisJson',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'analysisJson',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      analysisRequestedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'analysisRequested',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pose',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pose',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> poseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> poseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pose',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pose',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> poseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pose',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pose',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      poseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pose',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> tsEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition>
      tsGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> tsLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterFilterCondition> tsBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressPhotoQueryObject
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QFilterCondition> {}

extension ProgressPhotoQueryLinks
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QFilterCondition> {}

extension ProgressPhotoQuerySortBy
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QSortBy> {
  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByAnalysisComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisComplete', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByAnalysisCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisComplete', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByAnalysisJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisJson', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByAnalysisJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisJson', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByAnalysisRequested() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisRequested', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByAnalysisRequestedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisRequested', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByPose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pose', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByPoseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pose', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> sortByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }
}

extension ProgressPhotoQuerySortThenBy
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QSortThenBy> {
  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByAnalysisComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisComplete', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByAnalysisCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisComplete', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByAnalysisJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisJson', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByAnalysisJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisJson', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByAnalysisRequested() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisRequested', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByAnalysisRequestedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analysisRequested', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy>
      thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByPose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pose', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByPoseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pose', Sort.desc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QAfterSortBy> thenByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }
}

extension ProgressPhotoQueryWhereDistinct
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct> {
  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct>
      distinctByAnalysisComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'analysisComplete');
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct> distinctByAnalysisJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'analysisJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct>
      distinctByAnalysisRequested() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'analysisRequested');
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct> distinctByPose(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pose', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressPhoto, ProgressPhoto, QDistinct> distinctByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ts');
    });
  }
}

extension ProgressPhotoQueryProperty
    on QueryBuilder<ProgressPhoto, ProgressPhoto, QQueryProperty> {
  QueryBuilder<ProgressPhoto, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressPhoto, bool, QQueryOperations>
      analysisCompleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'analysisComplete');
    });
  }

  QueryBuilder<ProgressPhoto, String?, QQueryOperations>
      analysisJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'analysisJson');
    });
  }

  QueryBuilder<ProgressPhoto, bool, QQueryOperations>
      analysisRequestedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'analysisRequested');
    });
  }

  QueryBuilder<ProgressPhoto, String, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<ProgressPhoto, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<ProgressPhoto, String?, QQueryOperations> poseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pose');
    });
  }

  QueryBuilder<ProgressPhoto, DateTime, QQueryOperations> tsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ts');
    });
  }
}
