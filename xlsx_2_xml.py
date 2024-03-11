import pandas as pd
import xml.etree.ElementTree as ET
from xml.dom.minidom import parseString

# Define the path to the Excel file
excel_file_path = '/workspaces/def/Codelist Excel Files and Conversion Templates to XML/roles.xlsx'

# Read the 'DictionaryName' sheet to get the XML file name and description
dictionary_name_df = pd.read_excel(excel_file_path, sheet_name='DictionaryName')
dictionary_file = dictionary_name_df['DictionaryFile'].dropna().iloc[0].strip()
description_text = dictionary_name_df['Description'].dropna().iloc[0].strip()

# Construct the XML file path using the extracted name
xml_file_path = f'/workspaces/def/BetaVersion/converted_xml/{dictionary_file}.xml'

# Read the 'Definitions' and 'AssociatedElements' sheets for data
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
    "{http://www.w3.org/2001/XMLSchema-instance}schemaLocation": "http://diggsml.org/schemas/2.6 https://diggsml.org/schemas/2.6/Diggs.xsd",
    "{http://www.opengis.net/gml/3.2}id": dictionary_file  # Correct use of the gml namespace
}
root = ET.Element(ET.QName(NS_MAP['gml'], 'Dictionary'), attrib=root_attribs)

# Add sub-elements like description and identifier
description = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'description'))
description.text = description_text

identifier = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'identifier'), attrib={"codeSpace": "http://diggsml.org"})
identifier.text = dictionary_file + ".xml"

# Populate the XML with data from the 'Definitions' sheet
for _, row in definitions_df.iterrows():
    entry = ET.SubElement(root, 'dictionaryEntry')
    definition = ET.SubElement(entry, ET.QName(NS_MAP['diggs'], 'Definition'), attrib={ET.QName(NS_MAP['gml'], 'id'): row['ID'].strip()})
    
    # Add detailed elements as per the spreadsheet data
    ET.SubElement(definition, 'description').text = row['Description'].strip()
    ET.SubElement(definition, 'identifier', attrib={"codeSpace": "http://diggsml.org"}).text = row['Name'].strip()
    ET.SubElement(definition, 'name').text = row['Name'].strip()
    ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'dataType')).text = row['DataType'].strip()
    ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'authority')).text = row['Authority'].strip()
    
    # Handle associated elements if necessary

# Convert the ElementTree to a string
tree_str = ET.tostring(root, 'utf-8')

# Use minidom to pretty-print
dom = parseString(tree_str)
pretty_xml_as_string = dom.toprettyxml(indent="    ")

# Manually adjust the order of the XML declaration and the processing instruction
xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'
processing_instruction = '<?xml-stylesheet type="text/xsl" href="https://diggsml.org/def/stylesheets/codelists.xsl"?>\n'
final_xml_str = xml_declaration + processing_instruction + pretty_xml_as_string

# Remove the duplicate XML declaration added by `toprettyxml`
final_xml_str = final_xml_str.replace('<?xml version="1.0" ?>', '', 1)

# Write the final XML string to the file
with open(xml_file_path, 'w', encoding='utf-8') as xml_file:
    xml_file.write(final_xml_str)

print(f"XML file with correct order of declarations created at: {xml_file_path}")
