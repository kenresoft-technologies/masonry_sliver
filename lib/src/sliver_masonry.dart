import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Where a child of a [RenderSliverMasonry] sits across the scroll direction.
class SliverMasonryParentData extends SliverMultiBoxAdaptorParentData {
  double crossAxisOffset = 0;
}

/// Lazily builds its children in [crossAxisCount] columns of equal width, each child as tall as it
/// needs to be.
class SliverMasonry extends SliverMultiBoxAdaptorWidget {
  const SliverMasonry({
    super.key,
    required super.delegate,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  }) : assert(crossAxisCount > 0);

  /// Builds [itemCount] children with [itemBuilder].
  SliverMasonry.builder({
    Key? key,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    int crossAxisCount = 2,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
  }) : this(
          key: key,
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
            findChildIndexCallback: findChildIndexCallback,
          ),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
        );

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this);

  @override
  RenderSliverMasonry createRenderObject(BuildContext context) {
    return RenderSliverMasonry(
      childManager: context as SliverMultiBoxAdaptorElement,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverMasonry renderObject) {
    renderObject
      ..crossAxisCount = crossAxisCount
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing;
  }
}

class RenderSliverMasonry extends RenderSliverMultiBoxAdaptor {
  RenderSliverMasonry({
    required super.childManager,
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
  })  : _crossAxisCount = crossAxisCount,
        _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing {
    _columnEnds = List<double>.filled(crossAxisCount, 0);
  }

