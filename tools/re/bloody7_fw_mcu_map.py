#!/usr/bin/env python3
"""
Extract a static firmware-template to MCU map from Bloody7.exe.

This script uses UTF-16LE string clusters in Bloody7.exe:
1) Legacy USB firmware template names (e.g. A60cir_P3332A_%.3X_%d)
2) Contiguous Sonix MCU part strings (e.g. SN8F22E88B, SN8F2288)

The pairing is an informed static heuristic based on block ordering in the
binary's firmware-selection code path.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


DEFAULT_EXE = (
    "tmp/re/bloody7_rar/Bloody7_V2025.1222_MUI.exe/"
    "program files/Bloody7/Bloody7.exe"
)

UTF16_ASCII_PATTERN = re.compile(rb"(?:[\x20-\x7e]\x00){4,}")


def extract_utf16_ascii_strings(exe_bytes: bytes) -> list[str]:
    return [m.group(0).decode("utf-16le", "ignore") for m in UTF16_ASCII_PATTERN.finditer(exe_bytes)]


def find_legacy_model_templates(strings: list[str]) -> list[str]:
    start_token = "V_P3305_%.3X_%d"
    end_token = "FLc_A9800_%.3X_%d"
    try:
        start_index = strings.index(start_token)
        end_index = strings.index(end_token)
    except ValueError as exc:
        raise RuntimeError("Could not find legacy firmware template block in Bloody7.exe.") from exc

    if end_index < start_index:
        raise RuntimeError("Legacy template block end appears before start.")
    return strings[start_index : end_index + 1]


def find_initial_mcu_block(strings: list[str]) -> list[str]:
    start_token = "SN8F2253B"
    try:
        start_index = strings.index(start_token)
    except ValueError as exc:
        raise RuntimeError("Could not find MCU string block in Bloody7.exe.") from exc

    mcus: list[str] = []
    for entry in strings[start_index:]:
        if entry.startswith("SN"):
            mcus.append(entry)
            continue
        if mcus:
            break
    if not mcus:
        raise RuntimeError("MCU block extraction failed.")
    return mcus


def build_mapping(models: list[str], mcus: list[str]) -> list[dict[str, str]]:
    if len(mcus) < len(models):
        raise RuntimeError(
            f"MCU block too short for model block (models={len(models)}, mcus={len(mcus)})."
        )
    rows: list[dict[str, str]] = []
    for index, model in enumerate(models):
        rows.append(
            {
                "ordinal": str(index + 1),
                "firmware_template": model,
                "inferred_mcu": mcus[index],
            }
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Infer Bloody7 firmware template -> MCU mapping.")
    parser.add_argument("--exe", default=DEFAULT_EXE, help="Path to Bloody7.exe")
    parser.add_argument("--json-out", default="", help="Optional path to write JSON mapping output")
    args = parser.parse_args()

    exe_path = Path(args.exe)
    if not exe_path.exists():
        raise FileNotFoundError(f"Missing executable: {exe_path}")

    exe_bytes = exe_path.read_bytes()
    strings = extract_utf16_ascii_strings(exe_bytes)
    models = find_legacy_model_templates(strings)
    mcus = find_initial_mcu_block(strings)
    mapping = build_mapping(models, mcus)

    print(f"legacy_templates={len(models)}")
    print(f"initial_mcu_entries={len(mcus)}")
    print("")
    for row in mapping:
        print(f"{int(row['ordinal']):02d}. {row['firmware_template']} -> {row['inferred_mcu']}")

    t50_rows = [row for row in mapping if row["firmware_template"].startswith("A60cir_P3332A_")]
    if t50_rows:
        print("")
        print("T50 candidate:")
        for row in t50_rows:
            print(f"  {row['firmware_template']} -> {row['inferred_mcu']}")

    if args.json_out:
        out_path = Path(args.json_out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "exe": str(exe_path),
            "legacy_template_count": len(models),
            "initial_mcu_count": len(mcus),
            "mapping": mapping,
            "t50_candidates": t50_rows,
            "note": "Mapping is inferred from ordered static string blocks; validate against code-path pairing.",
        }
        out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"\nwrote {out_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
