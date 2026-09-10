// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, SemesterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstWeekMondayMeta = const VerificationMeta(
    'firstWeekMonday',
  );
  @override
  late final GeneratedColumn<DateTime> firstWeekMonday =
      GeneratedColumn<DateTime>(
        'first_week_monday',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  @override
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, firstWeekMonday, totalWeeks];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SemesterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('first_week_monday')) {
      context.handle(
        _firstWeekMondayMeta,
        firstWeekMonday.isAcceptableOrUnknown(
          data['first_week_monday']!,
          _firstWeekMondayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstWeekMondayMeta);
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    } else if (isInserting) {
      context.missing(_totalWeeksMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SemesterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemesterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      firstWeekMonday: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_week_monday'],
      )!,
      totalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weeks'],
      )!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }
}

class SemesterRow extends DataClass implements Insertable<SemesterRow> {
  final String id;
  final String name;
  final DateTime firstWeekMonday;
  final int totalWeeks;
  const SemesterRow({
    required this.id,
    required this.name,
    required this.firstWeekMonday,
    required this.totalWeeks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['first_week_monday'] = Variable<DateTime>(firstWeekMonday);
    map['total_weeks'] = Variable<int>(totalWeeks);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      name: Value(name),
      firstWeekMonday: Value(firstWeekMonday),
      totalWeeks: Value(totalWeeks),
    );
  }

  factory SemesterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemesterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      firstWeekMonday: serializer.fromJson<DateTime>(json['firstWeekMonday']),
      totalWeeks: serializer.fromJson<int>(json['totalWeeks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'firstWeekMonday': serializer.toJson<DateTime>(firstWeekMonday),
      'totalWeeks': serializer.toJson<int>(totalWeeks),
    };
  }

  SemesterRow copyWith({
    String? id,
    String? name,
    DateTime? firstWeekMonday,
    int? totalWeeks,
  }) => SemesterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    firstWeekMonday: firstWeekMonday ?? this.firstWeekMonday,
    totalWeeks: totalWeeks ?? this.totalWeeks,
  );
  SemesterRow copyWithCompanion(SemestersCompanion data) {
    return SemesterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      firstWeekMonday: data.firstWeekMonday.present
          ? data.firstWeekMonday.value
          : this.firstWeekMonday,
      totalWeeks: data.totalWeeks.present
          ? data.totalWeeks.value
          : this.totalWeeks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemesterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firstWeekMonday: $firstWeekMonday, ')
          ..write('totalWeeks: $totalWeeks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, firstWeekMonday, totalWeeks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemesterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.firstWeekMonday == this.firstWeekMonday &&
          other.totalWeeks == this.totalWeeks);
}