  int _crossAxisCount;
  int get crossAxisCount => _crossAxisCount;
  set crossAxisCount(int value) {
    if (value == _crossAxisCount) return;
    _crossAxisCount = value;
    _forgetPlaces();
    markNeedsLayout();
  }

  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (value == _mainAxisSpacing) return;
    _mainAxisSpacing = value;
    _forgetPlaces();
    markNeedsLayout();
  }

  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (value == _crossAxisSpacing) return;
    _crossAxisSpacing = value;
    _forgetPlaces();
    markNeedsLayout();
  }

  // What is remembered: one entry per item placed so far, in index order. Tops never decrease
  // with the index (each item goes where the shortest column ends), which the layout relies on.
  final List<double> _tops = [];
  final List<double> _heights = [];
  final List<int> _columns = [];
  late List<double> _columnEnds;
  double _columnWidth = -1;

  void _forgetPlaces() {
    _tops.clear();
    _heights.clear();
    _columns.clear();
    _columnEnds = List<double>.filled(_crossAxisCount, 0);
  }

  /// Forgets every place from [index] on (the item there changed height, or is a different one).
  void _truncate(int index) {
    if (index >= _tops.length) return;
    _tops.length = index;
    _heights.length = index;
    _columns.length = index;
    _columnEnds = List<double>.filled(_crossAxisCount, 0);
    for (var i = 0; i < index; i++) {
      _columnEnds[_columns[i]] = _tops[i] + _heights[i] + _mainAxisSpacing;
    }
  }

  int get _shortestColumn {
    var best = 0;
    for (var i = 1; i < _columnEnds.length; i++) {
      if (_columnEnds[i] < _columnEnds[best]) best = i;
    }
    return best;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMasonryParentData)
      child.parentData = SliverMasonryParentData();
  }

  @override
  double childCrossAxisPosition(RenderBox child) =>
      (child.parentData! as SliverMasonryParentData).crossAxisOffset;

  @override
  void performLayout() {
    final c = constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final count = childManager.childCount;
    if (count == 0) {
      collectGarbage(childCount, 0);
      _forgetPlaces();
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final columnWidth =
        (c.crossAxisExtent - _crossAxisSpacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
    if (columnWidth != _columnWidth || _columnEnds.length != _crossAxisCount) {
      _columnWidth = columnWidth;
      _forgetPlaces();
    }
    final childConstraints =
        BoxConstraints(minWidth: columnWidth, maxWidth: columnWidth);

    final windowStart = c.scrollOffset + c.cacheOrigin;
    final windowEnd = windowStart + c.remainingCacheExtent;

    // The first remembered item that still reaches into the window.
    var first = _tops.length;
    for (var i = 0; i < _tops.length; i++) {
      if (_tops[i] + _heights[i] >= windowStart) {
        first = i;
        break;
      }
    }
    if (first >= _tops.length) first = math.max(0, _tops.length - 1);
    if (first >= count) first = count - 1;

    // Make the live children start at [first].
    if (firstChild == null) {
      _forgetPlaces();
      if (!addInitialChild(index: 0, layoutOffset: 0)) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    } else {
      final liveFirst = indexOf(firstChild!);
      final liveLast = indexOf(lastChild!);
      if (first > liveFirst) {
        if (first <= liveLast) {
          collectGarbage(first - liveFirst, 0);
        } else {
          collectGarbage(liveLast - liveFirst + 1, 0);
          addInitialChild(
              index: first,
              layoutOffset: first < _tops.length ? _tops[first] : 0);
        }
      } else if (first < liveFirst) {
        while (indexOf(firstChild!) > first) {
          if (insertAndLayoutLeadingChild(childConstraints,
                  parentUsesSize: true) ==
              null) break;
        }
      }
    }

    // Walk forwards, reading back the places that are known and placing what is new.
    var child = firstChild!;
    var index = indexOf(child);
    var reachedEnd = false;
    var leading = double.infinity;
    var trailing = 0.0;
    RenderBox lastLaidOut = child;

    while (true) {
      child.layout(childConstraints, parentUsesSize: true);
      final height = child.size.height;

      if (index < _tops.length && (_heights[index] - height).abs() > 0.01) {
        _truncate(
            index); // it is a different height now: everything after it is worked out again
      }
      if (index > _tops.length) {
        // Only after a jump past what is placed: stand in for the gap so the order holds. The
        // real items correct it as they are laid out (their heights differ, so places are redone).
        while (_tops.length < index) {
          _place(height);
        }
      }
      if (index == _tops.length) _place(height);

      final data = child.parentData! as SliverMasonryParentData;
      data.layoutOffset = _tops[index];
      data.crossAxisOffset =
          _columns[index] * (columnWidth + _crossAxisSpacing);
      leading = math.min(leading, _tops[index]);
      trailing = math.max(trailing, _tops[index] + height);
      lastLaidOut = child;

      if (index + 1 >= count) {
        reachedEnd = true;
        break;
      }
      final nextTop = index + 1 < _tops.length
          ? _tops[index + 1]
          : _columnEnds.reduce(math.min);
      if (nextTop > windowEnd) break;

      var next = childAfter(child);
      if (next == null || indexOf(next) != index + 1) {
        next = insertAndLayoutChild(childConstraints,
            after: child, parentUsesSize: true);
        if (next == null) {
          reachedEnd = true;
          break;
        }
      }
      child = next;
      index += 1;
    }

    // Children after the last one needed.
    var trailingGarbage = 0;
    for (var extra = childAfter(lastLaidOut);
        extra != null;
        extra = childAfter(extra)) {
      trailingGarbage += 1;
    }
    collectGarbage(0, trailingGarbage);

    // How long the whole thing is: exact at the end, a steady estimate before.
    final placed = _tops.length;
    final longest = _columnEnds.reduce(math.max) - _mainAxisSpacing;
    final double scrollExtent;
    if (reachedEnd && placed >= count) {
      scrollExtent = math.max(longest, trailing);
    } else {
      var sum = 0.0;
      for (final h in _heights) {
        sum += h + _mainAxisSpacing;
      }
      final average = placed == 0 ? 0.0 : sum / placed;
      scrollExtent = math.max(longest, trailing) +
          (count - placed) * average / _crossAxisCount;
    }

    final paintExtent = calculatePaintOffset(c, from: leading, to: trailing);
    final cacheExtent = calculateCacheOffset(c, from: leading, to: trailing);
    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: scrollExtent,
      hasVisualOverflow: trailing > c.scrollOffset + c.remainingPaintExtent ||
          c.scrollOffset > 0,
    );
    childManager.setDidUnderflow(reachedEnd && placed >= count);
    childManager.didFinishLayout();
  }

  void _place(double height) {
    final column = _shortestColumn;
    final top = _columnEnds[column];
    _tops.add(top);
    _heights.add(height);
    _columns.add(column);
    _columnEnds[column] = top + height + _mainAxisSpacing;
  }

  /// How many items have a remembered place (for tests).
  int get placedCount => _tops.length;
}
