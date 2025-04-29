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
                    #loadingOverlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background-color: rgba(255, 255, 255, 0.9);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    z-index: 9999;
                    }
                    .loading-spinner {
                    border: 16px solid #f3f3f3;
                    border-top: 16px solid #3498db;
                    border-radius: 50%;
                    width: 80px;
                    height: 80px;
                    animation: spin 2s linear infinite;
                    margin-bottom: 20px;
                    }
                    .loading-text {
                    font-size: 24px;
                    font-weight: bold;
                    text-align: center;
                    }
                    @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                    }
                    .loading-container {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    }
                    /* Hide content initially */
                    .main-content {
                    display: none;
                    }
                </style>
                <script type="text/javascript">
                    // Initialize table data
                    var tableData = [];
                    var totalRows = 0;
                    var debounceTimeout = null;
                    
                    // Create and show loading overlay immediately when the page starts loading
                    document.write('<div id="loadingOverlay"><div class="loading-container"><div class="loading-spinner"></div><div class="loading-text">Loading... Please wait</div></div></div>');
                    
                    // Hide loading overlay
                    function hideLoading() {
                    var overlay = document.getElementById('loadingOverlay');
                    if (overlay) {
                        document.body.removeChild(overlay);
                    }
                    // Show main content
                    document.getElementById('mainContent').style.display = 'block';
                    }
                    
                    // Pre-process the table data for faster filtering
                    function initializeTableData() {
                    var table = document.getElementById("unitTable");
                    var rows = table.getElementsByTagName("tr");
                    totalRows = rows.length - 2; // Subtract 2 header rows
                    
                    // Store searchable data for each row
                    for (var i = 2; i < rows.length; i++) { // Start from index 2 (after 2 header rows)
                        var cells = rows[i].getElementsByTagName("td");
                        var rowData = {
                        element: rows[i],
                        searchText: ""
                        };
                        
                        // Include columns we want to search (0, 1, 2, 3, 4, 5, 15) - Added column 15 (Underlying Definition)
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
                    
                    // Update the row count display initially
                    updateRowCount(totalRows);
                    
                    // Hide loading overlay and show content
                    hideLoading();
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
                    
                    // Set up event listeners when the document is loaded
                    window.onload = function() {
                    // Initialize the table data for faster searching
                    setTimeout(function() {
                        initializeTableData();
                        
                        var input = document.getElementById("filterInput");
                        
                        // Real-time filtering with debouncing
                        input.addEventListener('input', debounceFilter);
                        
                        // Apply filter when Enter key is pressed (immediate, no debounce)
                        input.addEventListener('keypress', function(event) {
                        if (event.key === 'Enter') {
                            if (debounceTimeout) {
                            clearTimeout(debounceTimeout);
                            }
                            filterTable();
                            // Prevent form submission if within a form
                            event.preventDefault();
                        }
                        });
                    }, 10); // Short delay to ensure DOM is ready
                    };
                </script>
            </head>
            <body>
                <!-- Main content wrapped in a div that's initially hidden -->
                <div id="mainContent" class="main-content">
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
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>