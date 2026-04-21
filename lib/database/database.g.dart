// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects
    with TableInfo<$SubjectsTable, SubjectData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, color, icon, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<SubjectData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class SubjectData extends DataClass implements Insertable<SubjectData> {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  const SubjectData(
      {required this.id,
      required this.name,
      this.color,
      this.icon,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      createdAt: Value(createdAt),
    );
  }

  factory SubjectData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SubjectData copyWith(
          {String? id,
          String? name,
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          DateTime? createdAt}) =>
      SubjectData(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        createdAt: createdAt ?? this.createdAt,
      );
  SubjectData copyWithCompanion(SubjectsCompanion data) {
    return SubjectData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, icon, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.createdAt == this.createdAt);
}

class SubjectsCompanion extends UpdateCompanion<SubjectData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<SubjectData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? color,
      Value<String?>? icon,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
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
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectNameMeta =
      const VerificationMeta('subjectName');
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
      'subject_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
      'mode', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subjectId,
        subjectName,
        startTime,
        endTime,
        durationSeconds,
        mode,
        planId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<SessionData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
          _subjectNameMeta,
          subjectName.isAcceptableOrUnknown(
              data['subject_name']!, _subjectNameMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      subjectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_name']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mode'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionData extends DataClass implements Insertable<SessionData> {
  final String id;
  final String subjectId;
  final String? subjectName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final int mode;
  final String? planId;
  final DateTime createdAt;
  const SessionData(
      {required this.id,
      required this.subjectId,
      this.subjectName,
      required this.startTime,
      required this.endTime,
      required this.durationSeconds,
      required this.mode,
      this.planId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || subjectName != null) {
      map['subject_name'] = Variable<String>(subjectName);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['mode'] = Variable<int>(mode);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<String>(planId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      subjectName: subjectName == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectName),
      startTime: Value(startTime),
      endTime: Value(endTime),
      durationSeconds: Value(durationSeconds),
      mode: Value(mode),
      planId:
          planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      createdAt: Value(createdAt),
    );
  }

  factory SessionData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionData(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      subjectName: serializer.fromJson<String?>(json['subjectName']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      mode: serializer.fromJson<int>(json['mode']),
      planId: serializer.fromJson<String?>(json['planId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'subjectName': serializer.toJson<String?>(subjectName),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'mode': serializer.toJson<int>(mode),
      'planId': serializer.toJson<String?>(planId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SessionData copyWith(
          {String? id,
          String? subjectId,
          Value<String?> subjectName = const Value.absent(),
          DateTime? startTime,
          DateTime? endTime,
          int? durationSeconds,
          int? mode,
          Value<String?> planId = const Value.absent(),
          DateTime? createdAt}) =>
      SessionData(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName.present ? subjectName.value : this.subjectName,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        mode: mode ?? this.mode,
        planId: planId.present ? planId.value : this.planId,
        createdAt: createdAt ?? this.createdAt,
      );
  SessionData copyWithCompanion(SessionsCompanion data) {
    return SessionData(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      subjectName:
          data.subjectName.present ? data.subjectName.value : this.subjectName,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      mode: data.mode.present ? data.mode.value : this.mode,
      planId: data.planId.present ? data.planId.value : this.planId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionData(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('subjectName: $subjectName, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('mode: $mode, ')
          ..write('planId: $planId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, subjectId, subjectName, startTime,
      endTime, durationSeconds, mode, planId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionData &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.subjectName == this.subjectName &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.mode == this.mode &&
          other.planId == this.planId &&
          other.createdAt == this.createdAt);
}

class SessionsCompanion extends UpdateCompanion<SessionData> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String?> subjectName;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<int> durationSeconds;
  final Value<int> mode;
  final Value<String?> planId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.mode = const Value.absent(),
    this.planId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String subjectId,
    this.subjectName = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required int mode,
    this.planId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subjectId = Value(subjectId),
        startTime = Value(startTime),
        endTime = Value(endTime),
        durationSeconds = Value(durationSeconds),
        mode = Value(mode),
        createdAt = Value(createdAt);
  static Insertable<SessionData> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? subjectName,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationSeconds,
    Expression<int>? mode,
    Expression<String>? planId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (subjectName != null) 'subject_name': subjectName,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (mode != null) 'mode': mode,
      if (planId != null) 'plan_id': planId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subjectId,
      Value<String?>? subjectName,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<int>? durationSeconds,
      Value<int>? mode,
      Value<String?>? planId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SessionsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mode: mode ?? this.mode,
      planId: planId ?? this.planId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(mode.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('subjectName: $subjectName, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('mode: $mode, ')
          ..write('planId: $planId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, PlanData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectNameMeta =
      const VerificationMeta('subjectName');
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
      'subject_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetMinutesMeta =
      const VerificationMeta('targetMinutes');
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
      'target_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
      'deadline', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _subTasksMeta =
      const VerificationMeta('subTasks');
  @override
  late final GeneratedColumn<String> subTasks = GeneratedColumn<String>(
      'sub_tasks', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedMinutesMeta =
      const VerificationMeta('completedMinutes');
  @override
  late final GeneratedColumn<int> completedMinutes = GeneratedColumn<int>(
      'completed_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        subjectId,
        subjectName,
        targetMinutes,
        deadline,
        priority,
        status,
        subTasks,
        completedMinutes,
        createdAt,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(Insertable<PlanData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
          _subjectNameMeta,
          subjectName.isAcceptableOrUnknown(
              data['subject_name']!, _subjectNameMeta));
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
          _targetMinutesMeta,
          targetMinutes.isAcceptableOrUnknown(
              data['target_minutes']!, _targetMinutesMeta));
    } else if (isInserting) {
      context.missing(_targetMinutesMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sub_tasks')) {
      context.handle(_subTasksMeta,
          subTasks.isAcceptableOrUnknown(data['sub_tasks']!, _subTasksMeta));
    } else if (isInserting) {
      context.missing(_subTasksMeta);
    }
    if (data.containsKey('completed_minutes')) {
      context.handle(
          _completedMinutesMeta,
          completedMinutes.isAcceptableOrUnknown(
              data['completed_minutes']!, _completedMinutesMeta));
    } else if (isInserting) {
      context.missing(_completedMinutesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      subjectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_name']),
      targetMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_minutes'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deadline']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      subTasks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sub_tasks'])!,
      completedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_minutes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class PlanData extends DataClass implements Insertable<PlanData> {
  final String id;
  final String title;
  final String? description;
  final String subjectId;
  final String? subjectName;
  final int targetMinutes;
  final DateTime? deadline;
  final int priority;
  final int status;
  final String subTasks;
  final int completedMinutes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  const PlanData(
      {required this.id,
      required this.title,
      this.description,
      required this.subjectId,
      this.subjectName,
      required this.targetMinutes,
      this.deadline,
      required this.priority,
      required this.status,
      required this.subTasks,
      required this.completedMinutes,
      required this.createdAt,
      this.startedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || subjectName != null) {
      map['subject_name'] = Variable<String>(subjectName);
    }
    map['target_minutes'] = Variable<int>(targetMinutes);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<int>(status);
    map['sub_tasks'] = Variable<String>(subTasks);
    map['completed_minutes'] = Variable<int>(completedMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      subjectId: Value(subjectId),
      subjectName: subjectName == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectName),
      targetMinutes: Value(targetMinutes),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      priority: Value(priority),
      status: Value(status),
      subTasks: Value(subTasks),
      completedMinutes: Value(completedMinutes),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory PlanData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      subjectName: serializer.fromJson<String?>(json['subjectName']),
      targetMinutes: serializer.fromJson<int>(json['targetMinutes']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<int>(json['status']),
      subTasks: serializer.fromJson<String>(json['subTasks']),
      completedMinutes: serializer.fromJson<int>(json['completedMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'subjectId': serializer.toJson<String>(subjectId),
      'subjectName': serializer.toJson<String?>(subjectName),
      'targetMinutes': serializer.toJson<int>(targetMinutes),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<int>(status),
      'subTasks': serializer.toJson<String>(subTasks),
      'completedMinutes': serializer.toJson<int>(completedMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  PlanData copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          String? subjectId,
          Value<String?> subjectName = const Value.absent(),
          int? targetMinutes,
          Value<DateTime?> deadline = const Value.absent(),
          int? priority,
          int? status,
          String? subTasks,
          int? completedMinutes,
          DateTime? createdAt,
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent()}) =>
      PlanData(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName.present ? subjectName.value : this.subjectName,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        deadline: deadline.present ? deadline.value : this.deadline,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        subTasks: subTasks ?? this.subTasks,
        completedMinutes: completedMinutes ?? this.completedMinutes,
        createdAt: createdAt ?? this.createdAt,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  PlanData copyWithCompanion(PlansCompanion data) {
    return PlanData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      subjectName:
          data.subjectName.present ? data.subjectName.value : this.subjectName,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      subTasks: data.subTasks.present ? data.subTasks.value : this.subTasks,
      completedMinutes: data.completedMinutes.present
          ? data.completedMinutes.value
          : this.completedMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('subjectId: $subjectId, ')
          ..write('subjectName: $subjectName, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('deadline: $deadline, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('subTasks: $subTasks, ')
          ..write('completedMinutes: $completedMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      subjectId,
      subjectName,
      targetMinutes,
      deadline,
      priority,
      status,
      subTasks,
      completedMinutes,
      createdAt,
      startedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.subjectId == this.subjectId &&
          other.subjectName == this.subjectName &&
          other.targetMinutes == this.targetMinutes &&
          other.deadline == this.deadline &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.subTasks == this.subTasks &&
          other.completedMinutes == this.completedMinutes &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class PlansCompanion extends UpdateCompanion<PlanData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> subjectId;
  final Value<String?> subjectName;
  final Value<int> targetMinutes;
  final Value<DateTime?> deadline;
  final Value<int> priority;
  final Value<int> status;
  final Value<String> subTasks;
  final Value<int> completedMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.deadline = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.subTasks = const Value.absent(),
    this.completedMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String subjectId,
    this.subjectName = const Value.absent(),
    required int targetMinutes,
    this.deadline = const Value.absent(),
    required int priority,
    required int status,
    required String subTasks,
    required int completedMinutes,
    required DateTime createdAt,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        subjectId = Value(subjectId),
        targetMinutes = Value(targetMinutes),
        priority = Value(priority),
        status = Value(status),
        subTasks = Value(subTasks),
        completedMinutes = Value(completedMinutes),
        createdAt = Value(createdAt);
  static Insertable<PlanData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? subjectId,
    Expression<String>? subjectName,
    Expression<int>? targetMinutes,
    Expression<DateTime>? deadline,
    Expression<int>? priority,
    Expression<int>? status,
    Expression<String>? subTasks,
    Expression<int>? completedMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (subjectId != null) 'subject_id': subjectId,
      if (subjectName != null) 'subject_name': subjectName,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (deadline != null) 'deadline': deadline,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (subTasks != null) 'sub_tasks': subTasks,
      if (completedMinutes != null) 'completed_minutes': completedMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? subjectId,
      Value<String?>? subjectName,
      Value<int>? targetMinutes,
      Value<DateTime?>? deadline,
      Value<int>? priority,
      Value<int>? status,
      Value<String>? subTasks,
      Value<int>? completedMinutes,
      Value<DateTime>? createdAt,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? completedAt,
      Value<int>? rowid}) {
    return PlansCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      subTasks: subTasks ?? this.subTasks,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (subTasks.present) {
      map['sub_tasks'] = Variable<String>(subTasks.value);
    }
    if (completedMinutes.present) {
      map['completed_minutes'] = Variable<int>(completedMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('subjectId: $subjectId, ')
          ..write('subjectName: $subjectName, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('deadline: $deadline, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('subTasks: $subTasks, ')
          ..write('completedMinutes: $completedMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $PlansTable plans = $PlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [subjects, sessions, plans];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String name,
  Value<String?> color,
  Value<String?> icon,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> color,
  Value<String?> icon,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SubjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectsTable,
    SubjectData,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (SubjectData, BaseReferences<_$AppDatabase, $SubjectsTable, SubjectData>),
    SubjectData,
    PrefetchHooks Function()> {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion(
            id: id,
            name: name,
            color: color,
            icon: icon,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion.insert(
            id: id,
            name: name,
            color: color,
            icon: icon,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectsTable,
    SubjectData,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (SubjectData, BaseReferences<_$AppDatabase, $SubjectsTable, SubjectData>),
    SubjectData,
    PrefetchHooks Function()>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String subjectId,
  Value<String?> subjectName,
  required DateTime startTime,
  required DateTime endTime,
  required int durationSeconds,
  required int mode,
  Value<String?> planId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> subjectId,
  Value<String?> subjectName,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<int> durationSeconds,
  Value<int> mode,
  Value<String?> planId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    SessionData,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (SessionData, BaseReferences<_$AppDatabase, $SessionsTable, SessionData>),
    SessionData,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String?> subjectName = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> mode = const Value.absent(),
            Value<String?> planId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            subjectId: subjectId,
            subjectName: subjectName,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            mode: mode,
            planId: planId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subjectId,
            Value<String?> subjectName = const Value.absent(),
            required DateTime startTime,
            required DateTime endTime,
            required int durationSeconds,
            required int mode,
            Value<String?> planId = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            subjectId: subjectId,
            subjectName: subjectName,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            mode: mode,
            planId: planId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    SessionData,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (SessionData, BaseReferences<_$AppDatabase, $SessionsTable, SessionData>),
    SessionData,
    PrefetchHooks Function()>;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  required String subjectId,
  Value<String?> subjectName,
  required int targetMinutes,
  Value<DateTime?> deadline,
  required int priority,
  required int status,
  required String subTasks,
  required int completedMinutes,
  required DateTime createdAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String> subjectId,
  Value<String?> subjectName,
  Value<int> targetMinutes,
  Value<DateTime?> deadline,
  Value<int> priority,
  Value<int> status,
  Value<String> subTasks,
  Value<int> completedMinutes,
  Value<DateTime> createdAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subTasks => $composableBuilder(
      column: $table.subTasks, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedMinutes => $composableBuilder(
      column: $table.completedMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subTasks => $composableBuilder(
      column: $table.subTasks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedMinutes => $composableBuilder(
      column: $table.completedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get subjectName => $composableBuilder(
      column: $table.subjectName, builder: (column) => column);

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get subTasks =>
      $composableBuilder(column: $table.subTasks, builder: (column) => column);

  GeneratedColumn<int> get completedMinutes => $composableBuilder(
      column: $table.completedMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$PlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlansTable,
    PlanData,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (PlanData, BaseReferences<_$AppDatabase, $PlansTable, PlanData>),
    PlanData,
    PrefetchHooks Function()> {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String?> subjectName = const Value.absent(),
            Value<int> targetMinutes = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String> subTasks = const Value.absent(),
            Value<int> completedMinutes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlansCompanion(
            id: id,
            title: title,
            description: description,
            subjectId: subjectId,
            subjectName: subjectName,
            targetMinutes: targetMinutes,
            deadline: deadline,
            priority: priority,
            status: status,
            subTasks: subTasks,
            completedMinutes: completedMinutes,
            createdAt: createdAt,
            startedAt: startedAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required String subjectId,
            Value<String?> subjectName = const Value.absent(),
            required int targetMinutes,
            Value<DateTime?> deadline = const Value.absent(),
            required int priority,
            required int status,
            required String subTasks,
            required int completedMinutes,
            required DateTime createdAt,
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlansCompanion.insert(
            id: id,
            title: title,
            description: description,
            subjectId: subjectId,
            subjectName: subjectName,
            targetMinutes: targetMinutes,
            deadline: deadline,
            priority: priority,
            status: status,
            subTasks: subTasks,
            completedMinutes: completedMinutes,
            createdAt: createdAt,
            startedAt: startedAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlansTable,
    PlanData,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (PlanData, BaseReferences<_$AppDatabase, $PlansTable, PlanData>),
    PlanData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
}