class SemestersCompanion extends UpdateCompanion<SemesterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> firstWeekMonday;
  final Value<int> totalWeeks;
  final Value<int> rowid;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.firstWeekMonday = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SemestersCompanion.insert({
    required String id,
    required String name,
    required DateTime firstWeekMonday,
    required int totalWeeks,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       firstWeekMonday = Value(firstWeekMonday),
       totalWeeks = Value(totalWeeks);
  static Insertable<SemesterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? firstWeekMonday,
    Expression<int>? totalWeeks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (firstWeekMonday != null) 'first_week_monday': firstWeekMonday,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SemestersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? firstWeekMonday,
    Value<int>? totalWeeks,
    Value<int>? rowid,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      firstWeekMonday: firstWeekMonday ?? this.firstWeekMonday,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstWeekMonday.present) {
      map['first_week_monday'] = Variable<DateTime>(firstWeekMonday.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firstWeekMonday: $firstWeekMonday, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseEntriesTable extends CourseEntries
    with TableInfo<$CourseEntriesTable, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _classroomMeta = const VerificationMeta(
    'classroom',
  );
  @override
  late final GeneratedColumn<String> classroom = GeneratedColumn<String>(
    'classroom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startSectionMeta = const VerificationMeta(
    'startSection',
  );
  @override
  late final GeneratedColumn<int> startSection = GeneratedColumn<int>(
    'start_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endSectionMeta = const VerificationMeta(
    'endSection',
  );
  @override
  late final GeneratedColumn<int> endSection = GeneratedColumn<int>(
    'end_section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weeksJsonMeta = const VerificationMeta(
    'weeksJson',
  );
  @override
  late final GeneratedColumn<String> weeksJson = GeneratedColumn<String>(
    'weeks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<String> semesterId = GeneratedColumn<String>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<int> colorKey = GeneratedColumn<int>(
    'color_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    teacher,
    classroom,
    weekday,
    startSection,
    endSection,
    startTime,
    endTime,
    weeksJson,
    semesterId,
    colorKey,
    note,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('classroom')) {
      context.handle(
        _classroomMeta,
        classroom.isAcceptableOrUnknown(data['classroom']!, _classroomMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_section')) {
      context.handle(
        _startSectionMeta,
        startSection.isAcceptableOrUnknown(
          data['start_section']!,
          _startSectionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startSectionMeta);
    }
    if (data.containsKey('end_section')) {
      context.handle(
        _endSectionMeta,
        endSection.isAcceptableOrUnknown(data['end_section']!, _endSectionMeta),
      );
    } else if (isInserting) {
      context.missing(_endSectionMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('weeks_json')) {
      context.handle(
        _weeksJsonMeta,
        weeksJson.isAcceptableOrUnknown(data['weeks_json']!, _weeksJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_weeksJsonMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_colorKeyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      )!,
      classroom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_section'],
      )!,
      endSection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_section'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      weeksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weeks_json'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_id'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_key'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $CourseEntriesTable createAlias(String alias) {
    return $CourseEntriesTable(attachedDatabase, alias);
  }
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final String id;
  final String name;
  final String teacher;
  final String classroom;
  final int weekday;
  final int startSection;
  final int endSection;
  final String? startTime;
  final String? endTime;
  final String weeksJson;
  final String semesterId;
  final int colorKey;
  final String note;
  final String source;
  const CourseRow({
    required this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    this.startTime,
    this.endTime,
    required this.weeksJson,
    required this.semesterId,
    required this.colorKey,
    required this.note,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['teacher'] = Variable<String>(teacher);
    map['classroom'] = Variable<String>(classroom);
    map['weekday'] = Variable<int>(weekday);
    map['start_section'] = Variable<int>(startSection);
    map['end_section'] = Variable<int>(endSection);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['weeks_json'] = Variable<String>(weeksJson);
    map['semester_id'] = Variable<String>(semesterId);
    map['color_key'] = Variable<int>(colorKey);
    map['note'] = Variable<String>(note);
    map['source'] = Variable<String>(source);
    return map;
  }

  CourseEntriesCompanion toCompanion(bool nullToAbsent) {
    return CourseEntriesCompanion(
      id: Value(id),
      name: Value(name),
      teacher: Value(teacher),
      classroom: Value(classroom),
      weekday: Value(weekday),
      startSection: Value(startSection),
      endSection: Value(endSection),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      weeksJson: Value(weeksJson),
      semesterId: Value(semesterId),
      colorKey: Value(colorKey),
      note: Value(note),
      source: Value(source),
    );
  }

  factory CourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      teacher: serializer.fromJson<String>(json['teacher']),
      classroom: serializer.fromJson<String>(json['classroom']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startSection: serializer.fromJson<int>(json['startSection']),
      endSection: serializer.fromJson<int>(json['endSection']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      weeksJson: serializer.fromJson<String>(json['weeksJson']),
      semesterId: serializer.fromJson<String>(json['semesterId']),
      colorKey: serializer.fromJson<int>(json['colorKey']),
      note: serializer.fromJson<String>(json['note']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'teacher': serializer.toJson<String>(teacher),
      'classroom': serializer.toJson<String>(classroom),
      'weekday': serializer.toJson<int>(weekday),
      'startSection': serializer.toJson<int>(startSection),
      'endSection': serializer.toJson<int>(endSection),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'weeksJson': serializer.toJson<String>(weeksJson),
      'semesterId': serializer.toJson<String>(semesterId),
      'colorKey': serializer.toJson<int>(colorKey),
      'note': serializer.toJson<String>(note),
      'source': serializer.toJson<String>(source),
    };
  }

  CourseRow copyWith({
    String? id,
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startSection,
    int? endSection,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    String? weeksJson,
    String? semesterId,
    int? colorKey,
    String? note,
    String? source,
  }) => CourseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    classroom: classroom ?? this.classroom,
    weekday: weekday ?? this.weekday,
    startSection: startSection ?? this.startSection,
    endSection: endSection ?? this.endSection,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    weeksJson: weeksJson ?? this.weeksJson,
    semesterId: semesterId ?? this.semesterId,
    colorKey: colorKey ?? this.colorKey,
    note: note ?? this.note,
    source: source ?? this.source,
  );
  CourseRow copyWithCompanion(CourseEntriesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      classroom: data.classroom.present ? data.classroom.value : this.classroom,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startSection: data.startSection.present
          ? data.startSection.value
          : this.startSection,
      endSection: data.endSection.present
          ? data.endSection.value
          : this.endSection,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      weeksJson: data.weeksJson.present ? data.weeksJson.value : this.weeksJson,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('classroom: $classroom, ')
          ..write('weekday: $weekday, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('weeksJson: $weeksJson, ')
          ..write('semesterId: $semesterId, ')
          ..write('colorKey: $colorKey, ')
          ..write('note: $note, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    teacher,
    classroom,
    weekday,
    startSection,
    endSection,
    startTime,
    endTime,
    weeksJson,
    semesterId,
    colorKey,
    note,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.teacher == this.teacher &&
          other.classroom == this.classroom &&
          other.weekday == this.weekday &&
          other.startSection == this.startSection &&
          other.endSection == this.endSection &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.weeksJson == this.weeksJson &&
          other.semesterId == this.semesterId &&
          other.colorKey == this.colorKey &&
          other.note == this.note &&
          other.source == this.source);
}

class CourseEntriesCompanion extends UpdateCompanion<CourseRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> teacher;
  final Value<String> classroom;
  final Value<int> weekday;
  final Value<int> startSection;
  final Value<int> endSection;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String> weeksJson;
  final Value<String> semesterId;
  final Value<int> colorKey;
  final Value<String> note;
  final Value<String> source;
  final Value<int> rowid;
  const CourseEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.teacher = const Value.absent(),
    this.classroom = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startSection = const Value.absent(),
    this.endSection = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.weeksJson = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseEntriesCompanion.insert({
    required String id,
    required String name,
    this.teacher = const Value.absent(),
    this.classroom = const Value.absent(),
    required int weekday,
    required int startSection,
    required int endSection,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    required String weeksJson,
    required String semesterId,
    required int colorKey,
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       weekday = Value(weekday),
       startSection = Value(startSection),
       endSection = Value(endSection),
       weeksJson = Value(weeksJson),
       semesterId = Value(semesterId),
       colorKey = Value(colorKey);
  static Insertable<CourseRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? teacher,
    Expression<String>? classroom,
    Expression<int>? weekday,
    Expression<int>? startSection,
    Expression<int>? endSection,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? weeksJson,
    Expression<String>? semesterId,
    Expression<int>? colorKey,
    Expression<String>? note,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (teacher != null) 'teacher': teacher,
      if (classroom != null) 'classroom': classroom,
      if (weekday != null) 'weekday': weekday,
      if (startSection != null) 'start_section': startSection,
      if (endSection != null) 'end_section': endSection,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (weeksJson != null) 'weeks_json': weeksJson,
      if (semesterId != null) 'semester_id': semesterId,
      if (colorKey != null) 'color_key': colorKey,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? teacher,
    Value<String>? classroom,
    Value<int>? weekday,
    Value<int>? startSection,
    Value<int>? endSection,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String>? weeksJson,
    Value<String>? semesterId,
    Value<int>? colorKey,
    Value<String>? note,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return CourseEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weeksJson: weeksJson ?? this.weeksJson,
      semesterId: semesterId ?? this.semesterId,
      colorKey: colorKey ?? this.colorKey,
      note: note ?? this.note,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (classroom.present) {
      map['classroom'] = Variable<String>(classroom.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startSection.present) {
      map['start_section'] = Variable<int>(startSection.value);
    }
    if (endSection.present) {
      map['end_section'] = Variable<int>(endSection.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (weeksJson.present) {
      map['weeks_json'] = Variable<String>(weeksJson.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<String>(semesterId.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<int>(colorKey.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('classroom: $classroom, ')
          ..write('weekday: $weekday, ')
          ..write('startSection: $startSection, ')
          ..write('endSection: $endSection, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('weeksJson: $weeksJson, ')
          ..write('semesterId: $semesterId, ')
          ..write('colorKey: $colorKey, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionTimeEntriesTable extends SectionTimeEntries
    with TableInfo<$SectionTimeEntriesTable, SectionTimeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionTimeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<int> section = GeneratedColumn<int>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [section, startTime, endTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_times';
  @override
  VerificationContext validateIntegrity(
    Insertable<SectionTimeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {section};
  @override
  SectionTimeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionTimeRow(
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
    );
  }

  @override
  $SectionTimeEntriesTable createAlias(String alias) {
    return $SectionTimeEntriesTable(attachedDatabase, alias);
  }
}

class SectionTimeRow extends DataClass implements Insertable<SectionTimeRow> {
  final int section;
  final String startTime;
  final String endTime;
  const SectionTimeRow({
    required this.section,
    required this.startTime,
    required this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section'] = Variable<int>(section);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    return map;
  }

  SectionTimeEntriesCompanion toCompanion(bool nullToAbsent) {
    return SectionTimeEntriesCompanion(
      section: Value(section),
      startTime: Value(startTime),
      endTime: Value(endTime),
    );
  }

  factory SectionTimeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionTimeRow(
      section: serializer.fromJson<int>(json['section']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'section': serializer.toJson<int>(section),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
    };
  }

  SectionTimeRow copyWith({int? section, String? startTime, String? endTime}) =>
      SectionTimeRow(
        section: section ?? this.section,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );
  SectionTimeRow copyWithCompanion(SectionTimeEntriesCompanion data) {
    return SectionTimeRow(
      section: data.section.present ? data.section.value : this.section,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionTimeRow(')
          ..write('section: $section, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(section, startTime, endTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionTimeRow &&
          other.section == this.section &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class SectionTimeEntriesCompanion extends UpdateCompanion<SectionTimeRow> {
  final Value<int> section;
  final Value<String> startTime;
  final Value<String> endTime;
  const SectionTimeEntriesCompanion({
    this.section = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
  });
  SectionTimeEntriesCompanion.insert({
    this.section = const Value.absent(),
    required String startTime,
    required String endTime,
  }) : startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<SectionTimeRow> custom({
    Expression<int>? section,
    Expression<String>? startTime,
    Expression<String>? endTime,
  }) {
    return RawValuesInsertable({
      if (section != null) 'section': section,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
    });
  }

  SectionTimeEntriesCompanion copyWith({
    Value<int>? section,
    Value<String>? startTime,
    Value<String>? endTime,
  }) {
    return SectionTimeEntriesCompanion(
      section: section ?? this.section,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (section.present) {
      map['section'] = Variable<int>(section.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionTimeEntriesCompanion(')
          ..write('section: $section, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $CourseEntriesTable courseEntries = $CourseEntriesTable(this);
  late final $SectionTimeEntriesTable sectionTimeEntries =
      $SectionTimeEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    semesters,
    courseEntries,
    sectionTimeEntries,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('courses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SemestersTableCreateCompanionBuilder = SemestersCompanion Function({
  required String id,
  required String name,
  required DateTime firstWeekMonday,
  required int totalWeeks,
  Value<int> rowid,
});
typedef $$SemestersTableUpdateCompanionBuilder = SemestersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> firstWeekMonday,
  Value<int> totalWeeks,
  Value<int> rowid,
});

final class $$SemestersTableReferences
    extends BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow> {
  $$SemestersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseEntriesTable, List<CourseRow>>
  _courseEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseEntries,
    aliasName: 'semesters__id__courses__semester_id',
  );

  $$CourseEntriesTableProcessedTableManager get courseEntriesRefs {
    final manager = $$CourseEntriesTableTableManager(
      $_db,
      $_db.courseEntries,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstWeekMonday => $composableBuilder(
    column: $table.firstWeekMonday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseEntriesRefs(
    Expression<bool> Function($$CourseEntriesTableFilterComposer f) f,
  ) {
    final $$CourseEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseEntries,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseEntriesTableFilterComposer(
            $db: $db,
            $table: $db.courseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstWeekMonday => $composableBuilder(
    column: $table.firstWeekMonday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get firstWeekMonday => $composableBuilder(
    column: $table.firstWeekMonday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => column,
  );

  Expression<T> courseEntriesRefs<T extends Object>(
    Expression<T> Function($$CourseEntriesTableAnnotationComposer a) f,
  ) {
    final $$CourseEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseEntries,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.courseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemestersTable,
          SemesterRow,
          $$SemestersTableFilterComposer,
          $$SemestersTableOrderingComposer,
          $$SemestersTableAnnotationComposer,
          $$SemestersTableCreateCompanionBuilder,
          $$SemestersTableUpdateCompanionBuilder,
          (SemesterRow, $$SemestersTableReferences),
          SemesterRow,
          PrefetchHooks Function({bool courseEntriesRefs})
        > {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> firstWeekMonday = const Value.absent(),
                Value<int> totalWeeks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion(
                id: id,
                name: name,
                firstWeekMonday: firstWeekMonday,
                totalWeeks: totalWeeks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime firstWeekMonday,
                required int totalWeeks,
                Value<int> rowid = const Value.absent(),
              }) => SemestersCompanion.insert(
                id: id,
                name: name,
                firstWeekMonday: firstWeekMonday,
                totalWeeks: totalWeeks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SemestersTable, SemesterRow>(table),
                  $$SemestersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseEntriesRefs) db.courseEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseEntriesRefs)
                    await $_getPrefetchedData<
                      SemesterRow,
                      $SemestersTable,
                      CourseRow
                    >(
                      currentTable: table,
                      referencedTable: $$SemestersTableReferences
                          ._courseEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SemestersTableReferences(
                            db,
                            table,
                            p0,
                          ).courseEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.semesterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemestersTable,
      SemesterRow,
      $$SemestersTableFilterComposer,
      $$SemestersTableOrderingComposer,
      $$SemestersTableAnnotationComposer,
      $$SemestersTableCreateCompanionBuilder,
      $$SemestersTableUpdateCompanionBuilder,
      (SemesterRow, $$SemestersTableReferences),
      SemesterRow,
      PrefetchHooks Function({bool courseEntriesRefs})
    >;
typedef $$CourseEntriesTableCreateCompanionBuilder =
    CourseEntriesCompanion Function({
      required String id,
      required String name,
      Value<String> teacher,
      Value<String> classroom,
      required int weekday,
      required int startSection,
      required int endSection,
      Value<String?> startTime,
      Value<String?> endTime,
      required String weeksJson,
      required String semesterId,
      required int colorKey,
      Value<String> note,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$CourseEntriesTableUpdateCompanionBuilder =
    CourseEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> teacher,
      Value<String> classroom,
      Value<int> weekday,
      Value<int> startSection,
      Value<int> endSection,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String> weeksJson,
      Value<String> semesterId,
      Value<int> colorKey,
      Value<String> note,
      Value<String> source,
      Value<int> rowid,
    });

final class $$CourseEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $CourseEntriesTable, CourseRow> {
  $$CourseEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('courses__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<String>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CourseEntriesTable> {
  $$CourseEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classroom => $composableBuilder(
    column: $table.classroom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeksJson => $composableBuilder(
    column: $table.weeksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseEntriesTable> {
  $$CourseEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classroom => $composableBuilder(
    column: $table.classroom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeksJson => $composableBuilder(
    column: $table.weeksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseEntriesTable> {
  $$CourseEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get classroom =>
      $composableBuilder(column: $table.classroom, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get startSection => $composableBuilder(
    column: $table.startSection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endSection => $composableBuilder(
    column: $table.endSection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get weeksJson =>
      $composableBuilder(column: $table.weeksJson, builder: (column) => column);

  GeneratedColumn<int> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseEntriesTable,
          CourseRow,
          $$CourseEntriesTableFilterComposer,
          $$CourseEntriesTableOrderingComposer,
          $$CourseEntriesTableAnnotationComposer,
          $$CourseEntriesTableCreateCompanionBuilder,
          $$CourseEntriesTableUpdateCompanionBuilder,
          (CourseRow, $$CourseEntriesTableReferences),
          CourseRow,
          PrefetchHooks Function({bool semesterId})
        > {
  $$CourseEntriesTableTableManager(_$AppDatabase db, $CourseEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> teacher = const Value.absent(),
                Value<String> classroom = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> startSection = const Value.absent(),
                Value<int> endSection = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> weeksJson = const Value.absent(),
                Value<String> semesterId = const Value.absent(),
                Value<int> colorKey = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseEntriesCompanion(
                id: id,
                name: name,
                teacher: teacher,
                classroom: classroom,
                weekday: weekday,
                startSection: startSection,
                endSection: endSection,
                startTime: startTime,
                endTime: endTime,
                weeksJson: weeksJson,
                semesterId: semesterId,
                colorKey: colorKey,
                note: note,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> teacher = const Value.absent(),
                Value<String> classroom = const Value.absent(),
                required int weekday,
                required int startSection,
                required int endSection,
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                required String weeksJson,
                required String semesterId,
                required int colorKey,
                Value<String> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseEntriesCompanion.insert(
                id: id,
                name: name,
                teacher: teacher,
                classroom: classroom,
                weekday: weekday,
                startSection: startSection,
                endSection: endSection,
                startTime: startTime,
                endTime: endTime,
                weeksJson: weeksJson,
                semesterId: semesterId,
                colorKey: colorKey,
                note: note,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseEntriesTable, CourseRow>(table),
                  $$CourseEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (semesterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.semesterId,
                        referencedTable: $$CourseEntriesTableReferences
                            ._semesterIdTable(db),
                        referencedColumn: $$CourseEntriesTableReferences
                            ._semesterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseEntriesTable,
      CourseRow,
      $$CourseEntriesTableFilterComposer,
      $$CourseEntriesTableOrderingComposer,
      $$CourseEntriesTableAnnotationComposer,
      $$CourseEntriesTableCreateCompanionBuilder,
      $$CourseEntriesTableUpdateCompanionBuilder,
      (CourseRow, $$CourseEntriesTableReferences),
      CourseRow,
      PrefetchHooks Function({bool semesterId})
    >;
typedef $$SectionTimeEntriesTableCreateCompanionBuilder =
    SectionTimeEntriesCompanion Function({
      Value<int> section,
      required String startTime,
      required String endTime,
    });
typedef $$SectionTimeEntriesTableUpdateCompanionBuilder =
    SectionTimeEntriesCompanion Function({
      Value<int> section,
      Value<String> startTime,
      Value<String> endTime,
    });

class $$SectionTimeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SectionTimeEntriesTable> {
  $$SectionTimeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SectionTimeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionTimeEntriesTable> {
  $$SectionTimeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SectionTimeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionTimeEntriesTable> {
  $$SectionTimeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);
}

class $$SectionTimeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SectionTimeEntriesTable,
          SectionTimeRow,
          $$SectionTimeEntriesTableFilterComposer,
          $$SectionTimeEntriesTableOrderingComposer,
          $$SectionTimeEntriesTableAnnotationComposer,
          $$SectionTimeEntriesTableCreateCompanionBuilder,
          $$SectionTimeEntriesTableUpdateCompanionBuilder,
          (
            SectionTimeRow,
            BaseReferences<
              _$AppDatabase,
              $SectionTimeEntriesTable,
              SectionTimeRow
            >,
          ),
          SectionTimeRow,
          PrefetchHooks Function()
        > {
  $$SectionTimeEntriesTableTableManager(
    _$AppDatabase db,
    $SectionTimeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionTimeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionTimeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionTimeEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> section = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
              }) => SectionTimeEntriesCompanion(
                section: section,
                startTime: startTime,
                endTime: endTime,
              ),
          createCompanionCallback:
              ({
                Value<int> section = const Value.absent(),
                required String startTime,
                required String endTime,
              }) => SectionTimeEntriesCompanion.insert(
                section: section,
                startTime: startTime,
                endTime: endTime,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SectionTimeEntriesTable, SectionTimeRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SectionTimeEntriesTable,
                    SectionTimeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SectionTimeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SectionTimeEntriesTable,
      SectionTimeRow,
      $$SectionTimeEntriesTableFilterComposer,
      $$SectionTimeEntriesTableOrderingComposer,
      $$SectionTimeEntriesTableAnnotationComposer,
      $$SectionTimeEntriesTableCreateCompanionBuilder,
      $$SectionTimeEntriesTableUpdateCompanionBuilder,
      (
        SectionTimeRow,
        BaseReferences<_$AppDatabase, $SectionTimeEntriesTable, SectionTimeRow>,
      ),
      SectionTimeRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$CourseEntriesTableTableManager get courseEntries =>
      $$CourseEntriesTableTableManager(_db, _db.courseEntries);
  $$SectionTimeEntriesTableTableManager get sectionTimeEntries =>
      $$SectionTimeEntriesTableTableManager(_db, _db.sectionTimeEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
