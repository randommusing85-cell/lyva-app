// Frozen base schema for an isolated nullable-measurement upgrade test.
// ignore_for_file: non_constant_identifier_names, unnecessary_cast
import 'package:isar/isar.dart';
class LegacyCheckIn {
  Id id = Isar.autoIncrement;
  late DateTime ts;
  late double weightKg;
  late double waistCm;
  late int stepsToday;
  String? note;
  int? moodScore;
  int? energyScore;
}
const legacyCheckInSchema = CollectionSchema(
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
  LegacyCheckIn object,
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
  LegacyCheckIn object,
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

LegacyCheckIn _checkInDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LegacyCheckIn();
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

Id _checkInGetId(LegacyCheckIn object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _checkInGetLinks(LegacyCheckIn object) {
  return [];
}

void _checkInAttach(IsarCollection<dynamic> col, Id id, LegacyCheckIn object) {
  object.id = id;
}
