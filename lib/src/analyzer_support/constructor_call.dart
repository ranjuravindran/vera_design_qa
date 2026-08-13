import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Uniform view over a constructor-shaped call in a purely *syntactic*
/// parse (`package:analyzer`'s `parseString`, used throughout this package
/// so it never needs a full resolved `AnalysisContext`).
///
/// That parser only ever produces [InstanceCreationExpression] for a call
/// that writes an explicit `new`/`const` keyword. A bare `Widget(args)` -
/// the more common style once a subtree isn't const-able, and extremely
/// common in real Flutter code - is syntactically indistinguishable from a
/// function call without type information, so it parses as a plain
/// [MethodInvocation] instead. Every place in this package that looks for
/// "a call to construct X" (the source patcher, the route/theme scanners)
/// has to treat both shapes the same, or it silently only ever finds the
/// `const`-prefixed half of real projects' code.
///
/// Disambiguated from an actual function call by two syntactic cheats that
/// hold for real code: a constructor call has no target/receiver
/// (`Padding(...)`, never `foo.Padding(...)`), and Dart class names are
/// conventionally capitalized while function names are not.
class ConstructorCall {
  const ConstructorCall({required this.typeName, required this.arguments, required this.offset});

  final String typeName;
  final ArgumentList arguments;
  final int offset;

  static ConstructorCall? from(AstNode node) {
    if (node is InstanceCreationExpression) {
      return ConstructorCall(
        typeName: node.constructorName.type.toString(),
        arguments: node.argumentList,
        offset: node.offset,
      );
    }
    if (node is MethodInvocation && node.target == null && node.typeArguments == null) {
      final String name = node.methodName.name;
      if (name.isNotEmpty && RegExp(r'^[A-Z]').hasMatch(name)) {
        return ConstructorCall(typeName: name, arguments: node.argumentList, offset: node.offset);
      }
    }
    return null;
  }
}

/// Visits every node that could be a [ConstructorCall], in both its
/// possible AST shapes.
class ConstructorCallVisitor extends RecursiveAstVisitor<void> {
  ConstructorCallVisitor(this.onCall);
  final void Function(ConstructorCall call) onCall;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final ConstructorCall? call = ConstructorCall.from(node);
    if (call != null) onCall(call);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final ConstructorCall? call = ConstructorCall.from(node);
    if (call != null) onCall(call);
    super.visitMethodInvocation(node);
  }
}
