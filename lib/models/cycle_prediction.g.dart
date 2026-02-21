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
    r'confidence': PropertySchema(
      id: 1,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'factorsJson': PropertySchema(
      id: 2,
      name: r'factorsJson',
      type: IsarType.string,
    ),
    r'fertileWindowEnd': PropertySchema(
      id: 3,
      name: r'fertileWindowEnd',
      type: IsarType.dateTime,
    ),
    r'fertileWindowStart': PropertySchema(
      id: 4,
      name: r'fertileWindowStart',
      type: IsarType.dateTime,
    ),
    r'predictedCycleLength': PropertySchema(
      id: 5,
      name: r'predictedCycleLength',
      type: IsarType.long,
    ),
    r'predictedOvulation': PropertySchema(
      id: 6,
      name: r'predictedOvulation',
      type: IsarType.dateTime,
    ),
    r'predictedPeriodDate': PropertySchema(
      id: 7,
      name: r'predictedPeriodDate',
      type: IsarType.dateTime,
    ),
    r'ts': PropertySchema(
      id: 8,
      name: r'ts',
      type: IsarType.dateTime,
    ),
    r'verified': PropertySchema(
      id: 9,
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
  return bytesCount;
}

void _cyclePredictionSerialize(
  CyclePrediction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.actualPeriodDate);
  writer.writeDouble(offsets[1], object.confidence);
  writer.writeString(offsets[2], object.factorsJson);
  writer.writeDateTime(offsets[3], object.fertileWindowEnd);
  writer.writeDateTime(offsets[4], object.fertileWindowStart);
  writer.writeLong(offsets[5], object.predictedCycleLength);
  writer.writeDateTime(offsets[6], object.predictedOvulation);
  writer.writeDateTime(offsets[7], object.predictedPeriodDate);
  writer.writeDateTime(offsets[8], object.ts);
  writer.writeBool(offsets[9], object.verified);
}

CyclePrediction _cyclePredictionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CyclePrediction();
  object.actualPeriodDate = reader.readDateTimeOrNull(offsets[0]);
  object.confidence = reader.readDouble(offsets[1]);
  object.factorsJson = reader.readStringOrNull(offsets[2]);
  object.fertileWindowEnd = reader.readDateTime(offsets[3]);
  object.fertileWindowStart = reader.readDateTime(offsets[4]);
  object.id = id;
  object.predictedCycleLength = reader.readLong(offsets[5]);
  object.predictedOvulation = reader.readDateTime(offsets[6]);
  object.predictedPeriodDate = reader.readDateTime(offsets[7]);
  object.ts = reader.readDateTime(offsets[8]);
  object.verified = reader.readBool(offsets[9]);
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
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
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

  QueryBuilder<CyclePrediction, CyclePrediction, QDistinct> distinctByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ts');
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

  QueryBuilder<CyclePrediction, DateTime, QQueryOperations> tsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ts');
    });
  }

  QueryBuilder<CyclePrediction, bool, QQueryOperations> verifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verified');
    });
  }
}
