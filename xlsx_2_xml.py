import pandas as pd
import xml.etree.ElementTree as ET
from xml.dom import minidom
 
# Function to prettify the XML output (for human readability)
def prettify(elem):
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="    ")

# Load the Excel file
# (The actual file path would need to be provided here, assuming 'definitions.xlsx' as a placeholder)
excel_file_path = '/workspaces/diggs-dictionaries/2.5a/DIGGSTestPropertyDefinitions.xlsx'
xml_file_path = '/mnt/data/dictionary.xml'


# Read the 'Definitions' and 'AssociatedElements' sheets into Pandas DataFrames
definitions_df = pd.read_excel(excel_file_path, sheet_name='Definitions')
associated_elements_df = pd.read_excel(excel_file_path, sheet_name='AssociatedElements')

# Create the root element of the XML
root = ET.Element("Dictionary")
root.set("xmlns", "http://diggsml.org/schemas/2.5.a")
root.set("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
root.set("xsi:schemaLocation", "http://diggsml.org/schemas/2.5.a https://diggsml.org/schemas/2.5.a/Dictionary_diggs.xsd")
root.set("xmlns:xlink", "http://www.w3.org/1999/xlink")
root.set("xmlns:gml", "http://www.opengis.net/gml/3.2")
root.set("xmlns:diggs", "http://diggsml.org/schemas/2.5.a")
root.set("gml:id", "measurement_property_class")

# Add the description element
description = ET.SubElement(root, "gml:description")
description.text = """Dictionary enumerating the values for the element "property_class" of the object "Property" used within the Test and Monitor DIGGS features at these XPath locations: ...

    These values serve to define the "results" of geotechnical and environmental tests and monitoring activities that result from test procedures and monitoring sensors, but that may not specifically bound to the procedures that produce the results."""

# Add the identifier element
identifier = ET.SubElement(root, "gml:identifier")
identifier.set("codeSpace", "http://diggsml.org/terms")
identifier.text = "DIGGS measurement property classes"

# Iterate over the rows in the 'Definitions' DataFrame and create dictionaryEntry elements
for _, row in definitions_df.iterrows():
    dictionary_entry = ET.SubElement(root, "dictionaryEntry")
    definition = ET.SubElement(dictionary_entry, "Definition")
    definition.set("gml:id", row['Code'])
    
    def_description = ET.SubElement(definition, "gml:description")
    def_description.text = row['Description']
    
    def_identifier = ET.SubElement(definition, "gml:identifier")
    def_identifier.set("codeSpace", "http://diggsml.org/terms")
    def_identifier.text = row['Name']
    
    data_type = ET.SubElement(definition, "dataType")
    data_type.text = row['Data type']
    
    uom_type = ET.SubElement(definition, "uomType")
    uom_type.text = row['UOMType']
    
    authority = ET.SubElement(definition, "authority")
    authority.text = row['Authority'] if pd.notna(row['Authority']) else ""
    
    # Find associated elements for this code
    associated_elements = associated_elements_df[associated_elements_df['Code'] == row['Code']]['Element'].tolist()
    for element in associated_elements:
        associated_element = ET.SubElement(definition, "associatedElement")
        associated_element.text = element

# Convert the created XML structure into a string with indentation
xmlstr = prettify(root)

# Output the XML to a file

with open(xml_file_path, 'w') as xml_file:
    xml_file.write(xmlstr)

xml_file_path
