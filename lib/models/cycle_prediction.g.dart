// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_prediction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCyclePredictionCollection on Isar {
  IsarCollection<CyclePrediction> get cyclePredictions => this.collection();
}

const CyclePredictionSchema = CollectionSchema(
  name: r'CyclePrediction',
  id: -3806472271466472023,
  properties: {
    r'actualPeriodDate': PropertySchema(
      id: 0,
      name: r'actualPeriodDate',
      type: IsarType.dateTime,
    ),
    r'completedCycleCount': PropertySchema(
      id: 1,
      name: r'completedCycleCount',
      type: IsarType.long,
    ),
    r'confidence': PropertySchema(
      id: 2,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'factorsJson': PropertySchema(
      id: 3,
      name: r'factorsJson',
      type: IsarType.string,
    ),
    r'fertileWindowEnd': PropertySchema(
      id: 4,
      name: r'fertileWindowEnd',
      type: IsarType.dateTime,
    ),
    r'fertileWindowStart': PropertySchema(
      id: 5,
      name: r'fertileWindowStart',
      type: IsarType.dateTime,
    ),
    r'modelVersion': PropertySchema(
      id: 6,
      name: r'modelVersion',
      type: IsarType.string,
    ),
    r'predictedCycleLength': PropertySchema(
      id: 7,
      name: r'predictedCycleLength',
      type: IsarType.long,
    ),
    r'predictedOvulation': PropertySchema(
      id: 8,
      name: r'predictedOvulation',
      type: IsarType.dateTime,
    ),
    r'predictedPeriodDate': PropertySchema(
      id: 9,
      name: r'predictedPeriodDate',
      type: IsarType.dateTime,
    ),
    r'predictedPeriodRangeEnd': PropertySchema(
      id: 10,
      name: r'predictedPeriodRangeEnd',
      type: IsarType.dateTime,
    ),
    r'predictedPeriodRangeStart': PropertySchema(
      id: 11,
      name: r'predictedPeriodRangeStart',
      type: IsarType.dateTime,
    ),
    r'ts': PropertySchema(
      id: 12,
      name: r'ts',
      type: IsarType.dateTime,
    ),
    r'variabilityDays': PropertySchema(
      id: 13,
      name: r'variabilityDays',
      type: IsarType.double,
    ),
    r'verified': PropertySchema(
      id: 14,
      name: r'verified',
      type: IsarType.bool,
    )
  },
  estimateSize: _cyclePredictionEstimateSize,
  serialize: _cyclePredictionSerialize,
  deserialize: _cyclePredictionDeserialize,
  deserializeProp: _cyclePredictionDeserializeProp,
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
  getId: _cyclePredictionGetId,
  getLinks: _cyclePredictionGetLinks,
  attach: _cyclePredictionAttach,
  version: '3.1.0+1',
);

int _cyclePredictionEstimateSize(
  CyclePrediction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.factorsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.modelVersion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cyclePredictionSerialize(
  CyclePrediction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.actualPeriodDate);
  writer.writeLong(offsets[1], object.completedCycleCount);
  writer.writeDouble(offsets[2], object.confidence);
  writer.writeString(offsets[3], object.factorsJson);
  writer.writeDateTime(offsets[4], object.fertileWindowEnd);
  writer.writeDateTime(offsets[5], object.fertileWindowStart);
  writer.writeString(offsets[6], object.modelVersion);
  writer.writeLong(offsets[7], object.predictedCycleLength);
  writer.writeDateTime(offsets[8], object.predictedOvulation);
  writer.writeDateTime(offsets[9], object.predictedPeriodDate);
  writer.writeDateTime(offsets[10], object.predictedPeriodRangeEnd);
  writer.writeDateTime(offsets[11], object.predictedPeriodRangeStart);
  writer.writeDateTime(offsets[12], object.ts);
  writer.writeDouble(offsets[13], object.variabilityDays);
  writer.writeBool(offsets[14], object.verified);
}

CyclePrediction _cyclePredictionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CyclePrediction();
  object.actualPeriodDate = reader.readDateTimeOrNull(offsets[0]);
  object.completedCycleCount = reader.readLong(offsets[1]);
  object.confidence = reader.readDouble(offsets[2]);
  object.factorsJson = reader.readStringOrNull(offsets[3]);
  object.fertileWindowEnd = reader.readDateTime(offsets[4]);
  object.fertileWindowStart = reader.readDateTime(offsets[5]);
  object.id = id;
  object.modelVersion = reader.readStringOrNull(offsets[6]);
  object.predictedCycleLength = reader.readLong(offsets[7]);
  object.predictedOvulation = reader.readDateTime(offsets[8]);
  object.predictedPeriodDate = reader.readDateTime(offsets[9]);
  object.predictedPeriodRangeEnd = reader.readDateTimeOrNull(offsets[10]);
  object.predictedPeriodRangeStart = reader.readDateTimeOrNull(offsets[11]);
  object.ts = reader.readDateTime(offsets[12]);
  object.variabilityDays = reader.readDoubleOrNull(offsets[13]);
  object.verified = reader.readBool(offsets[14]);
  return object;
}

