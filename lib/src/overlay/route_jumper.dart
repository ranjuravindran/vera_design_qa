import 'package:flutter/material.dart';

import '../config/design_qa_config.dart';
import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';

/// Walks down from [context] to find the app's own `Navigator` - `Navigator
/// .of(context)` only searches ancestors, but design_qa's overlay sits
/// *above* the app (a sibling in the root `Stack`, not a descendant of
/// `MaterialApp`), so the app's Navigator is a descendant of our own
/// context, not an ancestor.
NavigatorState? findDescendantNavigatorState(BuildContext context) {
  NavigatorState? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is NavigatorState) {
      found = element.state as NavigatorState;
      return;
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return found;
}

/// Searchable list of every route declared in `design_qa.yaml`, tapping
/// navigates the running app via [Navigator.pushNamed].
///
/// Only works for plain `Navigator`/`MaterialApp(routes:)` /
/// `onGenerateRoute` apps - a `GoRouter` app's routes still get listed
/// (route discovery is static analysis in `dart run design_qa:init`, not
/// this), but tapping one won't navigate a GoRouter-based app, since
/// GoRouter manages navigation independently of `Navigator.pushNamed` and
/// design_qa deliberately doesn't take a hard dependency on
/// `package:go_router` just to support that. See doc/limitations.md.
class RouteJumperSheet extends StatefulWidget {
  const RouteJumperSheet({super.key});

  @override
  State<RouteJumperSheet> createState() => _RouteJumperSheetState();
}

class _RouteJumperSheetState extends State<RouteJumperSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _jump(BuildContext overlayContext, DesignQAController controller, RouteEntry route) {
    final NavigatorState? nav = findDescendantNavigatorState(overlayContext);
    if (nav == null) {
      ScaffoldMessenger.maybeOf(overlayContext)?.showSnackBar(
        const SnackBar(content: Text("Couldn't find a Navigator in this app.")),
      );
      return;
    }
    nav.pushNamed(route.name, arguments: route.mockArgs.isEmpty ? null : route.mockArgs);
    controller.toggleRouteJumper();
  }

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    final String query = _search.text.trim().toLowerCase();
    final List<RouteEntry> routes = controller.config.routes
        .where((RouteEntry r) => query.isEmpty || r.name.toLowerCase().contains(query))
        .toList();

    return Positioned(
      left: 16,
      top: 72,
      width: 280,
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search routes',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              Flexible(
                child: routes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No routes in design_qa.yaml yet. Re-run `dart run design_qa:init` after '
                          'adding screens.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: routes.length,
                        itemBuilder: (BuildContext context, int i) {
                          final RouteEntry route = routes[i];
                          return ListTile(
                            dense: true,
                            title: Text(route.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: route.mockArgs.isEmpty
                                ? null
                                : Text(
                                    route.mockArgs.toString(),
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                  ),
                            onTap: () => _jump(context, controller, route),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
