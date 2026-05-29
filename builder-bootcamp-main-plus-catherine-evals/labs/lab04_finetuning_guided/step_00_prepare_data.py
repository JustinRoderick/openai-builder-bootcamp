"""
Step 0 — Download and prepare the Wine Reviews dataset

This script:
- Downloads the Kaggle Wine Reviews dataset via kagglehub
- Filters to France rows and prunes rare varieties (<5 occurrences)
- Samples a manageable subset (default: 500)
- Writes a processed CSV and a JSON file with the variety enum list

Usage:
    python -m labs.lab04_finetuning_guided.step_00_prepare_data

Environment overrides (optional):
- SAMPLE_SIZE: number of rows to sample (default: 500)
- OUTPUT_DIR: where to write outputs (default: labs/data)
"""

from __future__ import annotations

import json
import os
from typing import List

from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv(), override=True)

try:
    import kagglehub  # type: ignore
except ImportError:
    kagglehub = None  # type: ignore

try:
    import pandas as pd  # type: ignore
except ImportError:
    pd = None  # type: ignore


DEFAULT_OUTPUT_DIR = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "data")
)
SAMPLE_SIZE = int(os.getenv("SAMPLE_SIZE", "500"))
OUTPUT_DIR = os.getenv("OUTPUT_DIR", DEFAULT_OUTPUT_DIR)


def ensure_output_dir(directory_path: str) -> None:
    if directory_path and not os.path.exists(directory_path):
        os.makedirs(directory_path, exist_ok=True)


def download_dataset() -> str:
    """Download the Kaggle dataset and return the directory path containing files.

    Requires `pip install kagglehub` and your Kaggle credentials configured.
    """
    if kagglehub is None:  # pragma: no cover
        raise ImportError(
            "Please install kagglehub: pip install kagglehub"
        )

    dataset_ref = "zynicide/wine-reviews"
    print(f"Downloading dataset: {dataset_ref}")
    path = kagglehub.dataset_download(dataset_ref)
    print(f"Dataset downloaded to: {path}")
    return path


def locate_csv(dataset_dir: str) -> str:
    """Find the CSV file used in this lab within the downloaded directory."""
    candidate = os.path.join(dataset_dir, "winemag-data-130k-v2.csv")
    if os.path.exists(candidate):
        return candidate

    for root, _dirs, files in os.walk(dataset_dir):
        for name in files:
            if name.endswith(".csv") and "winemag" in name:
                return os.path.join(root, name)
    raise FileNotFoundError("Could not find the Kaggle CSV (winemag-data-130k-v2.csv)")


def process_dataset(csv_path: str, sample_size: int) -> tuple[object, List[str]]:
    if pd is None:  # pragma: no cover
        raise ImportError("Please install pandas: pip install pandas")

    df = pd.read_csv(csv_path)
    df_france = df[df["country"] == "France"].copy()

    counts = df_france["variety"].value_counts()
    rare_varieties = counts[counts < 5].index.tolist()
    df_france = df_france[~df_france["variety"].isin(rare_varieties)].copy()

    if sample_size > 0 and sample_size < len(df_france):
        df_france_subset = df_france.sample(n=sample_size, random_state=42).copy()
    else:
        df_france_subset = df_france.copy()

    varieties = (
        df_france["variety"].astype(str).dropna().unique().tolist()
    )
    varieties = sorted(set(varieties))

    return df_france_subset, varieties


def write_outputs(df_subset: object, varieties: List[str], out_dir: str) -> tuple[str, str]:
    ensure_output_dir(out_dir)
    csv_out = os.path.join(out_dir, "wine_france_subset.csv")
    json_out = os.path.join(out_dir, "varieties.json")

    df_subset.to_csv(csv_out, index=False)
    with open(json_out, "w", encoding="utf-8") as handle:
        json.dump({"varieties": varieties}, handle, ensure_ascii=False, indent=2)

    return csv_out, json_out


def run() -> None:
    dataset_dir = download_dataset()
    csv_path = locate_csv(dataset_dir)
    df_subset, varieties = process_dataset(csv_path, SAMPLE_SIZE)
    csv_out, json_out = write_outputs(df_subset, varieties, OUTPUT_DIR)

    print("\n" + "-" * 80)
    print(f"Wrote subset CSV: {csv_out}")
    print(f"Wrote varieties JSON: {json_out}")
    print(f"Rows: {len(df_subset)} | Varieties: {len(varieties)}")


if __name__ == "__main__":
    run()
