import pandas as pd
import xml.etree.ElementTree as ET
import os
from xml.dom.minidom import parseString

# Define the path to the Excel file
excel_file_path = 'Codelist Excel Files and Conversion Templates to XML/triaxType.xlsx'

# Read the 'DictionaryName' sheet to get the XML file name
dictionary_name_df = pd.read_excel(excel_file_path, sheet_name='DictionaryName')
dictionary_file = dictionary_name_df['DictionaryFile'].dropna().iloc[0].strip()
description = dictionary_name_df['Description'].dropna().iloc[0].strip()

# Construct the XML file path using the extracted name
xml_file_path = f'/workspaces/def/BetaVersion/converted_xml/{dictionary_file}.xml'

# Read the 'Definitions' sheet for data
definitions_df = pd.read_excel(excel_file_path, sheet_name='Definitions')
associated_elements_df = pd.read_excel(excel_file_path, sheet_name='AssociatedElements')


# Namespace map
NS_MAP = {
    "gml": "http://www.opengis.net/gml/3.2",
    "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    "diggs": "http://diggsml.org/schemas/2.6"
}

# Register namespaces
for prefix, uri in NS_MAP.items():
    ET.register_namespace(prefix, uri)

# Create the root element with its namespaces
root_attribs = {
    "{http://www.w3.org/2001/XMLSchema-instance}schemaLocation": "http://diggsml.org/schemas/2.6 https://raw.githubusercontent.com/DIGGSml/diggs-schema/main/Diggs.xsd",
    "{http://www.opengis.net/gml/3.2}id": dictionary_file  # Correct use of the gml namespace
}
root = ET.Element(ET.QName(NS_MAP['gml'], 'Dictionary'), attrib=root_attribs)  # Use gml namespace correctly

# Add sub-elements
description = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'description'))
description.text = description

identifier = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'identifier'), attrib={"codeSpace": "http://diggsml.org/def/codes/DIGGS/authorities.xml#DIGGS"})
identifier.text = dictionary_file + ".xml"

# Populate the XML with data from the 'Definitions' sheet
for _, row in definitions_df.iterrows():
    entry = ET.SubElement(root, 'dictionaryEntry')
    definition = ET.SubElement(entry, ET.QName(NS_MAP['diggs'], 'Definition'), attrib={ET.QName(NS_MAP['gml'], 'id'): row['ID'].strip()})

    # Add detailed elements as per the spreadsheet data
    ET.SubElement(definition, 'description').text = row['Description'].strip()
    ET.SubElement(definition, 'identifier', attrib={"codeSpace": "http://diggsml.org/def/codes/DIGGS/0.1/triaxType.xml"}).text = row['Name'].strip()
    ET.SubElement(definition, 'name', attrib={"codeSpace": "en"}).text = row['Name'].strip()
    ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'dataType')).text = row['DataType'].strip()
    ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'authority')).text = row['Authority'].strip()
    
    # Add occurrences
    occurrences = ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'occurrences'))
    source_elements = associated_elements_df[associated_elements_df['ID'] == row['ID']]['SourceElement']
    for source_element in source_elements:
        occurrence = ET.SubElement(occurrences, ET.QName(NS_MAP['diggs'], 'Occurrence'))
        ET.SubElement(occurrence, ET.QName(NS_MAP['diggs'], 'sourceElementXpath')).text = source_element


# Write the XML to a file, including the XML declaration
ET.ElementTree(root).write(xml_file_path, encoding='utf-8', xml_declaration=True)

print(f"XML file created at: {xml_file_path}")


# Generate the XML string from the ElementTree object
tree_str = ET.tostring(root, 'utf-8')

# Use minidom to pretty-print
dom = parseString(tree_str)
pretty_xml_as_string = dom.toprettyxml(indent="    ")

# Write the pretty-printed XML to a file, including the XML declaration
with open(xml_file_path, 'w', encoding='utf-8') as xml_file:
    xml_file.write(pretty_xml_as_string)

print(f"Pretty-printed XML file created at: {xml_file_path}")
