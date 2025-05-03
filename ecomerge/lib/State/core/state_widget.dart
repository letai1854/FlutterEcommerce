import 'package:flutter/material.dart';
import '../signup/base_state_provider.dart';

class StateWidget<T extends BaseStateProvider> extends InheritedWidget {
  final T state;

  const StateWidget({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  static T of<T extends BaseStateProvider>(BuildContext context) {
    final StateWidget<T>? result =
        context.dependOnInheritedWidgetOfExactType<StateWidget<T>>();
    assert(result != null, 'No StateWidget<$T> found in context');
    return result!.state;
  }

  static T read<T extends BaseStateProvider>(BuildContext context) {
    final StateWidget<T>? result = context
        .getElementForInheritedWidgetOfExactType<StateWidget<T>>()
        ?.widget as StateWidget<T>?;
    assert(result != null, 'No StateWidget<$T> found in context');
    return result!.state;
  }

  @override
  bool updateShouldNotify(StateWidget<T> oldWidget) {
    return true; // Always notify since state is mutable
  }
}

class StateProvider<T extends BaseStateProvider> extends StatefulWidget {
  final T Function() create;
  final Widget child;

  const StateProvider({
    Key? key,
    required this.create,
    required this.child,
  }) : super(key: key);

  @override
  State<StateProvider<T>> createState() => _StateProviderState<T>();
}

class _StateProviderState<T extends BaseStateProvider>
    extends State<StateProvider<T>> {
  late final T state;

  @override
  void initState() {
    super.initState();
    state = widget.create();
    state.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    setState(() {});
  }

  @override
  void dispose() {
    state.removeListener(_handleStateChange);
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateWidget<T>(
      state: state,
      child: widget.child,
    );
  }
}

// Extensions for easier state access
extension StateReaderContext on BuildContext {
  T readState<T extends BaseStateProvider>() => StateWidget.read<T>(this);
  T watchState<T extends BaseStateProvider>() => StateWidget.of<T>(this);
}
