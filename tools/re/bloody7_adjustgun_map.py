#!/usr/bin/env python3
"""
Extract flash-bridge call structure from Bloody7.exe.

This focuses on callsites to Hid_flash primitives and emits per-function call
order plus local operand hints (address source, count source, pointer source).
It is intended to narrow down Iom_adjustgun-style persistence flows.
"""

from __future__ import annotations

import argparse
import bisect
import json
import struct
from pathlib import Path
from typing import Any

import lief
from capstone import CS_ARCH_X86, CS_MODE_32, Cs


DEFAULT_EXE = (
    "tmp/re/bloody7_rar/Bloody7_V2025.1222_MUI.exe/"
    "program files/Bloody7/Bloody7.exe"
)


DEFAULT_TARGETS = {
    0x55C8CC: "flash_read8",
    0x55CA00: "flash_write_words",
    0x55CABC: "flash_write_words_verify",
    0x55CCB4: "flash_read_dwords",
    0x55CE14: "flash_write_dwords",
}


def parse_hex_vma(value: str) -> int:
    return int(value, 0)


def find_text_section(binary: lief.PE.Binary) -> lief.PE.Section:
    for section in binary.sections:
        if section.name == ".text":
            return section
    raise RuntimeError("Could not find .text section.")


def find_rel32_calls(text_bytes: bytes, text_vma: int, target_vma: int) -> list[int]:
    hits: list[int] = []
    for offset in range(len(text_bytes) - 5):
        if text_bytes[offset] != 0xE8:
            continue
        rel = struct.unpack_from("<i", text_bytes, offset + 1)[0]
        callsite = text_vma + offset
        target = (callsite + 5 + rel) & 0xFFFFFFFF
        if target == target_vma:
            hits.append(callsite)
    return hits


def find_nearest_prologue(text_bytes: bytes, text_vma: int, callsite_vma: int) -> int | None:
    search_start = max(text_vma, callsite_vma - 0x1000)
    for vma in range(callsite_vma - 3, search_start - 1, -1):
        offset = vma - text_vma
        if text_bytes[offset : offset + 3] == b"\x55\x8b\xec":
            return vma
    return None


def disassemble_range(text_bytes: bytes, text_vma: int, start_vma: int, end_vma: int) -> list[Any]:
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    md.detail = False
    start_offset = max(0, start_vma - text_vma)
    end_offset = min(len(text_bytes), end_vma - text_vma)
    return list(md.disasm(text_bytes[start_offset:end_offset], text_vma + start_offset))


def owner_lookup(binary: lief.PE.Binary, address_vma: int) -> tuple[str | None, int | None]:
    exports: list[tuple[int, str]] = []
    imagebase = binary.optional_header.imagebase
    for func in binary.exported_functions:
        if not func.name:
            continue
        exports.append((imagebase + func.address, func.name))
    exports.sort()
    if not exports:
        return None, None
    addrs = [addr for addr, _ in exports]
    index = bisect.bisect_right(addrs, address_vma) - 1
    if index < 0:
        return None, None
    return exports[index][1], exports[index][0]


def collect_hints(context: list[Any], window_size: int = 28) -> dict[str, Any]:
    tail = context[-window_size:]
    pushes: list[str] = []
    push_immediates: list[str] = []
    address_sources: list[str] = []
    count_sources: list[str] = []
    pointer_sources: list[str] = []
    writes_a4a4 = False

    for insn in tail:
        text = f"{insn.mnemonic} {insn.op_str}".strip()
        if insn.mnemonic == "push":
            pushes.append(insn.op_str)
            try:
                push_immediates.append(hex(int(insn.op_str, 0)))
            except ValueError:
                pass
        if "mov dx, word ptr [ebp -" in text or "movzx edx, word ptr [ebp -" in text:
            address_sources.append(insn.op_str)
        if insn.mnemonic == "cmp" and ", 0x" in insn.op_str:
            count_sources.append(insn.op_str)
        if insn.mnemonic == "push" and ("[ebp -" in insn.op_str or "[esi +" in insn.op_str):
            pointer_sources.append(insn.op_str)
        if "0xa4a4" in insn.op_str:
            writes_a4a4 = True

    return {
        "pushes_tail": pushes[-10:],
        "push_immediates_tail": push_immediates[-6:],
        "address_sources": address_sources[-4:],
        "count_sources": count_sources[-4:],
        "pointer_sources": pointer_sources[-4:],
        "writes_a4a4_nearby": writes_a4a4,
        "context_tail": [
            {
                "address": f"0x{insn.address:08x}",
                "mnemonic": insn.mnemonic,
                "op_str": insn.op_str,
            }
            for insn in tail[-16:]
        ],
    }


