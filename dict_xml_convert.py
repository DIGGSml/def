#!/usr/bin/env python3
"""dict_xml_convert.py — regenerate DIGGS dictionary XML from the Codelist Excel workbooks.

A new application, not a revision of xlsx_2_xml.py (left in place, unmodified, as the
existing codespace reference). Built for RI_Build_Plan_3.md X11 + X11a:

  X11  — binds generated dictionaries to the schemas/3 namespace (every workbook
         currently produces schemas/2.6, stale against the current Diggs.xsd).
  X11a — reads the AlternateNames sheet, which xlsx_2_xml.py has never read, and
         emits each row as an additional gml:name on the matching Definition
         (gml:name is [1..unbounded] on DefinitionBaseType — Dictionary_diggs.xsd:24).

All other behavior — sheet layout, column names, the codelists.xsl/propertylists.xsl
stylesheet choice, the blank-row/placeholder-row tolerance, root gml:id sourced from
the workbook's own "Dictionary ID" cell — is unchanged from xlsx_2_xml.py.

Run with no arguments, from anywhere, in this repo or a fresh clone (paths resolve
relative to this file, not a hardcoded /workspaces/def/ prefix):

    python3 dict_xml_convert.py

By default this only reconverts a workbook whose git history (or working-tree state)
is newer than its generated XML's git history — see needs_regeneration(). Flags:

    --all       force regeneration of every dictionary, regardless of git history
                (use once after a generator change, e.g. this namespace migration —
                incremental staleness checking can never detect "the generator
                itself changed," only "an input file changed")
    --dry-run   report what would be (re)generated; write nothing
    --only ID   regenerate a single workbook by its DictionaryFile value, regardless
                of staleness (debugging)
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.dom.minidom import parseString

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parent
WORKBOOK_DIR = REPO_ROOT / "Codelist Excel Files and Conversion Templates to XML"
OUTPUT_DIR = REPO_ROOT / "docs" / "codes" / "DIGGS" / "0.1"

GML_NS = "http://www.opengis.net/gml/3.2"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
DIGGS_NS = "http://diggsml.org/schemas/3"  # X11 — was schemas/2.6

NS_MAP = {"": GML_NS, "gml": GML_NS, "xsi": XSI_NS, "diggs": DIGGS_NS}

SCHEMA_LOCATION = f"{DIGGS_NS} https://diggsml.org/schemas/3.0.0/Diggs.xsd"
AUTHORITY_CODESPACE = "https://diggsml.org/def/authorities.xml#DIGGS"
DICTIONARY_URL_BASE = "https://diggsml.org/def/codes/DIGGS/0.1/"

# Leaf tags known to hold free text that may contain a literal ". Re-escaping this
# set to &quot; makes output byte-identical regardless of which Python's xml.dom.minidom
# happens to run the script (this is the "quote-escaping artifact" the
# def-dictionary-authoring skill otherwise handles as a separate manual step).
# Deliberately an explicit tag list, not a wildcard — see that skill's §5 for why a
# wildcard here once corrupted gml:id attributes on an enclosing container element.
QUOTE_ESCAPE_LEAF_TAGS = (
    "gml:description",
    "gml:name",
    "diggs:authority",
    "diggs:reference",
    "diggs:conditionalElementXpath",
    "diggs:sourceElementXpath",
)

# pandas.read_excel's default na_values list includes the literal strings "None",
# "N/A", "NA", "NULL", "n/a", "null", etc. - so a cell containing exactly one of
# those words, as legitimate content, silently reads as NaN, indistinguishable from
# an empty cell. Real cases in this corpus: governingSpecificationSource#none's
# Name is literally "None"; grout_inj_properties has a QuantityClass of "N/A".
# Every read below passes keep_default_na=False so those survive as strings, and
# every blank-check in this file goes through _is_blank/_cell_text rather than
# pd.isna()/pd.notna()/.dropna() directly - under keep_default_na=False a genuinely
# empty cell reads as "" rather than NaN, which those would not treat as blank.
EXCEL_READ_KWARGS = {"keep_default_na": False}


def _is_blank(value: object) -> bool:
    """True for a missing cell or one containing only whitespace - not for a cell
    that merely looks like a pandas NA sentinel (e.g. "None", "N/A")."""
    if pd.isna(value):
        return True
    return not str(value).strip()


def _cell_text(value: object) -> str | None:
    """value with surrounding whitespace stripped, or None if the cell is blank."""
    return None if _is_blank(value) else str(value).strip()


def _first_nonblank(series: pd.Series, n: int = 0) -> str:
    """The (n+1)th non-blank value in series, in row order - a blank-aware
    replacement for the series.dropna().iloc[n] pattern xlsx_2_xml.py uses, which
    (like bare pd.isna()) only recognizes NaN, not "" from a keep_default_na=False
    read."""
    values = [v for v in series if not _is_blank(v)]
    return str(values[n]).strip()


def git_last_commit_epoch(path: Path) -> int | None:
    """Unix timestamp of path's most recent commit, or None if it has no commit
    history (new/untracked, or the path doesn't exist)."""
    try:
        rel = path.relative_to(REPO_ROOT)
    except ValueError:
        rel = path
    result = subprocess.run(
        ["git", "log", "-1", "--format=%ct", "--", str(rel)],
        cwd=REPO_ROOT, capture_output=True, text=True, check=False,
    )
    out = result.stdout.strip()
    return int(out) if out else None


def has_uncommitted_changes(path: Path) -> bool:
    """True if path has staged or unstaged changes, or is untracked."""
    try:
        rel = path.relative_to(REPO_ROOT)
    except ValueError:
        rel = path
    result = subprocess.run(
        ["git", "status", "--porcelain", "--", str(rel)],
        cwd=REPO_ROOT, capture_output=True, text=True, check=False,
    )
    return bool(result.stdout.strip())


def needs_regeneration(xlsx_path: Path, xml_path: Path) -> bool:
    """True if xlsx_path is newer than xml_path by git history, xml_path doesn't
    exist yet, either side's history is unknown, or xlsx_path has uncommitted edits
    (git log alone can't see those — this is what actually makes local iteration on
    a workbook, then running this script before committing, work as expected)."""
    if not xml_path.exists():
        return True
    if has_uncommitted_changes(xlsx_path):
        return True
    xlsx_commit = git_last_commit_epoch(xlsx_path)
    xml_commit = git_last_commit_epoch(xml_path)
    if xlsx_commit is None or xml_commit is None:
        return True  # can't prove it's current; safe default is to regenerate
    return xlsx_commit > xml_commit


def peek_dictionary_target(xlsx_path: Path) -> tuple[str, str]:
    """Read only the DictionaryName sheet — cheap enough to do for every workbook
    up front, since dictionary_file is needed to even know which XML path to check
    for staleness (DictionaryFile does not always match the workbook's own
    basename — e.g. astmD2488Brdr.xlsx -> astm2488Brdr.xml)."""
    df = pd.read_excel(xlsx_path, sheet_name="DictionaryName", **EXCEL_READ_KWARGS)
    dictionary_file = _first_nonblank(df["DictionaryFile"], 0)
    dictionary_id = _first_nonblank(df["Dictionary ID"], 0)
    return dictionary_file, dictionary_id


def build_dictionary_xml(xlsx_path: Path, dictionary_file: str, dictionary_id: str) -> tuple[str, list[str]]:
    """Full conversion: Definitions + AssociatedElements + AlternateNames -> one
    pretty-printed XML document string. Returns (xml_text, warnings)."""
    warnings: list[str] = []

    dictionary_name_df = pd.read_excel(xlsx_path, sheet_name="DictionaryName", **EXCEL_READ_KWARGS)
    description_text = _first_nonblank(dictionary_name_df["Description"], 1)
    dictionary_name = _first_nonblank(dictionary_name_df["DictionaryName"], 0)

    definitions_df = pd.read_excel(xlsx_path, sheet_name="Definitions", **EXCEL_READ_KWARGS)
    associated_elements_df = pd.read_excel(xlsx_path, sheet_name="AssociatedElements", **EXCEL_READ_KWARGS)
    workbook_sheets = pd.ExcelFile(xlsx_path).sheet_names
    if "AlternateNames" in workbook_sheets:
        alternate_names_df = pd.read_excel(xlsx_path, sheet_name="AlternateNames", **EXCEL_READ_KWARGS)
    else:
        # Older workbooks predate the AlternateNames sheet being added to the
        # template. No sheet is equivalent to an empty one, not an error.
        alternate_names_df = pd.DataFrame(columns=["Start", "ID", "Name", "codeSpace"])

    is_conditional_element_empty = associated_elements_df["ConditionalElement"].apply(_is_blank).all()
    processing_instruction = (
        '<?xml-stylesheet type="text/xsl" href="https://diggsml.org/def/stylesheets/'
        + ("codelists.xsl" if is_conditional_element_empty else "propertylists.xsl")
        + '"?>\n'
    )

    for prefix, uri in NS_MAP.items():
        ET.register_namespace(prefix, uri)

    root = ET.Element(
        ET.QName(GML_NS, "Dictionary"),
        attrib={
            ET.QName(XSI_NS, "schemaLocation"): SCHEMA_LOCATION,
            ET.QName(GML_NS, "id"): dictionary_id,
        },
    )
    ET.SubElement(root, ET.QName(GML_NS, "description")).text = description_text
    identifier = ET.SubElement(
        root, ET.QName(GML_NS, "identifier"), attrib={"codeSpace": AUTHORITY_CODESPACE}
    )
    identifier.text = DICTIONARY_URL_BASE + dictionary_file + ".xml"
    ET.SubElement(root, ET.QName(GML_NS, "name")).text = dictionary_name

    # X11a — pre-group AlternateNames rows by the Definition ID they alias. A row
    # whose ID matches no real Definition (the template's own placeholder example
    # row — ID "LFS" in every unfilled AlternateNames sheet, including the blank
    # .xltx itself) is silently dropped by never being looked up below, the same
    # way AssociatedElements already tolerates an unmatched ID today.
    alt_names_by_id: dict[str, list[tuple[str, str | None]]] = {}
    for _, row in alternate_names_df.iterrows():
        alt_id = _cell_text(row.get("ID"))
        alt_name = _cell_text(row.get("Name"))
        if alt_id is None or alt_name is None:
            continue
        code_space = _cell_text(row.get("codeSpace"))
        alt_names_by_id.setdefault(alt_id, []).append((alt_name, code_space))

    matched_alt_ids: set[str] = set()

    # A workbook can carry trailing rows past its real data (Excel extends the
    # "used range" from stray formatting/clicks) that read back as blank-ID rows
    # under keep_default_na=False, rather than vanishing the way a NaN ID would
    # have against .dropna()-style code. xlsx_2_xml.py has no guard against this
    # either - str(row['ID']).strip() there would write gml:id="" just the same -
    # it simply never met a workbook with such rows before. A blank ID is not an
    # incomplete Definition (which still warrants the Description/Name warnings
    # below); it carries no data at all, so it is not a Definition to attempt.
    skipped_blank_id_rows = 0
    for _, row in definitions_df.iterrows():
        definition_id = _cell_text(row["ID"])
        if definition_id is None:
            skipped_blank_id_rows += 1
            continue
        entry = ET.SubElement(root, ET.QName(GML_NS, "dictionaryEntry"))
        definition = ET.SubElement(
            entry, ET.QName(DIGGS_NS, "Definition"), attrib={ET.QName(GML_NS, "id"): definition_id}
        )

        entry_description = _cell_text(row["Description"])
        if entry_description is not None:
            ET.SubElement(definition, ET.QName(GML_NS, "description")).text = entry_description
        else:
            warnings.append(f"{dictionary_file}#{definition_id}: no Description (gml:description is mandatory)")

        name_text = _cell_text(row["Name"])
        if name_text is not None:
            identifier = ET.SubElement(
                definition, ET.QName(GML_NS, "identifier"), attrib={"codeSpace": AUTHORITY_CODESPACE}
            )
            identifier.text = DICTIONARY_URL_BASE + dictionary_file + ".xml#" + definition_id
            ET.SubElement(definition, ET.QName(GML_NS, "name")).text = name_text

            for alt_name, alt_code_space in alt_names_by_id.get(definition_id, []):
                attrib = {"codeSpace": alt_code_space} if alt_code_space else {}
                ET.SubElement(definition, ET.QName(GML_NS, "name"), attrib=attrib).text = alt_name
            if definition_id in alt_names_by_id:
                matched_alt_ids.add(definition_id)
        else:
            warnings.append(
                f"{dictionary_file}#{definition_id}: no Name (gml:identifier and gml:name are both "
                "mandatory; neither was written, matching xlsx_2_xml.py's existing gating on this "
                "column — this dictionary entry does not validate against Dictionary_diggs.xsd)"
            )
            if definition_id in alt_names_by_id:
                warnings.append(
                    f"{dictionary_file}#{definition_id}: has AlternateNames rows but no primary Name, "
                    "so the alternates were dropped along with the primary gml:name"
                )

        for tag, column in (
            ("dataType", "DataType"),
            ("quantityClass", "QuantityClass"),
            ("authority", "Authority"),
            ("reference", "Reference"),
        ):
            value = _cell_text(row[column])
            if value is not None:
                ET.SubElement(definition, ET.QName(DIGGS_NS, tag)).text = value

    if skipped_blank_id_rows:
        warnings.append(
            f"{dictionary_file}: {skipped_blank_id_rows} blank-ID row(s) in Definitions "
            "skipped (no data in any column - not an incomplete entry, just past the real data)"
        )

    for alt_id in alt_names_by_id:
        if alt_id not in matched_alt_ids and alt_id != "LFS":
            warnings.append(f"{dictionary_file}: AlternateNames row ID '{alt_id}' matches no Definition")

    skipped_blank_id_assoc_rows = 0
    for _, row in associated_elements_df.iterrows():
        definition_id = _cell_text(row["ID"])
        if definition_id is None:
            skipped_blank_id_assoc_rows += 1
            continue
        source_element = _cell_text(row["SourceElement"])
        conditional_element = _cell_text(row["ConditionalElement"])

        for definition in root.findall(f".//{{{DIGGS_NS}}}Definition"):
            if definition.get(ET.QName(GML_NS, "id")) == definition_id:
                occurrences = definition.find(f".//{{{DIGGS_NS}}}occurrences")
                if occurrences is None:
                    occurrences = ET.SubElement(definition, ET.QName(DIGGS_NS, "occurrences"))
                occurrence = ET.SubElement(occurrences, ET.QName(DIGGS_NS, "Occurrence"))
                if source_element:
                    ET.SubElement(occurrence, ET.QName(DIGGS_NS, "sourceElementXpath")).text = source_element
                if conditional_element:
                    ET.SubElement(occurrence, ET.QName(DIGGS_NS, "conditionalElementXpath")).text = conditional_element
                break

    if skipped_blank_id_assoc_rows:
        warnings.append(
            f"{dictionary_file}: {skipped_blank_id_assoc_rows} blank-ID row(s) in AssociatedElements "
            "skipped (no data in any column - not an incomplete entry, just past the real data)"
        )

    tree_str = ET.tostring(root, "utf-8")
    dom = parseString(tree_str)
    pretty_xml_as_string = dom.toprettyxml(indent="    ")

    xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'
    final_xml_str = xml_declaration + processing_instruction + pretty_xml_as_string
    final_xml_str = final_xml_str.replace('<?xml version="1.0" ?>', "", 1)
    final_xml_str = reescape_quotes(final_xml_str)

    # fail loudly rather than write output that isn't even well-formed
    ET.fromstring(final_xml_str)

    return final_xml_str, warnings


def reescape_quotes(xml_text: str) -> str:
    tag_group = "|".join(re.escape(t) for t in QUOTE_ESCAPE_LEAF_TAGS)
    pattern = re.compile(rf"<({tag_group})>(.*?)</\1>", re.S)

    def fix(m: re.Match) -> str:
        return f"<{m.group(1)}>" + m.group(2).replace('"', "&quot;") + f"</{m.group(1)}>"

    return pattern.sub(fix, xml_text)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--all", action="store_true", help="regenerate every dictionary regardless of git history")
    parser.add_argument("--dry-run", action="store_true", help="report what would change; write nothing")
    parser.add_argument("--only", metavar="DICTIONARY_FILE", help="regenerate a single workbook by its DictionaryFile value, regardless of staleness (debugging)")
    args = parser.parse_args()

    if not WORKBOOK_DIR.is_dir():
        print(f"error: workbook directory not found: {WORKBOOK_DIR}", file=sys.stderr)
        return 1
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    converted: list[str] = []
    skipped: list[str] = []
    errors: list[str] = []
    all_warnings: list[str] = []

    for xlsx_path in sorted(WORKBOOK_DIR.glob("*.xlsx")):
        if xlsx_path.name.startswith("~$"):
            continue  # Excel/Office lock file for a workbook currently open elsewhere
        try:
            dictionary_file, dictionary_id = peek_dictionary_target(xlsx_path)
        except Exception as exc:
            errors.append(f"{xlsx_path.name}: could not read DictionaryName sheet ({exc})")
            continue

        if args.only and dictionary_file != args.only:
            continue

        xml_path = OUTPUT_DIR / f"{dictionary_file}.xml"

        if not args.all and not args.only and not needs_regeneration(xlsx_path, xml_path):
            skipped.append(dictionary_file)
            continue

        try:
            xml_text, warnings = build_dictionary_xml(xlsx_path, dictionary_file, dictionary_id)
        except Exception as exc:
            errors.append(f"{dictionary_file}: conversion failed ({exc})")
            continue

        all_warnings.extend(warnings)
        converted.append(dictionary_file)

        if not args.dry_run:
            xml_path.write_text(xml_text, encoding="utf-8")

    verb = "would convert" if args.dry_run else "converted"
    print(f"{verb}: {len(converted)}")
    for name in converted:
        print(f"  {name}")
    print(f"skipped (up to date): {len(skipped)}")
    if errors:
        print(f"errors: {len(errors)}")
        for e in errors:
            print(f"  ERROR: {e}")
    if all_warnings:
        print(f"warnings: {len(all_warnings)}")
        for w in all_warnings:
            print(f"  WARNING: {w}")

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
