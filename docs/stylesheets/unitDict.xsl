<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:uom="http://www.energistics.org/energyml/data/uomv1">
    
    <xsl:output method="html" indent="yes" encoding="UTF-8"/>
    
    <xsl:template match="/">
        <html>
            <head>
                <title>DIGGS Unit of Measure Dictionary</title>
                <style>
                    body {
                    font-family: Arial, sans-serif;
                    margin: 0;
                    padding: 0;
                    background-color: #FFEFD5; /* Light amber background */
                    }
                    .header-container {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    padding: 10px 20px;
                    }
                    .logo {
                    flex: 0 0 150px;
                    }
                    .title-container {
                    flex: 1;
                    text-align: center;
                    }
                    h1 {
                    margin: 0;
                    }
                    .description-container {
                    border: 2px solid black;
                    padding: 5px;
                    text-align: left;
                    background-color: none;
                    display: block; /* Changed from inline-block to block */
                    max-width: 1000px;
                    margin: 0 auto; /* Added auto margins for centering */
                    }
                    
                    .search-row {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    padding: 20px;
                    gap: 20px;
                    }
                    #filterInput {
                    padding: 8px;
                    width: 500px;
                    font-size: 16px;
                    }
                    #rowCount {
                    font-weight: bold;
                    min-width: 200px;
                    }
                    table {
                    border-collapse: collapse;
                    width: 100%;
                    background-color: white;
                    }
                    .container {
                    background-color: white;
                    margin: 0 20px 20px 20px;
                    max-height: 70vh;
                    overflow-y: auto;
                    }
                    th, td {
                    border-right: 1px solid #ddd;
                    border-left: 1px solid #ddd;     
                    padding: 8px;
                    text-align: left;
                    }
                    /* Modified header styling to make both rows sticky */
                    #unitTable tr:nth-child(1) th {
                    position: sticky;
                    top: 0;
                    background-color: #000000;
                    color: white;
                    font-weight: bold;
                    text-align: center;
                    vertical-align: middle;
                    z-index: 2; /* Higher z-index for first row */
                    padding: 10px 5px;
                    height: 40px;
                    }
                    #unitTable tr:nth-child(2) th {
                    position: sticky;
                    top: 59px; /* Adjusted: Height of first header row + padding - 1px */
                    background-color: #000000;
                    color: white;
                    font-weight: bold;
                    text-align: center;
                    vertical-align: middle;
                    z-index: 1;
                    padding: 10px 5px;
                    height: 40px;
                    }
                    /* Style for alternating quantity classes */
                    .quantity-class-even {
                    background-color: #aaaaaa; /*grey */
                    }
                    .quantity-class-odd {
                    background-color: #ffffff; /* White */
                    }
                    /* Row border styling */
                    tr {
                    border-top: 2px solid #000;
                    border-bottom: 2px solid #000;
                    }
                    tr:hover {
                    background-color: #e6f2ff; /* Light blue */
                    }
                    /* Loading overlay styles */
                    #loading-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    background-color: #FFEFD5;
                    z-index: 9999;
                    }
                    #loader {
                    border: 16px solid #f3f3f3;
                    border-radius: 50%;
                    border-top: 16px solid #3498db;
                    width: 120px;
                    height: 120px;
                    animation: spin 2s linear infinite;
                    }
                    .loading-text {
                    margin-top: 20px;
                    font-size: 24px;
                    font-weight: bold;
                    }
                    #progress-text {
                    margin-top: 10px;
                    font-size: 16px;
                    }
                    @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                    }
                </style>
            </head>
            <body>
                <div id="loading-overlay">
                    <div class="logo">
                        <img src="https://diggsml.org/def/img/diggs-logo.png" style="width:150px"/>
                    </div>
                    <div id="loader"></div>
                    <div class="loading-text">Loading DIGGS Unit Dictionary...</div>
                    <div id="progress-text">Initializing...</div>
                </div>
                
                <div class="header-container">
                    <div class="logo">
                        <img src="https://diggsml.org/def/img/diggs-logo.png" style="width:150px"/>
                    </div>
                    <div class="title-container">
                        <h1><xsl:value-of select="/uomDictionary/title | /uom:uomDictionary/uom:title"/></h1>
                    </div>
                    <!-- Empty div to balance the flex layout -->
                    <div style="flex: 0 0 150px;"></div>
                </div>
                <div style="text-align: center;"> <!-- Added wrapper div with center alignment -->
                    <span class="description-container"><xsl:value-of select="/uom:uomDictionary/uom:description | /uomDictionary/description"/></span>
                </div>
                
                <div class="search-row">
                    <input type="text" id="filterInput" placeholder="Filter by name, description, symbol, dimension, or definition..."/>
                    <div id="rowCount"></div>
                </div>
                
                <div class="container">
                    <table id="unitTable">
                        <tr>
                            <th colspan="11"/>
                            <th colspan="4">Conversion Coefficients<br/>y=(A + Bx)/(C + Dx)</th>
                            <th/>
                        </tr>
                        <tr>
                            <th>Unit<br/>Symbol</th>
                            <th>Unit<br/>Name</th>
                            <th>Unit<br/>Description</th>
                            <th>Quantity Class<br/>Name</th>
                            <th>Quantity Class<br/>Description</th>
                            <th>Dimension</th>
                            <th>Is SI</th>
                            <th>Category</th>
                            <th>Base Unit</th>
                            <th>Conversion<br/>Reference</th>
                            <th>Conversion<br/>Exact?</th>
                            <th>A</th>
                            <th>B</th>
                            <th>C</th>
                            <th>D</th>
                            <th>Underlying<br/>Definition</th>
                        </tr>
                        
                        <!-- Process each quantityClass in order by name -->
                        <xsl:for-each select="//uom:quantityClassSet/uom:quantityClass | //quantityClassSet/quantityClass">
                            <xsl:sort select="uom:name | name"/>
                            
                            <xsl:variable name="qcName" select="uom:name | name"/>
                            <xsl:variable name="qcDescription" select="uom:description | description"/>
                            <xsl:variable name="qcPosition" select="position()"/>
                            <xsl:variable name="rowClass">
                                <xsl:choose>
                                    <xsl:when test="$qcPosition mod 2 = 1">quantity-class-odd</xsl:when>
                                    <xsl:otherwise>quantity-class-even</xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            
                            <!-- For each memberUnit in this quantityClass -->
                            <xsl:for-each select="uom:memberUnit | memberUnit">
                                <xsl:variable name="memberUnitValue" select="normalize-space(.)"/>
                                
                                <!-- Find the matching unit in unitSet based on symbol -->
                                <xsl:for-each select="//uom:unitSet/uom:unit[normalize-space(uom:symbol) = $memberUnitValue] | 
                                    //unitSet/unit[normalize-space(symbol) = $memberUnitValue]">
                                    <xsl:if test="position() = 1"> <!-- Only use the first matching unit if there are duplicates -->
                                        <tr class="{$rowClass}">
                                            <td><xsl:value-of select="uom:symbol | symbol"/></td>
                                            <td><xsl:value-of select="uom:name | name"/></td>
                                            <td><xsl:value-of select="uom:description | description"/></td>
                                            <!-- Repeat quantityClass info for each row (no rowspan) -->
                                            <td><xsl:value-of select="$qcName"/></td>
                                            <td><xsl:value-of select="$qcDescription"/></td>
                                            
                                            <!-- Display unit info from the matching unit element -->
                                            <td><xsl:value-of select="uom:dimension | dimension"/></td>
                                            <td><xsl:value-of select="uom:isSI | isSI"/></td>
                                            <td><xsl:value-of select="uom:category | category"/></td>
                                            <td><xsl:value-of select="uom:baseUnit | baseUnit"/></td>
                                            <td><xsl:value-of select="uom:conversionRef | conversionRef"/></td>
                                            <td><xsl:value-of select="uom:isExact | isExact"/></td>
                                            <td><xsl:value-of select="uom:A | A"/></td>
                                            <td><xsl:value-of select="uom:B | B"/></td>
                                            <td><xsl:value-of select="uom:C | C"/></td>
                                            <td><xsl:value-of select="uom:D | D"/></td>
                                            <td><xsl:value-of select="uom:underlyingDef | underlyingDef"/></td>
                                        </tr>
                                    </xsl:if>
                                </xsl:for-each>
                                
                                <!-- If no matching unit was found, create a row with just the quantityClass and memberUnit info -->
                                <xsl:if test="not(//uom:unitSet/uom:unit[normalize-space(uom:symbol) = $memberUnitValue] | 
                                    //unitSet/unit[normalize-space(symbol) = $memberUnitValue])">
                                    <tr class="{$rowClass}">
                                        <!-- Repeat quantityClass info for each row (no rowspan) -->
                                        <td><xsl:value-of select="$memberUnitValue"/></td>
                                        <td><xsl:value-of select="$qcName"/></td>
                                        <td><xsl:value-of select="$qcDescription"/></td>
                                        <td colspan="13">No matching unit found in unitSet</td>
                                    </tr>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </table>
                </div>
                
                <script>
                <![CDATA[
                    // Initialize variables
                    var tableData = [];
                    var totalRows = 0;
                    var debounceTimeout = null;
                    
                    // Function to update the loading progress text
                    function updateProgress(message) {
                        var progressText = document.getElementById('progress-text');
                        if (progressText) {
                            progressText.textContent = message;
                        }
                    }
                    
                    // Hide loading overlay when content is ready
                    function hideLoading() {
                        var overlay = document.getElementById('loading-overlay');
                        if (overlay) {
                            overlay.style.display = 'none';
                        }
                    }
                    
                    // Pre-process the table data for faster filtering
                    function initializeTableData() {
                        updateProgress("Processing table data...");
                        
                        // Get table rows
                        var table = document.getElementById("unitTable");
                        if (!table) {
                            console.error("Table element not found!");
                            return;
                        }
                        
                        var rows = table.getElementsByTagName("tr");
                        if (!rows || rows.length < 3) {
                            console.error("Not enough rows in table!");
                            return;
                        }
                        
                        totalRows = rows.length - 2; // Subtract 2 header rows
                        
                        // Process in chunks to prevent UI freezing
                        var processedRows = 0;
                        var chunkSize = 200; // Process 200 rows at a time
                        
                        function processChunk() {
                            var endRow = Math.min(processedRows + chunkSize + 2, rows.length);
                            
                            for (var i = processedRows + 2; i < endRow; i++) {
                                var cells = rows[i].getElementsByTagName("td");
                                var rowData = {
                                    element: rows[i],
                                    searchText: ""
                                };
                                
                                // Include columns we want to search (0, 1, 2, 3, 4, 5, 15)
                                var columnsToSearch = [0, 1, 2, 3, 4, 5, 15];
                                for (var j = 0; j < columnsToSearch.length; j++) {
                                    var colIndex = columnsToSearch[j];
                                    if (colIndex < cells.length) {
                                        var cellText = cells[colIndex].textContent || cells[colIndex].innerText;
                                        rowData.searchText += cellText.toUpperCase() + " ";
                                    }
                                }
                                
                                tableData.push(rowData);
                            }
                            
                            processedRows += chunkSize;
                            
                            // Update progress
                            var percentComplete = Math.min(100, Math.round((processedRows / totalRows) * 100));
                            updateProgress("Processing table: " + percentComplete + "% complete...");
                            
                            if (processedRows < totalRows) {
                                // Process next chunk asynchronously
                                setTimeout(processChunk, 0);
                            } else {
                                // Processing complete
                                updateRowCount(totalRows);
                                updateProgress("Table processing complete!");
                                
                                // Set up the filter input event listener
                                var input = document.getElementById("filterInput");
                                if (input) {
                                    input.addEventListener('input', debounceFilter);
                                    input.addEventListener('keypress', function(event) {
                                        if (event.key === 'Enter') {
                                            if (debounceTimeout) {
                                                clearTimeout(debounceTimeout);
                                            }
                                            filterTable();
                                            event.preventDefault();
                                        }
                                    });
                                }
                                
                                // Hide loading overlay
                                setTimeout(hideLoading, 500);
                            }
                        }
                        
                        // Start processing the first chunk
                        setTimeout(processChunk, 0);
                    }
                    
                    function updateRowCount(visibleRows) {
                        var countElement = document.getElementById("rowCount");
                        if (countElement) {
                            countElement.textContent = "Showing " + visibleRows + " of " + totalRows + " records";
                        }
                    }
                    
                    function filterTable() {
                        // Get input value
                        var input = document.getElementById("filterInput");
                        if (!input) return;
                        
                        var filter = input.value.toUpperCase();
                        var visibleRows = 0;
                        
                        // Use the pre-processed data for faster filtering
                        for (var i = 0; i < tableData.length; i++) {
                            var visible = filter === "" || tableData[i].searchText.indexOf(filter) > -1;
                            tableData[i].element.style.display = visible ? "" : "none";
                            if (visible) {
                                visibleRows++;
                            }
                        }
                        
                        // Update the row count display
                        updateRowCount(visibleRows);
                    }
                    
                    // Debounce function to avoid excessive filtering for fast typers
                    function debounceFilter() {
                        if (debounceTimeout) {
                            clearTimeout(debounceTimeout);
                        }
                        debounceTimeout = setTimeout(function() {
                            filterTable();
                        }, 250); // 250ms delay
                    }
                    
                    // Initialize the page
                    document.addEventListener('DOMContentLoaded', function() {
                        // Start table data processing after a short delay
                        setTimeout(initializeTableData, 100);
                    });
                ]]>
                </script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>