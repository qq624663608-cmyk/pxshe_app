/// Hard rules lint test — grep-checks AGENTS / BUILDING_BLOCKS / REFERENCE
/// invariants across `lib/`. Designed to run inside `flutter test` so it
/// shares the same CI gate as unit tests, and complements `tool/ai.ps1 all`
/// which only inspects docs / packages / metadata.
///
/// Every rule below points to the source-of-truth section that justifies it.
/// When adding a new rule, also update `docs/ARCHITECTURE.md` if the change
/// touches `lib/_core/`, or `docs/BUILDING_BLOCKS.md` if it touches widget
/// rules (CONTRIBUTING §8).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Paths to scan. Excludes generated, build, and tooling directories.
const Set<String> _libScanRoots = {
  'lib/_core',
  'lib/_shared',
  'lib/modules',
};

/// Each entry: forbidden regex → list of POSIX-style allow-list regexes.
/// All file paths are normalised to forward-slash form before matching,
/// so patterns written here can use `/` regardless of host OS.
final Map<RegExp, _RuleSpec> _rules = {
  // print() — AGENTS §7 / REFERENCE §12 / 硬规则 #26
  RegExp(r'\bprint\s*\('): _RuleSpec(
    reason: 'AGENTS §7 / REFERENCE §12 / BUILDING_BLOCKS 硬规则 #26',
    allowFiles: [
      // logger wrapper itself uses print under the hood via logger package.
      RegExp(r'lib/_core/logger\.dart$'),
      RegExp(r'test/.*_test\.dart$'),
    ],
  ),

  // Color(0xFF...) — 硬规则 #8 — only theme tokens may define colors.
  RegExp(r'Color\(\s*0x[0-9a-fA-F]+\s*\)'): _RuleSpec(
    reason: 'BUILDING_BLOCKS 硬规则 #8 — AppColors 统一颜色',
    allowFiles: [
      RegExp(r'lib/_core/theme/app_colors\.dart$'),
      RegExp(r'test/.*_test\.dart$'),
    ],
  ),

  // Bare Dio in modules/ — 硬规则 #16 / REFERENCE §5
  // (modules must use ApiClient; raw Dio is reserved for _core/network/
  // and the error-translation layer that knows about DioException).
  RegExp(r"import\s+'package:dio/dio\.dart'"): _RuleSpec(
    reason: '硬规则 #16 / REFERENCE §5 — HTTP 必须走 ApiClient',
    allowFiles: [
      RegExp(r'lib/_core/network/.*\.dart$'),
      RegExp(r'lib/_core/http_client\.dart$'),
      // error/ translates DioException → ApiException; this is its job.
      RegExp(r'lib/_core/error/.*\.dart$'),
      // auth repository is a known stage-1 violation: should switch to
      // ApiClient before module expansion. Tracked as tech debt.
      // TODO(phase-2): migrate modules/auth/data/auth_repository_impl.dart
      //                to ApiClient (will touch 11 mock tests).
      RegExp(r'lib/modules/auth/data/auth_repository_impl\.dart$'),
      RegExp(r'test/.*_test\.dart$'),
    ],
  ),

  // OpenIM SDK in business code — 硬规则 #18 / IM_INTEGRATION §4
  // Only the IM module's data layer may import it directly.
  RegExp(r"import\s+'package:flutter_openim_sdk/"): _RuleSpec(
    reason: '硬规则 #18 / IM_INTEGRATION §4 — 业务代码禁直连 SDK',
    allowFiles: [
      RegExp(r'lib/modules/im/.*\.dart$'),
      RegExp(r'test/.*_test\.dart$'),
    ],
  ),
};

class _RuleSpec {
  _RuleSpec({required this.reason, required this.allowFiles});
  final String reason;
  final List<RegExp> allowFiles;
}

void main() {
  group('hard rules lint', () {
    final repoRoot = Directory.current.path;

    for (final entry in _rules.entries) {
      final pattern = entry.key;
      final spec = entry.value;
      test('no violation: ${pattern.pattern} (${spec.reason})', () async {
        final violations = await _scanForViolations(
          repoRoot: repoRoot,
          scanRoots: _libScanRoots,
          pattern: pattern,
          allowFiles: spec.allowFiles,
        );
        expect(
          violations,
          isEmpty,
          reason: 'Hard-rule violation (${spec.reason}). '
              'Offending files:\n  ${violations.join('\n  ')}\n\n'
              'See docs/BUILDING_BLOCKS.md §7 硬规则 or '
              'docs/REFERENCE.md for the rule details.',
        );
      });
    }
  });
}

/// Walks [scanRoots] under [repoRoot], collects every file whose contents
/// match [pattern] but is not in [allowFiles]. Returns project-relative
/// POSIX-style paths (forward slashes) of every offending file.
Future<List<String>> _scanForViolations({
  required String repoRoot,
  required Set<String> scanRoots,
  required RegExp pattern,
  required List<RegExp> allowFiles,
}) async {
  final offenders = <String>[];
  final rootWithSep = '$repoRoot${Platform.pathSeparator}';

  for (final root in scanRoots) {
    final dir = Directory('$repoRoot${Platform.pathSeparator}$root');
    if (!dir.existsSync()) continue;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      // Normalise to POSIX-style so allow-list regexes are portable.
      final rel = entity.path
          .replaceFirst(rootWithSep, '')
          .replaceAll(Platform.pathSeparator, '/');

      // Skip files in the allow-list.
      if (allowFiles.any((rx) => rx.hasMatch(rel))) continue;

      final contents = await entity.readAsString();
      if (pattern.hasMatch(contents)) {
        offenders.add(rel);
      }
    }
  }

  return offenders;
}