P _cyclePredictionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cyclePredictionGetId(CyclePrediction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cyclePredictionGetLinks(CyclePrediction object) {
  return [];
}

void _cyclePredictionAttach(
    IsarCollection<dynamic> col, Id id, CyclePrediction object) {
  object.id = id;
}

extension CyclePredictionQueryWhereSort
    on QueryBuilder<CyclePrediction, CyclePrediction, QWhere> {
  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhere> anyTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ts'),
      );
    });
  }
}

extension CyclePredictionQueryWhere
    on QueryBuilder<CyclePrediction, CyclePrediction, QWhereClause> {
  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause> idBetween(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause> tsEqualTo(
      DateTime ts) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ts',
        value: [ts],
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause>
      tsNotEqualTo(DateTime ts) {
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause>
      tsGreaterThan(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause> tsLessThan(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterWhereClause> tsBetween(
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

extension CyclePredictionQueryFilter
    on QueryBuilder<CyclePrediction, CyclePrediction, QFilterCondition> {
  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      actualPeriodDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actualPeriodDate',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      actualPeriodDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actualPeriodDate',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      actualPeriodDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualPeriodDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      actualPeriodDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualPeriodDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      actualPeriodDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualPeriodDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      actualPeriodDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualPeriodDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      completedCycleCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedCycleCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      completedCycleCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedCycleCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      completedCycleCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedCycleCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      completedCycleCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedCycleCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      confidenceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'factorsJson',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'factorsJson',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'factorsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'factorsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'factorsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'factorsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'factorsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'factorsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'factorsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'factorsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'factorsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      factorsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'factorsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowEndEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fertileWindowEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowEndGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fertileWindowEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowEndLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fertileWindowEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowEndBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fertileWindowEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fertileWindowStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fertileWindowStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fertileWindowStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      fertileWindowStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fertileWindowStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modelVersion',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modelVersion',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      modelVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedCycleLengthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedCycleLength',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedCycleLengthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedCycleLength',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedCycleLengthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedCycleLength',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedCycleLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedCycleLength',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedOvulationEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedOvulation',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedOvulationGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedOvulation',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedOvulationLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedOvulation',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedOvulationBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedOvulation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedPeriodDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedPeriodDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedPeriodDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedPeriodDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'predictedPeriodRangeEnd',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'predictedPeriodRangeEnd',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeEndEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedPeriodRangeEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeEndGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedPeriodRangeEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeEndLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedPeriodRangeEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeEndBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedPeriodRangeEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeStartIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'predictedPeriodRangeStart',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeStartIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'predictedPeriodRangeStart',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeStartEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedPeriodRangeStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeStartGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedPeriodRangeStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeStartLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedPeriodRangeStart',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      predictedPeriodRangeStartBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedPeriodRangeStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      tsEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      tsLessThan(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      tsBetween(
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

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      variabilityDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'variabilityDays',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      variabilityDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'variabilityDays',
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      variabilityDaysEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'variabilityDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      variabilityDaysGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'variabilityDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      variabilityDaysLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'variabilityDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      variabilityDaysBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'variabilityDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterFilterCondition>
      verifiedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verified',
        value: value,
      ));
    });
  }
}

extension CyclePredictionQueryObject
    on QueryBuilder<CyclePrediction, CyclePrediction, QFilterCondition> {}

extension CyclePredictionQueryLinks
    on QueryBuilder<CyclePrediction, CyclePrediction, QFilterCondition> {}

extension CyclePredictionQuerySortBy
    on QueryBuilder<CyclePrediction, CyclePrediction, QSortBy> {
  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByActualPeriodDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualPeriodDate', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByActualPeriodDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualPeriodDate', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByCompletedCycleCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCycleCount', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByCompletedCycleCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCycleCount', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByFactorsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factorsJson', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByFactorsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factorsJson', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByFertileWindowEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowEnd', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByFertileWindowEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowEnd', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByFertileWindowStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowStart', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByFertileWindowStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowStart', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByModelVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelVersion', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByModelVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelVersion', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedCycleLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedCycleLength', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedCycleLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedCycleLength', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedOvulation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedOvulation', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedOvulationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedOvulation', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedPeriodDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodDate', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedPeriodDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodDate', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedPeriodRangeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeEnd', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedPeriodRangeEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeEnd', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedPeriodRangeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeStart', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByPredictedPeriodRangeStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeStart', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy> sortByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy> sortByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByVariabilityDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variabilityDays', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByVariabilityDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variabilityDays', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verified', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      sortByVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verified', Sort.desc);
    });
  }
}

