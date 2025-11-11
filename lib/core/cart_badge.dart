import 'package:flutter/foundation.dart';

// Simple app-wide ValueNotifier to track unseen cart additions.
// This avoids depending on Riverpod-specific providers for a small UI badge.
final cartBadgeNotifier = ValueNotifier<int>(0);

void incrementCartBadge([int by = 1]) => cartBadgeNotifier.value = cartBadgeNotifier.value + by;
void resetCartBadge() => cartBadgeNotifier.value = 0;
