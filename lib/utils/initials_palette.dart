import 'package:flutter/material.dart';

/// First grapheme of [name] uppercased, or `?` when [name] is empty.
String initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

/// Deterministic colour for [name] from the darker shades of the Plezzant
/// palette. They are dark enough that white-on-colour text always meets
/// contrast — callers can use plain `Colors.white` without per-colour checks.
Color colorForName(String name, ThemeData theme) {
  if (name.isEmpty) return theme.colorScheme.primary;
  var hash = 0;
  for (final code in name.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _palette[hash % _palette.length];
}

const _palette = <Color>[
  Color.fromARGB(0xFF, 15, 115, 185), // Azure darker
  Color.fromARGB(0xFF, 55, 145, 40), // Leaf Green darker
  Color.fromARGB(0xFF, 150, 10, 85), // Magenta darker
  Color.fromARGB(0xFF, 85, 20, 180), // Violet darker
  Color.fromARGB(0xFF, 0, 95, 95), // Dark Teal darker
  Color.fromARGB(0xFF, 165, 45, 25), // Persimmon darker
  Color.fromARGB(0xFF, 15, 55, 150), // Cobalt darker
  Color.fromARGB(0xFF, 150, 10, 40), // Crimson darker
];
