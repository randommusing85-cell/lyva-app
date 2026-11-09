// Frozen pre-LYVA-07 storage schema for a real upgrade/reopen regression test.
// Serializer/schema copied from base revision f36c9065; not production code.
// ignore_for_file: non_constant_identifier_names, unnecessary_cast
import 'package:isar/isar.dart';

class LegacyWorkoutSession {
  Id id = Isar.autoIncrement;
  late DateTime date;
  late int dayIndex;
  late bool completed;
  bool skipped = false;
  String? skipReason;
  String? notes;
  String? planId;
}

const legacyWorkoutSessionSchema = CollectionSchema(
  name: r'WorkoutSessionDoc',
  id: -8010692267484114098,
  properties: {
    r'completed': PropertySchema(
      id: 0,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'date': PropertySchema(id: 1, name: r'date', type: IsarType.dateTime),
    r'dayIndex': PropertySchema(id: 2, name: r'dayIndex', type: IsarType.long),
    r'notes': PropertySchema(id: 3, name: r'notes', type: IsarType.string),
    r'planId': PropertySchema(id: 4, name: r'planId', type: IsarType.string),
    r'skipReason': PropertySchema(
      id: 5,
      name: r'skipReason',
      type: IsarType.string,
    ),
    r'skipped': PropertySchema(id: 6, name: r'skipped', type: IsarType.bool),
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _workoutSessionDocGetId,
  getLinks: _workoutSessionDocGetLinks,
  attach: _workoutSessionDocAttach,
  version: '3.1.0+1',
);

int _workoutSessionDocEstimateSize(
  LegacyWorkoutSession object,
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
    final value = object.skipReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _workoutSessionDocSerialize(
  LegacyWorkoutSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.completed);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeLong(offsets[2], object.dayIndex);
  writer.writeString(offsets[3], object.notes);
  writer.writeString(offsets[4], object.planId);
  writer.writeString(offsets[5], object.skipReason);
  writer.writeBool(offsets[6], object.skipped);
}

LegacyWorkoutSession _workoutSessionDocDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LegacyWorkoutSession();
  object.completed = reader.readBool(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.dayIndex = reader.readLong(offsets[2]);
  object.id = id;
  object.notes = reader.readStringOrNull(offsets[3]);
  object.planId = reader.readStringOrNull(offsets[4]);
  object.skipReason = reader.readStringOrNull(offsets[5]);
  object.skipped = reader.readBool(offsets[6]);
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
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _workoutSessionDocGetId(LegacyWorkoutSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workoutSessionDocGetLinks(
  LegacyWorkoutSession object,
) {
  return [];
}

void _workoutSessionDocAttach(
  IsarCollection<dynamic> col,
  Id id,
  LegacyWorkoutSession object,
) {
  object.id = id;
}
