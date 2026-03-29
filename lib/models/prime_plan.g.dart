// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prime_plan.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPrimePlanCollection on Isar {
  IsarCollection<PrimePlan> get primePlans => this.collection();
}

const PrimePlanSchema = CollectionSchema(
  name: r'PrimePlan',
  id: 566556248262072501,
  properties: {
    r'calories': PropertySchema(
      id: 0,
      name: r'calories',
      type: IsarType.long,
    ),
    r'carbsG': PropertySchema(
      id: 1,
      name: r'carbsG',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fatG': PropertySchema(
      id: 3,
      name: r'fatG',
      type: IsarType.long,
    ),
    r'phase': PropertySchema(
      id: 4,
      name: r'phase',
      type: IsarType.string,
    ),
    r'phaseStartedAt': PropertySchema(
      id: 5,
      name: r'phaseStartedAt',
      type: IsarType.dateTime,
    ),
    r'planName': PropertySchema(
      id: 6,
      name: r'planName',
      type: IsarType.string,
    ),
    r'preRefeedCalories': PropertySchema(
      id: 7,
      name: r'preRefeedCalories',
      type: IsarType.long,
    ),
    r'proteinG': PropertySchema(
      id: 8,
      name: r'proteinG',
      type: IsarType.long,
    ),
    r'stepTarget': PropertySchema(
      id: 9,
      name: r'stepTarget',
      type: IsarType.long,
    ),
    r'trainingDays': PropertySchema(
      id: 10,
      name: r'trainingDays',
      type: IsarType.long,
    )
  },
  estimateSize: _primePlanEstimateSize,
  serialize: _primePlanSerialize,
  deserialize: _primePlanDeserialize,
  deserializeProp: _primePlanDeserializeProp,
  idName: r'id',
  indexes: {
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _primePlanGetId,
  getLinks: _primePlanGetLinks,
  attach: _primePlanAttach,
  version: '3.1.0+1',
);

int _primePlanEstimateSize(
  PrimePlan object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.phase.length * 3;
  bytesCount += 3 + object.planName.length * 3;
  return bytesCount;
}

void _primePlanSerialize(
  PrimePlan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.calories);
  writer.writeLong(offsets[1], object.carbsG);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.fatG);
  writer.writeString(offsets[4], object.phase);
  writer.writeDateTime(offsets[5], object.phaseStartedAt);
  writer.writeString(offsets[6], object.planName);
  writer.writeLong(offsets[7], object.preRefeedCalories);
  writer.writeLong(offsets[8], object.proteinG);
  writer.writeLong(offsets[9], object.stepTarget);
  writer.writeLong(offsets[10], object.trainingDays);
}

PrimePlan _primePlanDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PrimePlan();
  object.calories = reader.readLong(offsets[0]);
  object.carbsG = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.fatG = reader.readLong(offsets[3]);
  object.id = id;
  object.phase = reader.readString(offsets[4]);
  object.phaseStartedAt = reader.readDateTimeOrNull(offsets[5]);
  object.planName = reader.readString(offsets[6]);
  object.preRefeedCalories = reader.readLongOrNull(offsets[7]);
  object.proteinG = reader.readLong(offsets[8]);
  object.stepTarget = reader.readLong(offsets[9]);
  object.trainingDays = reader.readLong(offsets[10]);
  return object;
}

