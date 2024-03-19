import pandas as pd
import glob
import xml.etree.ElementTree as ET
from xml.dom.minidom import parseString

def xlsx_2_xml(excel_file_path):
    # Read the 'DictionaryName' sheet to get the XML file name and description
    dictionary_name_df = pd.read_excel(excel_file_path, sheet_name='DictionaryName')
    dictionary_file = dictionary_name_df['DictionaryFile'].dropna().iloc[0].strip()
    description_text = dictionary_name_df['Description'].dropna().iloc[1].strip()
    dictionary_name = dictionary_name_df['DictionaryName'].dropna().iloc[0].strip()
    dictionary_id = dictionary_name_df['Dictionary ID'].dropna().iloc[0].strip()

    # Construct the XML file path using the extracted name
    xml_file_path = f'/workspaces/def/codes/DIGGS/0.1/{dictionary_file}.xml'

    # Read the 'Definitions' and 'AssociatedElements' sheets for data
    definitions_df = pd.read_excel(excel_file_path, sheet_name='Definitions')
    associated_elements_df = pd.read_excel(excel_file_path, sheet_name='AssociatedElements')


    # Check if the entire 'ConditionalElement' column is empty
    is_conditional_element_empty = associated_elements_df['ConditionalElement'].isna().all()

    if is_conditional_element_empty:
        processing_instruction = '<?xml-stylesheet type="text/xsl" href="https://diggsml.org/def/stylesheets/codelists.xsl"?>\n'
    else:
        processing_instruction = '<?xml-stylesheet type="text/xsl" href="https://diggsml.org/def/stylesheets/propertylists.xsl"?>\n'


    # print(definitions_df)
    # print(associated_elements_df)

    # Namespace map
    NS_MAP = {
        "":"http://www.opengis.net/gml/3.2",
        "gml": "http://www.opengis.net/gml/3.2",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "diggs": "http://diggsml.org/schemas/2.6",
    }

    # Register namespaces
    for prefix, uri in NS_MAP.items():
        ET.register_namespace(prefix, uri)

    # Create the root element with its namespaces
    root_attribs = {
        "{http://www.w3.org/2001/XMLSchema-instance}schemaLocation": "http://diggsml.org/schemas/2.6 https://diggsml.org/schemas/2.6/Diggs.xsd",
        "{http://www.opengis.net/gml/3.2}id": dictionary_id  # Correct use of the gml namespace
    }
    root = ET.Element(ET.QName(NS_MAP['gml'], 'Dictionary'), attrib=root_attribs)

    # Add sub-elements like description and identifier with the gml prefix
    description = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'description'))
    description.text = description_text

    # Corrected identifier element: Removed gml prefix from codeSpace attribute
    identifier = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'identifier'), attrib={'codeSpace': "https://diggsml.org/def/authorities.xml#DIGGS"})
    identifier.text = "https://diggsml.org/def/codes/DIGGS?0.1/" + dictionary_file + ".xml"

    # Add sub-element name with the gml prefix
    name = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'name'))
    name.text = dictionary_name


    # Populate the XML with data from the 'Definitions' sheet, using the 'gml' prefix for GML elements
    for _, row in definitions_df.iterrows():
        entry = ET.SubElement(root, ET.QName(NS_MAP['gml'], 'dictionaryEntry'))
        definition = ET.SubElement(entry, ET.QName(NS_MAP['diggs'], 'Definition'), attrib={ET.QName(NS_MAP['gml'], 'id'): str(row['ID']).strip()})
        
        # Check and add elements only if they are not blank
        if pd.notna(row['Description']) and row['Description'].strip():
            ET.SubElement(definition, ET.QName(NS_MAP['gml'], 'description')).text = row['Description'].strip()
        if pd.notna(row['Name']) and row['Name'].strip():
            identifier_attrib = {'codeSpace': "https://diggsml.org/def/authorities.xml#DIGGS"}
            identifier = ET.SubElement(definition, ET.QName(NS_MAP['gml'], 'identifier'), attrib=identifier_attrib)
            identifier.text = "https://diggsml.org/def/codes/DIGGS?0.1/" + dictionary_file + ".xml#" + row['ID'].strip()
            ET.SubElement(definition, ET.QName(NS_MAP['gml'], 'name')).text = row['Name'].strip()
        if pd.notna(row['DataType']) and row['DataType'].strip():
            ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'dataType')).text = str(row['DataType']).strip()
        if pd.notna(row['Authority']) and row['Authority'].strip():
            ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'authority')).text = str(row['Authority']).strip()
        if pd.notna(row['Reference']) and row['Reference'].strip():
            ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'reference')).text = str(row['Reference']).strip()


    for _, row in associated_elements_df.iterrows():
        # Find the parent definition element by matching the ID
        definition_id = str(row['ID']).strip()  # Assuming there's an 'ID' column to match with definitions
        source_element = str(row['SourceElement']).strip() if pd.notna(row['SourceElement']) else None  # The XPath or other identifier
        conditional_element = str(row['ConditionalElement']).strip() if pd.notna(row['ConditionalElement']) else None  # The XPath or other identifier
        
        # Find the definition element this occurrence is associated with
        for definition in root.findall(f".//{{{NS_MAP['diggs']}}}Definition"):
            if definition.get(ET.QName(NS_MAP['gml'], 'id')) == definition_id:
                # Once the correct definition is found, create the occurrences element if not already present
                occurrences = definition.find(f".//{{{NS_MAP['diggs']}}}occurrences")
                if occurrences is None:  # If there's no occurrences element, create one
                    occurrences = ET.SubElement(definition, ET.QName(NS_MAP['diggs'], 'occurrences'))
                
                # Add the Occurrence element
                occurrence = ET.SubElement(occurrences, ET.QName(NS_MAP['diggs'], 'Occurrence'))
                
                if source_element:
                    source_element_xpath = ET.SubElement(occurrence, ET.QName(NS_MAP['diggs'], 'sourceElementXpath'))
                    source_element_xpath.text = source_element
                
                if conditional_element:
                    conditional_element_xpath = ET.SubElement(occurrence, ET.QName(NS_MAP['diggs'], 'conditionalElementXpath'))
                    conditional_element_xpath.text = conditional_element

                break  # Exit the loop once the occurrence is added to the correct definition



    # Convert the ElementTree to a string
    tree_str = ET.tostring(root, 'utf-8')

    # Use minidom to pretty-print
    dom = parseString(tree_str)
    pretty_xml_as_string = dom.toprettyxml(indent="    ")

    # Manually adjust the order of the XML declaration and the processing instruction
    xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'

    final_xml_str = xml_declaration + processing_instruction + pretty_xml_as_string

    # Remove the duplicate XML declaration added by `toprettyxml`
    final_xml_str = final_xml_str.replace('<?xml version="1.0" ?>', '', 1)

    # Write the final XML string to the file
    with open(xml_file_path, 'w', encoding='utf-8') as xml_file:
        xml_file.write(final_xml_str)

    return(f"XML file with correct order of declarations created at: {xml_file_path}")

# Replace 'your_directory_path' with the path to your directory
for xlsx_file in glob.glob('/workspaces/def/Codelist Excel Files and Conversion Templates to XML/*.xlsx'):
    print(xlsx_2_xml(xlsx_file))