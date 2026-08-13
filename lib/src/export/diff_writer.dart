/// Minimal unified-diff generator (LCS-based line diff) so exporting
/// doesn't need an extra pub dependency just for this. `design_qa` only
/// ever diffs single screen-sized source files, so an O(n*m) DP table is
/// fine; above [_maxLinesForFullDiff] it degrades to a note rather than
/// spending seconds (or hundreds of MB) on a diff nobody asked for.
const int _maxLinesForFullDiff = 4000;
const int _contextLines = 3;

String unifiedDiff({required String path, required String before, required String after}) {
  final List<String> a = before.split('\n');
  final List<String> b = after.split('\n');

  if (a.length > _maxLinesForFullDiff || b.length > _maxLinesForFullDiff) {
    return '--- a/$path\n+++ b/$path\n'
        '@@ file too large for an inline diff (${a.length} lines) - see the patched file directly @@\n';
  }

  final List<_DiffOp> ops = _lineDiff(a, b);
  final StringBuffer out = StringBuffer('--- a/$path\n+++ b/$path\n');

  int i = 0;
  while (i < ops.length) {
    if (ops[i].type == _OpType.equal) {
      i++;
      continue;
    }
    int start = i;
    while (start > 0 && i - start < _contextLines && ops[start - 1].type == _OpType.equal) {
      start--;
    }
    int end = i;
    while (end < ops.length && (end - i < 1 || _withinContextOfChange(ops, end))) {
      end++;
    }
    out.write(_formatHunk(ops, start, end));
    i = end;
  }
  return out.toString();
}

bool _withinContextOfChange(List<_DiffOp> ops, int index) {
  if (index >= ops.length) return false;
  if (ops[index].type != _OpType.equal) return true;
  // Keep scanning through an equal-run only if another change starts within
  // 2 * context lines - otherwise this hunk is done.
  for (int k = index; k < ops.length && k < index + _contextLines; k++) {
    if (ops[k].type != _OpType.equal) return true;
  }
  return false;
}

String _formatHunk(List<_DiffOp> ops, int start, int end) {
  int oldLine = 1 + ops.take(start).where((_DiffOp o) => o.type != _OpType.insert).length;
  int newLine = 1 + ops.take(start).where((_DiffOp o) => o.type != _OpType.delete).length;
  final int oldCount = ops.sublist(start, end).where((_DiffOp o) => o.type != _OpType.insert).length;
  final int newCount = ops.sublist(start, end).where((_DiffOp o) => o.type != _OpType.delete).length;

  final StringBuffer hunk = StringBuffer('@@ -$oldLine,$oldCount +$newLine,$newCount @@\n');
  for (int k = start; k < end; k++) {
    final _DiffOp op = ops[k];
    final String prefix = switch (op.type) {
      _OpType.equal => ' ',
      _OpType.delete => '-',
      _OpType.insert => '+',
    };
    hunk.write('$prefix${op.line}\n');
  }
  return hunk.toString();
}

enum _OpType { equal, delete, insert }

class _DiffOp {
  const _DiffOp(this.type, this.line);
  final _OpType type;
  final String line;
}

List<_DiffOp> _lineDiff(List<String> a, List<String> b) {
  final int n = a.length;
  final int m = b.length;
  final List<List<int>> dp = List<List<int>>.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (int i = n - 1; i >= 0; i--) {
    for (int j = m - 1; j >= 0; j--) {
      dp[i][j] =
          a[i] == b[j] ? dp[i + 1][j + 1] + 1 : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final List<_DiffOp> ops = <_DiffOp>[];
  int i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      ops.add(_DiffOp(_OpType.equal, a[i]));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      ops.add(_DiffOp(_OpType.delete, a[i]));
      i++;
    } else {
      ops.add(_DiffOp(_OpType.insert, b[j]));
      j++;
    }
  }
  while (i < n) {
    ops.add(_DiffOp(_OpType.delete, a[i]));
    i++;
  }
  while (j < m) {
    ops.add(_DiffOp(_OpType.insert, b[j]));
    j++;
  }
  return ops;
}
