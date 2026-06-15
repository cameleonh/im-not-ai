from __future__ import annotations

import json
import sys
from pathlib import Path

from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions
from docling.document_converter import DocumentConverter, PdfFormatOption


def make_converter(do_ocr: bool) -> DocumentConverter:
    options = PdfPipelineOptions()
    options.do_ocr = do_ocr
    return DocumentConverter(
        format_options={InputFormat.PDF: PdfFormatOption(pipeline_options=options)}
    )


def parse_pdf(converter: DocumentConverter, pdf_path: Path, output_dir: Path) -> dict:
    result = converter.convert(pdf_path)
    markdown = result.document.export_to_markdown()
    markdown_path = output_dir / f"{pdf_path.stem}.md"
    markdown_path.write_text(markdown, encoding="utf-8")
    return {
        "source_pdf": str(pdf_path),
        "markdown": str(markdown_path),
        "characters": len(markdown),
        "lines": markdown.count("\n") + 1,
    }


def main() -> int:
    args = [arg for arg in sys.argv[1:] if arg != "--ocr"]
    do_ocr = "--ocr" in sys.argv[1:]
    source_dir = Path(args[0]) if len(args) > 0 else Path("_style_sources/pdf")
    output_dir = Path(args[1]) if len(args) > 1 else Path("_style_sources/parsed")
    output_dir.mkdir(parents=True, exist_ok=True)

    pdfs = [source_dir] if source_dir.is_file() else sorted(source_dir.glob("*.pdf"))
    if not pdfs:
        print(f"No PDF files found: {source_dir}", file=sys.stderr)
        return 1

    converter = make_converter(do_ocr)
    manifest = []
    for pdf_path in pdfs:
        print(f"Parsing {pdf_path}")
        manifest.append(parse_pdf(converter, pdf_path, output_dir))

    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Wrote {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
