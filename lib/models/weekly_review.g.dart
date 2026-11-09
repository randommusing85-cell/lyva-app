// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_review.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWeeklyReviewCollection on Isar {
  IsarCollection<WeeklyReview> get weeklyReviews => this.collection();
}

const WeeklyReviewSchema = CollectionSchema(
  name: r'WeeklyReview',
  id: 1740939263748820166,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'decidedAt': PropertySchema(
      id: 1,
      name: r'decidedAt',
      type: IsarType.dateTime,
    ),
    r'decisionToken': PropertySchema(
      id: 2,
      name: r'decisionToken',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 3,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'sourceRevision': PropertySchema(
      id: 4,
      name: r'sourceRevision',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.string,
    ),
    r'weekStart': PropertySchema(
      id: 6,
      name: r'weekStart',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _weeklyReviewEstimateSize,
  serialize: _weeklyReviewSerialize,
  deserialize: _weeklyReviewDeserialize,
  deserializeProp: _weeklyReviewDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _weeklyReviewGetId,
  getLinks: _weeklyReviewGetLinks,
  attach: _weeklyReviewAttach,
  version: '3.1.0+1',
);

int _weeklyReviewEstimateSize(
  WeeklyReview object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.decisionToken.length * 3;
  bytesCount += 3 + object.sourceRevision.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _weeklyReviewSerialize(
  WeeklyReview object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.decidedAt);
  writer.writeString(offsets[2], object.decisionToken);
  writer.writeLong(offsets[3], object.schemaVersion);
  writer.writeString(offsets[4], object.sourceRevision);
  writer.writeString(offsets[5], object.status);
  writer.writeDateTime(offsets[6], object.weekStart);
}

WeeklyReview _weeklyReviewDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WeeklyReview();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.decidedAt = reader.readDateTimeOrNull(offsets[1]);
  object.decisionToken = reader.readString(offsets[2]);
  object.id = id;
  object.schemaVersion = reader.readLong(offsets[3]);
  object.sourceRevision = reader.readString(offsets[4]);
  object.status = reader.readString(offsets[5]);
  object.weekStart = reader.readDateTime(offsets[6]);
  return object;
}

P _weeklyReviewDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _weeklyReviewGetId(WeeklyReview object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _weeklyReviewGetLinks(WeeklyReview object) {
  return [];
}

void _weeklyReviewAttach(
    IsarCollection<dynamic> col, Id id, WeeklyReview object) {
  object.id = id;
}

extension WeeklyReviewQueryWhereSort
    on QueryBuilder<WeeklyReview, WeeklyReview, QWhere> {
  QueryBuilder<WeeklyReview, WeeklyReview, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WeeklyReviewQueryWhere
    on QueryBuilder<WeeklyReview, WeeklyReview, QWhereClause> {
  QueryBuilder<WeeklyReview, WeeklyReview, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterWhereClause> idBetween(
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
}

extension WeeklyReviewQueryFilter
    on QueryBuilder<WeeklyReview, WeeklyReview, QFilterCondition> {
  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decidedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'decidedAt',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decidedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'decidedAt',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decidedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decidedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decidedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decidedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decidedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decidedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decidedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decidedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decisionToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decisionToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decisionToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decisionToken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'decisionToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'decisionToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'decisionToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'decisionToken',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decisionToken',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      decisionTokenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'decisionToken',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> idBetween(
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

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      schemaVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      schemaVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schemaVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceRevision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceRevision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceRevision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceRevision',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceRevision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceRevision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceRevision',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceRevision',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceRevision',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      sourceRevisionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceRevision',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      weekStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekStart',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      weekStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekStart',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      weekStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekStart',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterFilterCondition>
      weekStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WeeklyReviewQueryObject
    on QueryBuilder<WeeklyReview, WeeklyReview, QFilterCondition> {}

extension WeeklyReviewQueryLinks
    on QueryBuilder<WeeklyReview, WeeklyReview, QFilterCondition> {}

extension WeeklyReviewQuerySortBy
    on QueryBuilder<WeeklyReview, WeeklyReview, QSortBy> {
  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByDecidedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAt', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByDecidedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAt', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByDecisionToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionToken', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      sortByDecisionTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionToken', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      sortBySourceRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRevision', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      sortBySourceRevisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRevision', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByWeekStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekStart', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> sortByWeekStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekStart', Sort.desc);
    });
  }
}

extension WeeklyReviewQuerySortThenBy
    on QueryBuilder<WeeklyReview, WeeklyReview, QSortThenBy> {
  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByDecidedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAt', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByDecidedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAt', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByDecisionToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionToken', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      thenByDecisionTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decisionToken', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      thenBySourceRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRevision', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy>
      thenBySourceRevisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRevision', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByWeekStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekStart', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QAfterSortBy> thenByWeekStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekStart', Sort.desc);
    });
  }
}

extension WeeklyReviewQueryWhereDistinct
    on QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> {
  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> distinctByDecidedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decidedAt');
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> distinctByDecisionToken(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decisionToken',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct>
      distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> distinctBySourceRevision(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceRevision',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WeeklyReview, WeeklyReview, QDistinct> distinctByWeekStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekStart');
    });
  }
}

extension WeeklyReviewQueryProperty
    on QueryBuilder<WeeklyReview, WeeklyReview, QQueryProperty> {
  QueryBuilder<WeeklyReview, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WeeklyReview, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<WeeklyReview, DateTime?, QQueryOperations> decidedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decidedAt');
    });
  }

  QueryBuilder<WeeklyReview, String, QQueryOperations> decisionTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decisionToken');
    });
  }

  QueryBuilder<WeeklyReview, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<WeeklyReview, String, QQueryOperations>
      sourceRevisionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceRevision');
    });
  }

  QueryBuilder<WeeklyReview, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<WeeklyReview, DateTime, QQueryOperations> weekStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekStart');
    });
  }
}
