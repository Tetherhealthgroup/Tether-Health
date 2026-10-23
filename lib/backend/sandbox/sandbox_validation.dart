// Body validation for the sandbox's routes: the same accept/refuse rules as
// the API's DTOs for the fields the app sends. A refusal names a code only.
import 'dart:math' as math;

/// A refused request: status and problem code. Thrown inside a sandbox
/// transaction, so nothing of the request is kept.
class SandboxProblem implements Exception {
  const SandboxProblem(this.status, this.code, {this.positions = const []});

  final int status;
  final String code;
  final List<int> positions;

  @override
  String toString() => 'SandboxProblem($status, $code)';
}

/// One body field's rule.
abstract class FieldRule {
  const FieldRule({this.required = false, this.nullable = false});

  final bool required;
  final bool nullable;

  /// The checked value, or throws [FormatException].
  Object? check(Object? value, DateTime now);
}

class StrRule extends FieldRule {
  const StrRule({
    super.required,
    super.nullable,
    this.min = 0,
    this.max = 1 << 20,
    this.pattern,
    this.trim = false,
  });

  final int min;
  final int max;
  final RegExp? pattern;
  final bool trim;

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! String) throw const FormatException();
    final text = trim ? value.trim() : value;
    if (text.length < min || text.length > max) throw const FormatException();
    if (pattern != null && !pattern!.hasMatch(text)) {
      throw const FormatException();
    }
    return text;
  }
}

class IntRule extends FieldRule {
  const IntRule({super.required, super.nullable, this.min, this.max});

  final int? min;
  final int? max;

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! num || value != value.roundToDouble()) {
      throw const FormatException();
    }
    final n = value.toInt();
    if ((min != null && n < min!) || (max != null && n > max!)) {
      throw const FormatException();
    }
    return n;
  }
}

/// A number with at most 3 decimal places. Bounds here are DTO bounds
/// (400); spec ranges and value bounds are checked by the route (422).
class NumRule extends FieldRule {
  const NumRule({super.required, super.nullable, this.min, this.max});

  final num? min;
  final num? max;

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! num || value.isNaN || value.isInfinite) {
      throw const FormatException();
    }
    final scaled = value * 1000;
    if ((scaled - scaled.roundToDouble()).abs() > 1e-6) {
      throw const FormatException();
    }
    if ((min != null && value < min!) || (max != null && value > max!)) {
      throw const FormatException();
    }
    return value;
  }
}

class BoolRule extends FieldRule {
  const BoolRule({super.required, super.nullable});

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! bool) throw const FormatException();
    return value;
  }
}

class EnumRule extends FieldRule {
  const EnumRule(this.values, {super.required, super.nullable});

  final Set<String> values;

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! String || !values.contains(value)) {
      throw const FormatException();
    }
    return value;
  }
}

/// A unique array of codes.
class SetRule extends FieldRule {
  const SetRule(this.values, {super.required, this.min = 0, this.max = 12});

  final Set<String> values;
  final int min;
  final int max;

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! List) throw const FormatException();
    if (value.length < min || value.length > max) {
      throw const FormatException();
    }
    final seen = <String>{};
    for (final item in value) {
      if (item is! String || !values.contains(item) || !seen.add(item)) {
        throw const FormatException();
      }
    }
    return List<String>.of(seen);
  }
}

/// RFC 3339 with an offset, at most 5 minutes in the future.
class TimeRule extends FieldRule {
  const TimeRule({super.required});

  static final RegExp _shape = RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! String || !_shape.hasMatch(value)) {
      throw const FormatException();
    }
    final at = DateTime.parse(value).toUtc();
    if (at.isAfter(now.toUtc().add(const Duration(minutes: 5)))) {
      throw const FormatException();
    }
    return at.toIso8601String();
  }
}

/// `YYYY-MM-DD` from 1900-01-01 up to tomorrow's UTC date.
class DateRule extends FieldRule {
  const DateRule({super.required});

  static final RegExp _shape = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! String || !_shape.hasMatch(value)) {
      throw const FormatException();
    }
    final parts = value.split('-').map(int.parse).toList();
    final date = DateTime.utc(parts[0], parts[1], parts[2]);
    if (date.year != parts[0] ||
        date.month != parts[1] ||
        date.day != parts[2]) {
      throw const FormatException();
    }
    final today = now.toUtc();
    final tomorrow = DateTime.utc(today.year, today.month, today.day + 1);
    if (date.isBefore(DateTime.utc(1900)) || date.isAfter(tomorrow)) {
      throw const FormatException();
    }
    return value;
  }
}

/// A nested object with its own rules.
class ObjRule extends FieldRule {
  const ObjRule(this.fields, {super.required});

  final Map<String, FieldRule> fields;

  @override
  Object? check(Object? value, DateTime now) => checkObject(value, fields, now);
}

/// Checks [body] against [fields]: an object with only known keys, every
/// required key present, every value valid. Returns the checked values of
/// the keys present. Throws [FormatException] otherwise.
Map<String, Object?> checkObject(
  Object? body,
  Map<String, FieldRule> fields,
  DateTime now,
) {
  if (body is! Map) throw const FormatException();
  final out = <String, Object?>{};
  for (final key in body.keys) {
    if (key is! String || !fields.containsKey(key)) {
      throw const FormatException();
    }
  }
  for (final MapEntry(key: name, value: rule) in fields.entries) {
    if (!body.containsKey(name)) {
      if (rule.required) throw const FormatException();
      continue;
    }
    final value = body[name];
    if (value == null) {
      if (!rule.nullable) throw const FormatException();
      out[name] = null;
      continue;
    }
    out[name] = rule.check(value, now);
  }
  return out;
}

/// [checkObject], refusing with [status]/[code].
Map<String, Object?> validated(
  Object? body,
  Map<String, FieldRule> fields,
  DateTime now, {
  int status = 400,
  String code = 'bad_request',
}) {
  try {
    return checkObject(body, fields, now);
  } on FormatException {
    throw SandboxProblem(status, code);
  } on TypeError {
    throw SandboxProblem(status, code);
  }
}

/// A canonical text of [value] for comparing two submissions' content.
String canonicalJson(Object? value) => switch (value) {
      null => 'null',
      final bool b => '$b',
      final num n => n == n.roundToDouble() && n.abs() < math.pow(2, 53)
          ? '${n.toInt()}'
          : '$n',
      final String s => '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"',
      final List<Object?> l => '[${l.map(canonicalJson).join(',')}]',
      final Map<Object?, Object?> m => () {
          final keys = m.keys.map((k) => '$k').toList()..sort();
          return '{${keys.map((k) => '"$k":${canonicalJson(m[k])}').join(',')}}';
        }(),
      _ => '"$value"',
    };
