import 'package:flutter/material.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget mobileScaffold;
  final Widget tableScaffold;
  final Widget destopScaffold;

  const ResponsiveLayout({
    Key? key,
    required this.mobileScaffold,
    required this.tableScaffold,
    required this.destopScaffold,
  }) : super(key: key);

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout>
    with AutomaticKeepAliveClientMixin {
  Size? _lastSize;
  Widget? _currentWidget;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentWidgetIfNeeded();
  }

  @override
  void didUpdateWidget(ResponsiveLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentWidgetIfNeeded();
  }

  void _updateCurrentWidgetIfNeeded() {
    final size = MediaQuery.of(context).size;
    final newWidget = _getWidgetForSize(size.width);

    if (_lastSize == null || _lastSize!.width != size.width) {
      _lastSize = size;
      if (_currentWidget != newWidget) {
        setState(() {
          _currentWidget = newWidget;
        });
      }
    }
  }

  Widget _getWidgetForSize(double width) {
    if (width < 500) {
      return widget.mobileScaffold;
    } else if (width < 1100) {
      return widget.tableScaffold;
    } else {
      return widget.destopScaffold;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Use LayoutBuilder directly to get the current constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget layout;
        if (constraints.maxWidth < 500) {
          layout = widget.mobileScaffold;
        } else if (constraints.maxWidth < 1100) {
          layout = widget.tableScaffold;
        } else {
          layout = widget.destopScaffold;
        }

        // Wrap in RepaintBoundary to preserve visual state during transitions
        return RepaintBoundary(child: layout);
      },
    );
  }
}
