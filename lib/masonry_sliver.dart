/// A lazy staggered ("masonry") sliver: cards keep their own heights, and each new one goes into
/// the shortest column.
///
/// Sliver grids that work positions out backwards from whatever happens to be built can lose
/// track of them, so the page stops scrolling or jumps back. This one remembers where every item
/// went: items are only ever placed forwards, once, and scrolling up reads the remembered places.
/// The scroll length is exact once the end has been reached, and a steady estimate before.
library;

export 'src/sliver_masonry.dart';
