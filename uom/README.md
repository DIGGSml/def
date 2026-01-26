# Energistics UOM Dictionary Excel Conversion Tools

A suite of tools for converting between Energistics Unit of Measure Dictionary XML files and Excel workbooks for easier inspection and editing.

## Overview

These tools provide a bidirectional conversion between XML UOM dictionaries and Excel workbooks:

- **XML → Excel**: Parse an XML UOM dictionary and populate an Excel template
- **Excel → XML**: Read a populated Excel workbook and generate an XML UOM dictionary

## Files Included

1. `uom_dictionary_template.xlsx` - Excel template with structured worksheets
2. `uom_xml_to_excel.py` - Convert XML to Excel
3. `excel_to_uom_xml.py` - Convert Excel to XML

## Excel Template Structure

The template contains 6 worksheets:

### 1. Metadata
- Dictionary version
- **Namespace** (automatically captured from XML)
- **Schema Location** (automatically captured for xsi:schemaLocation)
- Title
- Originator  
- Description (long text with wrapping)

**Note:** Namespace and Schema Location are preserved during round-trip conversions to ensure exact XML reconstruction.

### 2. Unit Dimensions
Columns: Name, Dimension, Base For Conversion, Canonical Unit, Description

### 3. Quantity Classes
Columns: Name, Dimension, Base For Conversion, Alternative Base, Description, Member Units (comma-separated)

### 4. Units
Columns: Symbol, Name, Dimension, Is SI, Category, Is Base, Base Unit, Conversion Ref, Is Exact, A, B, C, D, Underlying Def, Description

**Note**: If "Is Base" = TRUE, leave Base Unit and conversion parameters (A,B,C,D) empty.

### 5. References
Columns: ID, Description

### 6. Prefixes
Columns: Symbol, Name, Multiplier, Common Name

## Usage

### Prerequisites

```bash
pip install openpyxl
```

### XML to Excel Conversion

Convert an Energistics UOM Dictionary XML file to Excel:

```bash
python uom_xml_to_excel.py <input_xml> <template_xlsx> <output_xlsx>
```

**Example:**
```bash
python uom_xml_to_excel.py uom_dictionary.xml uom_dictionary_template.xlsx uom_output.xlsx
```

The script will:
- Parse the XML file (handles namespaces automatically)
- Populate each worksheet with the corresponding data
- Save the populated Excel workbook

### Excel to XML Conversion

Convert a populated Excel workbook back to XML:

```bash
python excel_to_uom_xml.py <input_xlsx> <output_xml> [namespace]
```

**Example:**
```bash
python excel_to_uom_xml.py uom_output.xlsx uom_dictionary_new.xml
```

**With custom namespace:**
```bash
python excel_to_uom_xml.py uom_output.xlsx uom_dictionary_new.xml http://www.energistics.org/energyml/data/uomv2
```

Default namespace: `http://www.energistics.org/energyml/data/uomv1`

## Workflow Examples

### Inspect and Edit an Existing Dictionary

1. Convert XML to Excel for easy viewing:
   ```bash
   python uom_xml_to_excel.py original.xml uom_dictionary_template.xlsx working.xlsx
   ```

2. Open `working.xlsx` in Excel, make your edits

3. Convert back to XML:
   ```bash
   python excel_to_uom_xml.py working.xlsx updated.xml
   ```

### Create a New Dictionary

1. Start with the blank template: `uom_dictionary_template.xlsx`

2. Fill in the worksheets with your UOM data

3. Generate the XML:
   ```bash
   python excel_to_uom_xml.py my_uom_data.xlsx my_dictionary.xml
   ```

## Data Entry Guidelines

### Unit Dimensions
- **Name**: The identifier for the dimension concept
- **Dimension**: The dimensional analysis (e.g., L, M/T2)
- **Base For Conversion**: Symbol of the base unit for this dimension
- **Canonical Unit**: SI base unit expression
- **Description**: Optional explanatory text

### Quantity Classes
- **Member Units**: Enter as comma-separated list (e.g., "m, ft, in")
- **Alternative Base**: Only needed when multiple classes share same dimension
- Can have multiple member units per class

### Units
- **Is Base**: Enter TRUE for base units, FALSE otherwise
- **Conversion Parameters**: Only fill if Is Base = FALSE
  - Formula: y = (A + Bx) / (C + Dx)
  - Where x is the unit to convert, y is the result in base unit
- **Is SI**: Enter true/false or 1/0
- **Is Exact**: Enter true/false or 1/0 for conversion precision

### References
- **ID**: Unique identifier for the reference
- **Description**: Full citation or reference information

### Prefixes
- **Symbol**: Short prefix symbol (e.g., "k", "M", "m")
- **Name**: Full name (e.g., "kilo", "mega", "milli")
- **Multiplier**: Numeric multiplier (e.g., "1000", "1000000", "0.001")
- **Common Name**: Optional English phrase (e.g., "thousand", "million")

## Features

### XML Parsing
- Handles namespaced XML automatically
- Supports both explicit and local-name element matching
- Gracefully handles optional elements
- **Preserves XML namespace declarations (xmlns, xmlns:xsi)**
- **Preserves xsi:schemaLocation for exact header reconstruction**

### Excel Population
- Color-coded headers for easy navigation
- Frozen header rows for scrolling
- Appropriate column widths pre-set
- Clear notes for complex sections
- **Namespace and schema location stored in metadata**

### Round-Trip Compatibility
- Preserves all data through XML → Excel → XML cycle
- Maintains structure and semantics
- Handles optional elements correctly
- **Exactly preserves XML header with xmlns and xsi:schemaLocation**
- **Namespace declarations automatically maintained**

## Troubleshooting

### "Could not find uomDictionary root element"
- Ensure your XML file has a `uomDictionary` root element
- Check that the XML is well-formed

### Missing Data in Excel
- Verify the XML structure matches the expected schema
- Check for namespace issues in the XML file

### Empty Conversion Parameters
- This is normal for base units (Is Base = TRUE)
- Only non-base units require conversion parameters

### Member Units Not Appearing
- In Quantity Classes, ensure member units are comma-separated
- Extra spaces around commas are automatically trimmed

## Schema Compliance

These tools are designed to work with the Energistics UOM Dictionary schema structure as defined in the provided XSD. The conversion maintains:

- Element ordering as per schema
- Required vs optional elements
- Choice elements (isBase vs conversion parameters)
- Repeating elements (member units)

## Future Enhancements

Potential improvements:
- XML schema validation
- Data validation rules in Excel
- Formula conversion calculator
- Unit conversion tester
- Dimension consistency checker

## Support

For issues or questions about:
- **Schema interpretation**: Refer to Energistics UOM Dictionary documentation
- **Tool functionality**: Check this README or examine the Python scripts
- **Excel formatting**: Review the template structure
