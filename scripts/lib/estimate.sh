#!/usr/bin/env bash
# Print estimate of token usage & cost for the current work-plan.
# No API calls.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PLAN_FILE="$STATE_DIR/work-plan.json"
[ -f "$PLAN_FILE" ] || die "No work-plan.json — run resolve first."

CHAPTER="$(jq -r '.chapter' "$PLAN_FILE")"
SRC="$(abs_source_repo)"

INPUT_PRICE_DEFAULT="$(yaml_get '.run.pricing.default.input_per_mtok' | tr -d '"')"
OUTPUT_PRICE_DEFAULT="$(yaml_get '.run.pricing.default.output_per_mtok' | tr -d '"')"
INPUT_PRICE_COMPLEX="$(yaml_get '.run.pricing.complex.input_per_mtok' | tr -d '"')"
OUTPUT_PRICE_COMPLEX="$(yaml_get '.run.pricing.complex.output_per_mtok' | tr -d '"')"

python3 - "$PLAN_FILE" "$SRC" "$CONFIG_FILE" \
    "$INPUT_PRICE_DEFAULT" "$OUTPUT_PRICE_DEFAULT" \
    "$INPUT_PRICE_COMPLEX" "$OUTPUT_PRICE_COMPLEX" <<'PYEOF'
import sys, json, yaml, glob, os

plan_path, src, config_path, ipd, opd, ipc, opc = sys.argv[1:8]
ipd, opd, ipc, opc = float(ipd), float(opd), float(ipc), float(opc)

plan = json.load(open(plan_path))
cfg = yaml.safe_load(open(config_path))
chapter = plan["chapter"]
ch_cfg = cfg["chapters"][chapter]

def sources_for(slug):
    for d in ch_cfg["docs"]:
        if d["slug"] == slug:
            return d["sources"]
    return []

def expand_and_measure(patterns):
    total = 0
    files = 0
    for pat in patterns:
        for p in sorted(glob.glob(os.path.join(src, pat), recursive=True)):
            if os.path.isfile(p):
                try:
                    total += os.path.getsize(p)
                    files += 1
                except OSError:
                    pass
    return total, files

total_in, total_out, total_cost = 0, 0, 0.0
rows = []
for item in plan["items"]:
    if item["status"] != "to_generate":
        continue
    bytes_, n_files = expand_and_measure(sources_for(item["slug"]))
    in_tok = bytes_ // 4
    out_tok = int(in_tok * 0.3) * 2  # zh + en
    if item["model"] == "complex":
        cost = (in_tok * ipc + out_tok * opc) / 1_000_000
    else:
        cost = (in_tok * ipd + out_tok * opd) / 1_000_000
    total_in += in_tok
    total_out += out_tok
    total_cost += cost
    rows.append((item["slug"], n_files, in_tok, out_tok, cost))

print(f"Chapter '{chapter}' — {len(rows)} doc(s) to generate:")
print(f"  {'slug':<30} {'files':>6} {'tok_in':>8} {'tok_out':>8} {'$':>8}")
for slug, n, ti, to, c in rows:
    print(f"  {slug:<30} {n:>6} {ti:>8,} {to:>8,} {c:>7.3f}")
print(f"  {'TOTAL':<30} {'':>6} {total_in:>8,} {total_out:>8,} {total_cost:>7.3f}")
print(f"\nEstimate: ~${total_cost:.2f} USD total (model pricing from config.yaml)")
PYEOF
