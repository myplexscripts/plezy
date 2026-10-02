#!/usr/bin/env python3

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts" / "checks" / "check_icon_consistency.dart"


class IconConsistencyCheckerTest(unittest.TestCase):
    def run_checker(self, sources: dict[str, str]) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as temporary_directory:
            fixture_root = Path(temporary_directory)
            for relative_path, source in sources.items():
                target = fixture_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(source, encoding="utf-8")

            return subprocess.run(
                ["dart", "run", str(CHECKER), "--root", str(fixture_root)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_accepts_canonical_wrapper_and_lucide_icons(self) -> None:
        result = self.run_checker(
            {
                "lib/widgets/app_icon.dart": """
import 'package:flutter/material.dart';

Widget buildIcon(IconData icon) => Icon(icon);
""",
                "lib/example.dart": """
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:lucide_icons_flutter/lucide_icons.dart';

final icons = [AppIcon(lucide.LucideIcons.plus), AppIcon(LucideIcons.disc3), AppIcon(LucideIcons.repeat1)];
""",
                "lib/ignored.g.dart": """
Widget ignored(IconData icon) => Icon(icon);
""",
            }
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Icon consistency check passed", result.stdout)

    def test_rejects_material_icons_weight_variants_and_constructor_tear_offs(self) -> None:
        result = self.run_checker(
            {
                "lib/bad.dart": """
import 'package:flutter/material.dart' as material;
import 'package:material_symbols_icons/symbols.dart' as ms;
import 'package:material_symbols_icons/material_symbols_icons.dart' as material_symbols;
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

final values = [
  material.Icons.add,
  ms.Symbols.add_rounded,
  material_symbols.Symbols.add,
  Symbols.home_rounded,
  lucide.LucideIcons.house300,
  LucideIcons.house600Dir,
  material.Icon.new,
  Icon.new,
];
""",
            }
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("material.Icons.add is forbidden", result.stderr)
        self.assertIn("ms.Symbols.add_rounded is forbidden", result.stderr)
        self.assertIn("material_symbols.Symbols.add is forbidden", result.stderr)
        self.assertIn("Symbols.home_rounded is forbidden", result.stderr)
        self.assertIn("lucide.LucideIcons.house300 is a stroke-weight variant", result.stderr)
        self.assertIn("LucideIcons.house600Dir is a stroke-weight variant", result.stderr)
        self.assertEqual(result.stderr.count("constructor tear-offs are forbidden"), 2, result.stderr)


if __name__ == "__main__":
    unittest.main()
