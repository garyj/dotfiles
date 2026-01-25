#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pikepdf"]
# ///

"""
pdf_unlock - Remove passwords and unlock PDF files in the current directory.

Usage: pdf_unlock.sh [password]
"""

import sys
from pathlib import Path

import pikepdf


def unlock_pdf(input_path: Path, password: str | None) -> bool:
    """Open the PDF and save a decrypted copy, replacing the original."""
    temp_path = input_path.with_suffix(".tmp.pdf")
    try:
        with pikepdf.open(input_path, password=(password or "")) as pdf:
            pdf.save(temp_path)
        temp_path.replace(input_path)
        return True
    except pikepdf.PasswordError:
        temp_path.unlink(missing_ok=True)
        return False
    except pikepdf.PdfError as e:
        temp_path.unlink(missing_ok=True)
        print(f"  PDF error: {e}")
        return False
    except Exception as e:
        temp_path.unlink(missing_ok=True)
        print(f"  Unexpected error: {e}")
        return False


def main() -> None:
    password = sys.argv[1] if len(sys.argv) > 1 else None

    pdf_files = sorted(Path.cwd().glob("*.pdf"))

    if not pdf_files:
        print("No PDF files found in the current directory.")
        sys.exit(1)

    print(f"Found {len(pdf_files)} PDF file(s) to process...\n")

    success_count = 0
    fail_count = 0

    for pdf_file in pdf_files:
        if unlock_pdf(pdf_file, password):
            print(f"✓ Unlocked: {pdf_file.name}")
            success_count += 1
        else:
            print(f"✗ Skipped: {pdf_file.name} (may require password or is not encrypted)")
            fail_count += 1

    print(f"\nProcessing complete: {success_count} unlocked, {fail_count} skipped")


if __name__ == "__main__":
    main()