extension CyclePredictionQuerySortThenBy
    on QueryBuilder<CyclePrediction, CyclePrediction, QSortThenBy> {
  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByActualPeriodDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualPeriodDate', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByActualPeriodDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualPeriodDate', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByCompletedCycleCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCycleCount', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByCompletedCycleCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCycleCount', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByFactorsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factorsJson', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByFactorsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factorsJson', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByFertileWindowEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowEnd', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByFertileWindowEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowEnd', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByFertileWindowStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowStart', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByFertileWindowStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fertileWindowStart', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByModelVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelVersion', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByModelVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelVersion', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedCycleLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedCycleLength', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedCycleLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedCycleLength', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedOvulation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedOvulation', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedOvulationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedOvulation', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedPeriodDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodDate', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedPeriodDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodDate', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedPeriodRangeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeEnd', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedPeriodRangeEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeEnd', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedPeriodRangeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeStart', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByPredictedPeriodRangeStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedPeriodRangeStart', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy> thenByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy> thenByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByVariabilityDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variabilityDays', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByVariabilityDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variabilityDays', Sort.desc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verified', Sort.asc);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QAfterSortBy>
      thenByVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verified', Sort.desc);
    });
  }
}

extension CyclePredictionQueryWhereDistinct
    on QueryBuilder<CyclePrediction, CyclePrediction, QDistinct> {
  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByActualPeriodDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualPeriodDate');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByCompletedCycleCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedCycleCount');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByFactorsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'factorsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByFertileWindowEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fertileWindowEnd');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByFertileWindowStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fertileWindowStart');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByModelVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelVersion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByPredictedCycleLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedCycleLength');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByPredictedOvulation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedOvulation');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByPredictedPeriodDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedPeriodDate');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByPredictedPeriodRangeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedPeriodRangeEnd');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByPredictedPeriodRangeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedPeriodRangeStart');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct> distinctByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ts');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByVariabilityDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'variabilityDays');
    });
  }

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct>
      distinctByVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verified');
    });
  }
}

extension CyclePredictionQueryProperty
    on QueryBuilder<CyclePrediction, CyclePrediction, QQueryProperty> {
  QueryBuilder<CyclePrediction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CyclePrediction, DateTime?, QQueryOperations>
      actualPeriodDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualPeriodDate');
    });
  }

  QueryBuilder<CyclePrediction, int, QQueryOperations>
      completedCycleCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedCycleCount');
    });
  }

  QueryBuilder<CyclePrediction, double, QQueryOperations> confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<CyclePrediction, String?, QQueryOperations>
      factorsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'factorsJson');
    });
  }

  QueryBuilder<CyclePrediction, DateTime, QQueryOperations>
      fertileWindowEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fertileWindowEnd');
    });
  }

  QueryBuilder<CyclePrediction, DateTime, QQueryOperations>
      fertileWindowStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fertileWindowStart');
    });
  }

  QueryBuilder<CyclePrediction, String?, QQueryOperations>
      modelVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelVersion');
    });
  }

  QueryBuilder<CyclePrediction, int, QQueryOperations>
      predictedCycleLengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedCycleLength');
    });
  }

  QueryBuilder<CyclePrediction, DateTime, QQueryOperations>
      predictedOvulationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedOvulation');
    });
  }

  QueryBuilder<CyclePrediction, DateTime, QQueryOperations>
      predictedPeriodDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedPeriodDate');
    });
  }

  QueryBuilder<CyclePrediction, DateTime?, QQueryOperations>
      predictedPeriodRangeEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedPeriodRangeEnd');
    });
  }

  QueryBuilder<CyclePrediction, DateTime?, QQueryOperations>
      predictedPeriodRangeStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedPeriodRangeStart');
    });
  }

  QueryBuilder<CyclePrediction, DateTime, QQueryOperations> tsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ts');
    });
  }

  QueryBuilder<CyclePrediction, double?, QQueryOperations>
      variabilityDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'variabilityDays');
    });
  }

  QueryBuilder<CyclePrediction, bool, QQueryOperations> verifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verified');
    });
  }
}
