// Frozen base-revision meal schema for an isolated upgrade test, not production code.
// ignore_for_file: non_constant_identifier_names, unnecessary_cast
import 'package:isar/isar.dart';
class LegacyMealLog {
  Id id = Isar.autoIncrement;
  late DateTime ts;
  late String mealType;
  late int proteinG;
  late int carbsG;
  late int fatG;
  String? description;
  int get calories => proteinG * 4 + carbsG * 4 + fatG * 9;
}
const legacyMealLogSchema = CollectionSchema(
  name: r'MealLog',
  id: 3637844514022358638,
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
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'fatG': PropertySchema(
      id: 3,
      name: r'fatG',
      type: IsarType.long,
    ),
    r'mealType': PropertySchema(
      id: 4,
      name: r'mealType',
      type: IsarType.string,
    ),
    r'proteinG': PropertySchema(
      id: 5,
      name: r'proteinG',
      type: IsarType.long,
    ),
    r'ts': PropertySchema(
      id: 6,
      name: r'ts',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _mealLogEstimateSize,
  serialize: _mealLogSerialize,
  deserialize: _mealLogDeserialize,
  deserializeProp: _mealLogDeserializeProp,
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
  getId: _mealLogGetId,
  getLinks: _mealLogGetLinks,
  attach: _mealLogAttach,
  version: '3.1.0+1',
);

int _mealLogEstimateSize(
  LegacyMealLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mealType.length * 3;
  return bytesCount;
}

void _mealLogSerialize(
  LegacyMealLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.calories);
  writer.writeLong(offsets[1], object.carbsG);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.fatG);
  writer.writeString(offsets[4], object.mealType);
  writer.writeLong(offsets[5], object.proteinG);
  writer.writeDateTime(offsets[6], object.ts);
}

LegacyMealLog _mealLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LegacyMealLog();
  object.carbsG = reader.readLong(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.fatG = reader.readLong(offsets[3]);
  object.id = id;
  object.mealType = reader.readString(offsets[4]);
  object.proteinG = reader.readLong(offsets[5]);
  object.ts = reader.readDateTime(offsets[6]);
  return object;
}

P _mealLogDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mealLogGetId(LegacyMealLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mealLogGetLinks(LegacyMealLog object) {
  return [];
}

void _mealLogAttach(IsarCollection<dynamic> col, Id id, LegacyMealLog object) {
  object.id = id;
}
