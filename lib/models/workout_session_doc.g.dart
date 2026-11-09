// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session_doc.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWorkoutSessionDocCollection on Isar {
  IsarCollection<WorkoutSessionDoc> get workoutSessionDocs => this.collection();
}

const WorkoutSessionDocSchema = CollectionSchema(
  name: r'WorkoutSessionDoc',
  id: -8010692267484114098,
  properties: {
    r'completed': PropertySchema(
      id: 0,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'dayIndex': PropertySchema(
      id: 2,
      name: r'dayIndex',
      type: IsarType.long,
    ),
    r'notes': PropertySchema(
      id: 3,
      name: r'notes',
      type: IsarType.string,
    ),
    r'perceivedExertion': PropertySchema(
      id: 4,
      name: r'perceivedExertion',
      type: IsarType.long,
    ),
    r'planId': PropertySchema(
      id: 5,
      name: r'planId',
      type: IsarType.string,
    ),
    r'progressJson': PropertySchema(
      id: 6,
      name: r'progressJson',
      type: IsarType.string,
    ),
    r'skipReason': PropertySchema(
      id: 7,
      name: r'skipReason',
      type: IsarType.string,
    ),
    r'skipped': PropertySchema(
      id: 8,
      name: r'skipped',
      type: IsarType.bool,
    ),
    r'templateSnapshotJson': PropertySchema(
      id: 9,
      name: r'templateSnapshotJson',
      type: IsarType.string,
    )
  },
  estimateSize: _workoutSessionDocEstimateSize,
  serialize: _workoutSessionDocSerialize,
  deserialize: _workoutSessionDocDeserialize,
  deserializeProp: _workoutSessionDocDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _workoutSessionDocGetId,
  getLinks: _workoutSessionDocGetLinks,
  attach: _workoutSessionDocAttach,
  version: '3.1.0+1',
);

int _workoutSessionDocEstimateSize(
  WorkoutSessionDoc object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.planId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.progressJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.skipReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.templateSnapshotJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _workoutSessionDocSerialize(
  WorkoutSessionDoc object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.completed);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeLong(offsets[2], object.dayIndex);
  writer.writeString(offsets[3], object.notes);
  writer.writeLong(offsets[4], object.perceivedExertion);
  writer.writeString(offsets[5], object.planId);
  writer.writeString(offsets[6], object.progressJson);
  writer.writeString(offsets[7], object.skipReason);
  writer.writeBool(offsets[8], object.skipped);
  writer.writeString(offsets[9], object.templateSnapshotJson);
}

WorkoutSessionDoc _workoutSessionDocDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutSessionDoc();
  object.completed = reader.readBool(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.dayIndex = reader.readLong(offsets[2]);
  object.id = id;
  object.notes = reader.readStringOrNull(offsets[3]);
  object.perceivedExertion = reader.readLongOrNull(offsets[4]);
  object.planId = reader.readStringOrNull(offsets[5]);
  object.progressJson = reader.readStringOrNull(offsets[6]);
  object.skipReason = reader.readStringOrNull(offsets[7]);
  object.skipped = reader.readBool(offsets[8]);
  object.templateSnapshotJson = reader.readStringOrNull(offsets[9]);
  return object;
}

P _workoutSessionDocDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _workoutSessionDocGetId(WorkoutSessionDoc object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workoutSessionDocGetLinks(
    WorkoutSessionDoc object) {
  return [];
}

void _workoutSessionDocAttach(
    IsarCollection<dynamic> col, Id id, WorkoutSessionDoc object) {
  object.id = id;
}

extension WorkoutSessionDocQueryWhereSort
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QWhere> {
  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension WorkoutSessionDocQueryWhere
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QWhereClause> {
  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      dateEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterWhereClause>
      dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WorkoutSessionDocQueryFilter
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QFilterCondition> {
  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completed',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dayIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dayIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dayIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      dayIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
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

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      perceivedExertionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'perceivedExertion',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      perceivedExertionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'perceivedExertion',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      perceivedExertionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perceivedExertion',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      perceivedExertionGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'perceivedExertion',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      perceivedExertionLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'perceivedExertion',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      perceivedExertionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'perceivedExertion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'planId',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'planId',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planId',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      planIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planId',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'progressJson',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'progressJson',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progressJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progressJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progressJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progressJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'progressJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'progressJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'progressJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'progressJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progressJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      progressJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'progressJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'skipReason',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'skipReason',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skipReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skipReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skipReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skipReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skipReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skipReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skipReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skipReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skipReason',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skipReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skipReason',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      skippedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skipped',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'templateSnapshotJson',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'templateSnapshotJson',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateSnapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'templateSnapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'templateSnapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'templateSnapshotJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'templateSnapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'templateSnapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'templateSnapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'templateSnapshotJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateSnapshotJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterFilterCondition>
      templateSnapshotJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'templateSnapshotJson',
        value: '',
      ));
    });
  }
}

extension WorkoutSessionDocQueryObject
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QFilterCondition> {}

extension WorkoutSessionDocQueryLinks
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QFilterCondition> {}

extension WorkoutSessionDocQuerySortBy
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QSortBy> {
  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByDayIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByPerceivedExertion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perceivedExertion', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByPerceivedExertionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perceivedExertion', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByProgressJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByProgressJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortBySkipReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipReason', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortBySkipReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipReason', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortBySkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortBySkippedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByTemplateSnapshotJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshotJson', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      sortByTemplateSnapshotJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshotJson', Sort.desc);
    });
  }
}

extension WorkoutSessionDocQuerySortThenBy
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QSortThenBy> {
  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByDayIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByPerceivedExertion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perceivedExertion', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByPerceivedExertionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perceivedExertion', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByPlanId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByPlanIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planId', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByProgressJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByProgressJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenBySkipReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipReason', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenBySkipReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipReason', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenBySkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenBySkippedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipped', Sort.desc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByTemplateSnapshotJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshotJson', Sort.asc);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QAfterSortBy>
      thenByTemplateSnapshotJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateSnapshotJson', Sort.desc);
    });
  }
}

extension WorkoutSessionDocQueryWhereDistinct
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct> {
  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayIndex');
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByPerceivedExertion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'perceivedExertion');
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByPlanId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByProgressJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctBySkipReason({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skipReason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctBySkipped() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skipped');
    });
  }

  QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QDistinct>
      distinctByTemplateSnapshotJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateSnapshotJson',
          caseSensitive: caseSensitive);
    });
  }
}

extension WorkoutSessionDocQueryProperty
    on QueryBuilder<WorkoutSessionDoc, WorkoutSessionDoc, QQueryProperty> {
  QueryBuilder<WorkoutSessionDoc, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WorkoutSessionDoc, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<WorkoutSessionDoc, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<WorkoutSessionDoc, int, QQueryOperations> dayIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayIndex');
    });
  }

  QueryBuilder<WorkoutSessionDoc, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<WorkoutSessionDoc, int?, QQueryOperations>
      perceivedExertionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perceivedExertion');
    });
  }

  QueryBuilder<WorkoutSessionDoc, String?, QQueryOperations> planIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planId');
    });
  }

  QueryBuilder<WorkoutSessionDoc, String?, QQueryOperations>
      progressJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressJson');
    });
  }

  QueryBuilder<WorkoutSessionDoc, String?, QQueryOperations>
      skipReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skipReason');
    });
  }

  QueryBuilder<WorkoutSessionDoc, bool, QQueryOperations> skippedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skipped');
    });
  }

  QueryBuilder<WorkoutSessionDoc, String?, QQueryOperations>
      templateSnapshotJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateSnapshotJson');
    });
  }
}