P _primePlanDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _primePlanGetId(PrimePlan object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _primePlanGetLinks(PrimePlan object) {
  return [];
}

void _primePlanAttach(IsarCollection<dynamic> col, Id id, PrimePlan object) {
  object.id = id;
}

extension PrimePlanQueryWhereSort
    on QueryBuilder<PrimePlan, PrimePlan, QWhere> {
  QueryBuilder<PrimePlan, PrimePlan, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension PrimePlanQueryWhere
    on QueryBuilder<PrimePlan, PrimePlan, QWhereClause> {
  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> idBetween(
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

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> createdAtEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> createdAtNotEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PrimePlanQueryFilter
    on QueryBuilder<PrimePlan, PrimePlan, QFilterCondition> {
  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> caloriesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> caloriesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> caloriesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> caloriesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> carbsGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> carbsGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> carbsGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> carbsGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> fatGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> fatGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> fatGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> fatGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phase',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phase',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phase',
        value: '',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> phaseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phase',
        value: '',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      phaseStartedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'phaseStartedAt',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      phaseStartedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'phaseStartedAt',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      phaseStartedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phaseStartedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      phaseStartedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phaseStartedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      phaseStartedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phaseStartedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      phaseStartedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phaseStartedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> planNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      planNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planName',
        value: '',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      preRefeedCaloriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'preRefeedCalories',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      preRefeedCaloriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'preRefeedCalories',
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      preRefeedCaloriesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preRefeedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      preRefeedCaloriesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preRefeedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      preRefeedCaloriesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preRefeedCalories',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      preRefeedCaloriesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preRefeedCalories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> proteinGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> proteinGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> proteinGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinG',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> proteinGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> stepTargetEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stepTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      stepTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stepTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> stepTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stepTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> stepTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stepTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> trainingDaysEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      trainingDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition>
      trainingDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterFilterCondition> trainingDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trainingDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PrimePlanQueryObject
    on QueryBuilder<PrimePlan, PrimePlan, QFilterCondition> {}

extension PrimePlanQueryLinks
    on QueryBuilder<PrimePlan, PrimePlan, QFilterCondition> {}

extension PrimePlanQuerySortBy on QueryBuilder<PrimePlan, PrimePlan, QSortBy> {
  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsG', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByCarbsGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsG', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByFatGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPhaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPhaseStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseStartedAt', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPhaseStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseStartedAt', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByPreRefeedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preRefeedCalories', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy>
      sortByPreRefeedCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preRefeedCalories', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByProteinGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByStepTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepTarget', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByStepTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepTarget', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByTrainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDays', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> sortByTrainingDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDays', Sort.desc);
    });
  }
}

extension PrimePlanQuerySortThenBy
    on QueryBuilder<PrimePlan, PrimePlan, QSortThenBy> {
  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsG', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByCarbsGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsG', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByFatGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatG', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPhaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phase', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPhaseStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseStartedAt', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPhaseStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseStartedAt', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPlanName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPlanNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planName', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByPreRefeedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preRefeedCalories', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy>
      thenByPreRefeedCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preRefeedCalories', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByProteinGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinG', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByStepTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepTarget', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByStepTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepTarget', Sort.desc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByTrainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDays', Sort.asc);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QAfterSortBy> thenByTrainingDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDays', Sort.desc);
    });
  }
}

extension PrimePlanQueryWhereDistinct
    on QueryBuilder<PrimePlan, PrimePlan, QDistinct> {
  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calories');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByCarbsG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbsG');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByFatG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatG');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByPhase(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phase', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByPhaseStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phaseStartedAt');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByPlanName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByPreRefeedCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preRefeedCalories');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByProteinG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinG');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByStepTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stepTarget');
    });
  }

  QueryBuilder<PrimePlan, PrimePlan, QDistinct> distinctByTrainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trainingDays');
    });
  }
}

extension PrimePlanQueryProperty
    on QueryBuilder<PrimePlan, PrimePlan, QQueryProperty> {
  QueryBuilder<PrimePlan, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PrimePlan, int, QQueryOperations> caloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calories');
    });
  }

  QueryBuilder<PrimePlan, int, QQueryOperations> carbsGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbsG');
    });
  }

  QueryBuilder<PrimePlan, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PrimePlan, int, QQueryOperations> fatGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatG');
    });
  }

  QueryBuilder<PrimePlan, String, QQueryOperations> phaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phase');
    });
  }

  QueryBuilder<PrimePlan, DateTime?, QQueryOperations>
      phaseStartedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phaseStartedAt');
    });
  }

  QueryBuilder<PrimePlan, String, QQueryOperations> planNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planName');
    });
  }

  QueryBuilder<PrimePlan, int?, QQueryOperations> preRefeedCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preRefeedCalories');
    });
  }

  QueryBuilder<PrimePlan, int, QQueryOperations> proteinGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinG');
    });
  }

  QueryBuilder<PrimePlan, int, QQueryOperations> stepTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stepTarget');
    });
  }

  QueryBuilder<PrimePlan, int, QQueryOperations> trainingDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trainingDays');
    });
  }
}