def build_function_summary(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = row["function_start"]
        info = grouped.setdefault(
            key,
            {
                "function_start": row["function_start"],
                "owner_name": row["owner_name"],
                "primitives": [],
                "callsites": [],
                "writes_a4a4_nearby": False,
            },
        )
        info["primitives"].append(row["primitive"])
        info["callsites"].append(row["site"])
        info["writes_a4a4_nearby"] = info["writes_a4a4_nearby"] or row["writes_a4a4_nearby"]

    summary: list[dict[str, Any]] = []
    for _, info in grouped.items():
        summary.append(
            {
                "function_start": info["function_start"],
                "owner_name": info["owner_name"],
                "primitive_sequence": info["primitives"],
                "callsite_count": len(info["callsites"]),
                "writes_a4a4_nearby": info["writes_a4a4_nearby"],
            }
        )

    summary.sort(key=lambda row: int(row["function_start"], 16))
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Bloody7 flash-call map for adjustgun RE.")
    parser.add_argument("--exe", default=DEFAULT_EXE, help="Path to Bloody7.exe")
    parser.add_argument("--json-out", default="", help="Optional path to write full JSON output")
    parser.add_argument("--target-read8", default="0x55c8cc", type=parse_hex_vma)
    parser.add_argument("--target-write-words", default="0x55ca00", type=parse_hex_vma)
    parser.add_argument("--target-write-words-verify", default="0x55cabc", type=parse_hex_vma)
    parser.add_argument("--target-read-dwords", default="0x55ccb4", type=parse_hex_vma)
    parser.add_argument("--target-write-dwords", default="0x55ce14", type=parse_hex_vma)
    args = parser.parse_args()

    exe_path = Path(args.exe)
    if not exe_path.exists():
        raise FileNotFoundError(f"Missing executable: {exe_path}")

    binary = lief.parse(str(exe_path))
    text = find_text_section(binary)
    imagebase = binary.optional_header.imagebase
    text_vma = imagebase + text.virtual_address
    text_bytes = bytes(text.content)

    targets = {
        args.target_read8: "flash_read8",
        args.target_write_words: "flash_write_words",
        args.target_write_words_verify: "flash_write_words_verify",
        args.target_read_dwords: "flash_read_dwords",
        args.target_write_dwords: "flash_write_dwords",
    }

    rows: list[dict[str, Any]] = []
    for target_vma, primitive in targets.items():
        for callsite_vma in find_rel32_calls(text_bytes, text_vma, target_vma):
            function_start = find_nearest_prologue(text_bytes, text_vma, callsite_vma)
            if function_start is None:
                function_start = callsite_vma
            context = disassemble_range(text_bytes, text_vma, function_start, callsite_vma + 5)
            if not context:
                continue
            owner_name, owner_address = owner_lookup(binary, callsite_vma)
            hints = collect_hints(context)
            rows.append(
                {
                    "site": f"0x{callsite_vma:08x}",
                    "primitive": primitive,
                    "target": f"0x{target_vma:08x}",
                    "function_start": f"0x{function_start:08x}",
                    "owner_name": owner_name,
                    "owner_address": f"0x{owner_address:08x}" if owner_address is not None else None,
                    **hints,
                }
            )

    rows.sort(key=lambda row: int(row["site"], 16))
    function_summary = build_function_summary(rows)
    likely_adjustgun = [
        row
        for row in function_summary
        if ("flash_write_words_verify" in row["primitive_sequence"] or "flash_write_dwords" in row["primitive_sequence"])
        and row["writes_a4a4_nearby"]
    ]

    result = {
        "exe": str(exe_path),
        "imagebase": f"0x{imagebase:08x}",
        "text_vma": f"0x{text_vma:08x}",
        "targets": {name: f"0x{value:08x}" for value, name in targets.items()},
        "row_count": len(rows),
        "rows": rows,
        "function_summary": function_summary,
        "likely_adjustgun_functions": likely_adjustgun,
    }

    print(f"rows={len(rows)} functions={len(function_summary)} likely_adjustgun={len(likely_adjustgun)}")
    for row in likely_adjustgun:
        sequence = " -> ".join(row["primitive_sequence"])
        print(f"{row['function_start']} {row['owner_name'] or 'unknown'} :: {sequence}")

    if args.json_out:
        out_path = Path(args.json_out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(f"wrote {out_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
