// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_message.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCoachMessageCollection on Isar {
  IsarCollection<CoachMessage> get coachMessages => this.collection();
}

const CoachMessageSchema = CollectionSchema(
  name: r'CoachMessage',
  id: -699993403758557044,
  properties: {
    r'content': PropertySchema(
      id: 0,
      name: r'content',
      type: IsarType.string,
    ),
    r'contextSnapshot': PropertySchema(
      id: 1,
      name: r'contextSnapshot',
      type: IsarType.string,
    ),
    r'isLoading': PropertySchema(
      id: 2,
      name: r'isLoading',
      type: IsarType.bool,
    ),
    r'role': PropertySchema(
      id: 3,
      name: r'role',
      type: IsarType.string,
    ),
    r'ts': PropertySchema(
      id: 4,
      name: r'ts',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _coachMessageEstimateSize,
  serialize: _coachMessageSerialize,
  deserialize: _coachMessageDeserialize,
  deserializeProp: _coachMessageDeserializeProp,
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
  getId: _coachMessageGetId,
  getLinks: _coachMessageGetLinks,
  attach: _coachMessageAttach,
  version: '3.1.0+1',
);

int _coachMessageEstimateSize(
  CoachMessage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  {
    final value = object.contextSnapshot;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.role.length * 3;
  return bytesCount;
}

void _coachMessageSerialize(
  CoachMessage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeString(offsets[1], object.contextSnapshot);
  writer.writeBool(offsets[2], object.isLoading);
  writer.writeString(offsets[3], object.role);
  writer.writeDateTime(offsets[4], object.ts);
}

CoachMessage _coachMessageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CoachMessage();
  object.content = reader.readString(offsets[0]);
  object.contextSnapshot = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.isLoading = reader.readBool(offsets[2]);
  object.role = reader.readString(offsets[3]);
  object.ts = reader.readDateTime(offsets[4]);
  return object;
}

P _coachMessageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _coachMessageGetId(CoachMessage object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _coachMessageGetLinks(CoachMessage object) {
  return [];
}

void _coachMessageAttach(
    IsarCollection<dynamic> col, Id id, CoachMessage object) {
  object.id = id;
}

extension CoachMessageQueryWhereSort
    on QueryBuilder<CoachMessage, CoachMessage, QWhere> {
  QueryBuilder<CoachMessage, CoachMessage, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhere> anyTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ts'),
      );
    });
  }
}

extension CoachMessageQueryWhere
    on QueryBuilder<CoachMessage, CoachMessage, QWhereClause> {
  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> idBetween(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> tsEqualTo(
      DateTime ts) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ts',
        value: [ts],
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> tsNotEqualTo(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> tsGreaterThan(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> tsLessThan(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterWhereClause> tsBetween(
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

extension CoachMessageQueryFilter
    on QueryBuilder<CoachMessage, CoachMessage, QFilterCondition> {
  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contextSnapshot',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contextSnapshot',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contextSnapshot',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contextSnapshot',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contextSnapshot',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contextSnapshot',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contextSnapshot',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contextSnapshot',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contextSnapshot',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contextSnapshot',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contextSnapshot',
        value: '',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      contextSnapshotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contextSnapshot',
        value: '',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      isLoadingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLoading',
        value: value,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> roleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      roleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> roleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> roleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'role',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      roleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> roleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> roleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> roleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'role',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition>
      roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> tsEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> tsGreaterThan(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> tsLessThan(
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

  QueryBuilder<CoachMessage, CoachMessage, QAfterFilterCondition> tsBetween(
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

extension CoachMessageQueryObject
    on QueryBuilder<CoachMessage, CoachMessage, QFilterCondition> {}

extension CoachMessageQueryLinks
    on QueryBuilder<CoachMessage, CoachMessage, QFilterCondition> {}

extension CoachMessageQuerySortBy
    on QueryBuilder<CoachMessage, CoachMessage, QSortBy> {
  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy>
      sortByContextSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy>
      sortByContextSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByIsLoading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoading', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByIsLoadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoading', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> sortByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }
}

extension CoachMessageQuerySortThenBy
    on QueryBuilder<CoachMessage, CoachMessage, QSortThenBy> {
  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy>
      thenByContextSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy>
      thenByContextSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextSnapshot', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByIsLoading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoading', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByIsLoadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoading', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QAfterSortBy> thenByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }
}

extension CoachMessageQueryWhereDistinct
    on QueryBuilder<CoachMessage, CoachMessage, QDistinct> {
  QueryBuilder<CoachMessage, CoachMessage, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QDistinct> distinctByContextSnapshot(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contextSnapshot',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QDistinct> distinctByIsLoading() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLoading');
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QDistinct> distinctByRole(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CoachMessage, CoachMessage, QDistinct> distinctByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ts');
    });
  }
}

extension CoachMessageQueryProperty
    on QueryBuilder<CoachMessage, CoachMessage, QQueryProperty> {
  QueryBuilder<CoachMessage, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CoachMessage, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<CoachMessage, String?, QQueryOperations>
      contextSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextSnapshot');
    });
  }

  QueryBuilder<CoachMessage, bool, QQueryOperations> isLoadingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLoading');
    });
  }

  QueryBuilder<CoachMessage, String, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<CoachMessage, DateTime, QQueryOperations> tsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ts');
    });
  }
}
