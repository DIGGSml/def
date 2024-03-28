<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:diggs="http://diggsml.org/schemas/2.6" xmlns:gml="http://www.opengis.net/gml/3.2"
  xmlns:xlink="http://www.w3.org/1999/xlink">

  <xsl:template match="/">

    <html>
      <head>

        <style>
          body {
          background-color: #f7f0c6;
          }
          
          h1 {
          text-align: center;
          color: #21130d;
          font-family: 'Crimson Text', serif;
          }
          
          h2 {
          text-align: center;
          color: #21130d;
          font-family: 'Crimson Text', serif;
          }
          
          .logo {
          position: absolute;
          top: 10px;
          left: 10px;
          float: left;
          }
          
          .description {
          font-family: 'Crimson Text', serif;
          border: 2px solid black;
          padding: 5px;
          text-align: left;
          font-size: 20px;
          background-color: none;
          color: #21130d;
          display: inline-block;
          max-width: 1000px;
          
          }
          
          #counter {
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
          font-size: 14px;
          padding: 5px;
          
          }
          
          .fixed_header {
          overflow-y: auto;
          max-height: 650px;
          }
          
          .fixed_header div {
          box-shadow: 0 0 12px black;
          }
          
          .fixed_header table {
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
          border-collapse: collapse;
          width: 100%;
          background-color: #f2f2f2;
          }
          
          .fixed_header th {
          position: sticky;
          top: 0;
          padding-top: 12px;
          padding-bottom: 12px;
          text-align: center;
          background-color: black;
          color: #FFFFFF;
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
          }
          
          .fixed_header td {
          padding: 8px;
          text-align: left;
          border-bottom: 2px solid gray;
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
          font-size: 18px;
          cursor: pointer;
          }
          
          .selected {
          color: white;
          }
          
          .fixed_header tr:nth-child(even) {
          background-color: #f2f2f2;
          }
          
          .fixed_header tr:nth-child(odd) {
          background-color: #DCDCDC;
          }
          
          #instance {
          text-align: center;
          font-size: 14px;
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
          color: black;
          font-weight: bold;
          border: 2px solid black;
          padding: 5px;
          display: inline-block;
          background-color: #f2f2f2;
          }
          #instance p {
          line-height: 12px;
          margin-top: 10px;
          }
          
          #myInput {
          background-image: url('https://diggsml.org/def/img/searchIcon.png');
          background-size: 30px;
          background-position: 8px 6px; /* Position the search icon */
          background-color: none;
          background-repeat: no-repeat; /* Do not repeat the icon image */
          width: 30%; /* Percentage of screen width */
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
          font-size: 16px; /* Increase font-size */
          padding: 12px 20px 12px 40px; /* Add some padding */
          border: 1px solid #ddd; /* Add a grey border */
          margin-bottom: 12px; /* Add some space below the input */
          margin-top: 12px;
          }
          
          .hiddenFlds {
          display: none;
          }
          
        </style>
        <link href="https://fonts.googleapis.com/css?family=Crimson+Text|Graduate|Lobster|Quicksand"
          rel="stylesheet"/>
        
        <script src="https://diggsml.org/def/scripts/scripts.js"/>
        
      </head>
      <body>
        <div>
          <div class="logo">
            <img src= "https://diggsml.org/def/img/diggs-logo.png" style="width:150px"/>
          </div>
          <h1>
            <xsl:value-of select="gml:Dictionary/gml:name"/>
          </h1>
          
          <div style="text-align: center">
            <span class="description">
              <strong>
                <xsl:value-of select="gml:Dictionary/gml:description"/>
              </strong>
            </span>
          </div>
        </div>
        <div style="text-align: center">
          <span>
            <input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search..."/>
          </span>
          <span id="counter"></span>
        </div>
        <div class="fixed_header">
          <table id="myTable">
            <tr>
              <th>Name</th>
              <th>&#x20;&#x20;&#x20;ID&#x20;&#x20;&#x20;</th>
              <th>Definition</th>
              <th>Source Element XPath</th>
              <th>Authority</th>
              <th>Reference</th>
            </tr>
            <xsl:for-each select="gml:Dictionary/gml:dictionaryEntry/diggs:Definition">
              <!--        <xsl:sort select="diggs:occurences/diggs:Occurrence/diggs:sourceElementXpath"/> -->
              <xsl:sort select="./gml:namd"/>
              <tr>
                <td>
                  <xsl:value-of select="./gml:name"/>
                </td>
                <td>
                  <xsl:value-of select="@gml:id"/>
                </td>
                <td>
                  <xsl:value-of select="./gml:description"/>
                </td>
                 <td>
                  <xsl:for-each select="./diggs:occurrences/diggs:Occurrence">
                    <xsl:value-of select="./diggs:sourceElementXpath"/>
                    <br/>
                  </xsl:for-each>
                </td>
                <td>
                  <xsl:value-of select="./diggs:authority"/>
                </td>
                <td>
                  <xsl:element name="a">
                    <xsl:attribute name="href">
                      <xsl:value-of select="./diggs:reference"/>
                    </xsl:attribute>
                    <xsl:attribute name="target">_blank</xsl:attribute>
                    <xsl:value-of select="./diggs:reference"/>
                  </xsl:element>
                </td>
                
              </tr>
            </xsl:for-each>
          </table>
        </div>
        <p/>
        <div style="text-align:center">
          <span id = "instance">Click on row to see example instance</span>
        </div>
        <div class="hiddenflds">
          <p id="gmlid">
            <xsl:value-of select="/gml:Dictionary/@gml:id"/>
          </p>
          <p id="url"><xsl:value-of select="gml:Dictionary/@gml:id"/> codeSpace="<xsl:value-of
            select="./gml:Dictionary/gml:identifier"/>
          </p>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
