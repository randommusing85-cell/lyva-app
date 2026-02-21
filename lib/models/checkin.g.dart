// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCheckInCollection on Isar {
  IsarCollection<CheckIn> get checkIns => this.collection();
}

const CheckInSchema = CollectionSchema(
  name: r'CheckIn',
  id: 8269192239726548867,
  properties: {
    r'energyScore': PropertySchema(
      id: 0,
      name: r'energyScore',
      type: IsarType.long,
    ),
    r'moodScore': PropertySchema(
      id: 1,
      name: r'moodScore',
      type: IsarType.long,
    ),
    r'note': PropertySchema(
      id: 2,
      name: r'note',
      type: IsarType.string,
    ),
    r'stepsToday': PropertySchema(
      id: 3,
      name: r'stepsToday',
      type: IsarType.long,
    ),
    r'ts': PropertySchema(
      id: 4,
      name: r'ts',
      type: IsarType.dateTime,
    ),
    r'waistCm': PropertySchema(
      id: 5,
      name: r'waistCm',
      type: IsarType.double,
    ),
    r'weightKg': PropertySchema(
      id: 6,
      name: r'weightKg',
      type: IsarType.double,
    )
  },
  estimateSize: _checkInEstimateSize,
  serialize: _checkInSerialize,
  deserialize: _checkInDeserialize,
  deserializeProp: _checkInDeserializeProp,
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
  getId: _checkInGetId,
  getLinks: _checkInGetLinks,
  attach: _checkInAttach,
  version: '3.1.0+1',
);

int _checkInEstimateSize(
  CheckIn object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _checkInSerialize(
  CheckIn object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.energyScore);
  writer.writeLong(offsets[1], object.moodScore);
  writer.writeString(offsets[2], object.note);
  writer.writeLong(offsets[3], object.stepsToday);
  writer.writeDateTime(offsets[4], object.ts);
  writer.writeDouble(offsets[5], object.waistCm);
  writer.writeDouble(offsets[6], object.weightKg);
}

CheckIn _checkInDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CheckIn();
  object.energyScore = reader.readLongOrNull(offsets[0]);
  object.id = id;
  object.moodScore = reader.readLongOrNull(offsets[1]);
  object.note = reader.readStringOrNull(offsets[2]);
  object.stepsToday = reader.readLong(offsets[3]);
  object.ts = reader.readDateTime(offsets[4]);
  object.waistCm = reader.readDouble(offsets[5]);
  object.weightKg = reader.readDouble(offsets[6]);
  return object;
}

P _checkInDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _checkInGetId(CheckIn object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _checkInGetLinks(CheckIn object) {
  return [];
}

void _checkInAttach(IsarCollection<dynamic> col, Id id, CheckIn object) {
  object.id = id;
}

extension CheckInQueryWhereSort on QueryBuilder<CheckIn, CheckIn, QWhere> {
  QueryBuilder<CheckIn, CheckIn, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterWhere> anyTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ts'),
      );
    });
  }
}

extension CheckInQueryWhere on QueryBuilder<CheckIn, CheckIn, QWhereClause> {
  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> idBetween(
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

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> tsEqualTo(DateTime ts) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ts',
        value: [ts],
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> tsNotEqualTo(DateTime ts) {
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

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> tsGreaterThan(
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

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> tsLessThan(
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

  QueryBuilder<CheckIn, CheckIn, QAfterWhereClause> tsBetween(
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

extension CheckInQueryFilter
    on QueryBuilder<CheckIn, CheckIn, QFilterCondition> {
  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> energyScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'energyScore',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> energyScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'energyScore',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> energyScoreEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'energyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> energyScoreGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'energyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> energyScoreLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'energyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> energyScoreBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'energyScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> moodScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'moodScore',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> moodScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'moodScore',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> moodScoreEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moodScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> moodScoreGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'moodScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> moodScoreLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'moodScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> moodScoreBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'moodScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> stepsTodayEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stepsToday',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> stepsTodayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stepsToday',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> stepsTodayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stepsToday',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> stepsTodayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stepsToday',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> tsEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> tsGreaterThan(
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

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> tsLessThan(
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

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> tsBetween(
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

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> waistCmEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waistCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> waistCmGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waistCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> waistCmLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waistCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> waistCmBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waistCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> weightKgEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> weightKgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> weightKgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterFilterCondition> weightKgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weightKg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CheckInQueryObject
    on QueryBuilder<CheckIn, CheckIn, QFilterCondition> {}

extension CheckInQueryLinks
    on QueryBuilder<CheckIn, CheckIn, QFilterCondition> {}

extension CheckInQuerySortBy on QueryBuilder<CheckIn, CheckIn, QSortBy> {
  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByEnergyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByEnergyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByStepsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsToday', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByStepsTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsToday', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByWaistCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByWaistCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> sortByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension CheckInQuerySortThenBy
    on QueryBuilder<CheckIn, CheckIn, QSortThenBy> {
  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByEnergyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByEnergyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyScore', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByStepsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsToday', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByStepsTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepsToday', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByWaistCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByWaistCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.desc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QAfterSortBy> thenByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension CheckInQueryWhereDistinct
    on QueryBuilder<CheckIn, CheckIn, QDistinct> {
  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByEnergyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'energyScore');
    });
  }

  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodScore');
    });
  }

  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByStepsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stepsToday');
    });
  }

  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ts');
    });
  }

  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByWaistCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waistCm');
    });
  }

  QueryBuilder<CheckIn, CheckIn, QDistinct> distinctByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightKg');
    });
  }
}

extension CheckInQueryProperty
    on QueryBuilder<CheckIn, CheckIn, QQueryProperty> {
  QueryBuilder<CheckIn, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CheckIn, int?, QQueryOperations> energyScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'energyScore');
    });
  }

  QueryBuilder<CheckIn, int?, QQueryOperations> moodScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodScore');
    });
  }

  QueryBuilder<CheckIn, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<CheckIn, int, QQueryOperations> stepsTodayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stepsToday');
    });
  }

  QueryBuilder<CheckIn, DateTime, QQueryOperations> tsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ts');
    });
  }

  QueryBuilder<CheckIn, double, QQueryOperations> waistCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waistCm');
    });
  }

  QueryBuilder<CheckIn, double, QQueryOperations> weightKgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightKg');
    });
  }
}
