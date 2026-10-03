# masonry_sliver

[![CI](https://github.com/kenresoft-technologies/masonry_sliver/actions/workflows/ci.yml/badge.svg)](https://github.com/kenresoft-technologies/masonry_sliver/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A lazy staggered (masonry) sliver for Flutter. Items keep their own heights and each new one goes
into the shortest column.

Sliver grids that work positions out backwards from whatever happens to be built can lose track of
them, so the page stops scrolling or jumps back. `SliverMasonry` remembers where every item went:
items are only ever placed forwards, once, and scrolling up reads the remembered places. The scroll
length is exact once the end has been reached, and a steady estimate before.

## Usage

```yaml
dependencies:
  masonry_sliver:
    git:
      url: https://github.com/kenresoft-technologies/masonry_sliver.git
```

```dart
import 'package:masonry_sliver/masonry_sliver.dart';

CustomScrollView(
  slivers: [
    SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonry.builder(
        itemCount: 200,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemBuilder: (context, index) => MyCard(index),
      ),
    ),
  ],
)
```

| Parameter | Default | Description |
|---|---|---|
| `crossAxisCount` | `2` | Number of equal-width columns |
| `mainAxisSpacing` | `0` | Gap between items in a column |
| `crossAxisSpacing` | `0` | Gap between columns |

See the [example](example) app for a runnable demo.

## License

MIT — see [LICENSE](LICENSE).
