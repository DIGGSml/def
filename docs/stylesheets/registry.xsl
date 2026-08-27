<?xml version="1.0" encoding="UTF-8"?>

<!--
  Renders a DIGGS Specification Registry as a browsable, searchable page.

  Companion to codelists.xsl / propertylists.xsl, but deliberately NOT columnar: a registry entry
  carries a bibliographic record with many optional fields, most of them long, so one row per entry
  would be mostly empty cells and unreadable titles. Each entry is rendered as a card holding a
  key/value table instead, and only the fields actually present are shown.

  The page has one job beyond lookup: telling a data provider how to CITE what they found. Every
  card therefore ends with a ready-to-paste xlink:href snippet, built from the registry's own
  gml:identifier and the Specification's gml:id.

  NOTE THE NAMESPACE. Registries are authored against http://diggsml.org/schemas/3. The published
  code list dictionaries still declare http://diggsml.org/schemas/2.6, which is why codelists.xsl
  binds that instead - do not copy the prefix binding from that file.

  Behaviour lives in https://diggsml.org/def/scripts/registry.js
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:diggs="http://diggsml.org/schemas/3" xmlns:gml="http://www.opengis.net/gml/3.2"
  xmlns:xlink="http://www.w3.org/1999/xlink">

  <xsl:output method="html" indent="yes"/>

  <!-- The registry's canonical URL, used to build every citation snippet. -->
  <xsl:variable name="registryUrl" select="normalize-space(/diggs:SpecificationRegistry/gml:identifier)"/>

  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:value-of select="/diggs:SpecificationRegistry/gml:name"/></title>
        <style>
          body {
            font-family: Arial, Helvetica, sans-serif;
            margin: 0;
            padding: 0 0 60px 0;
            background-color: #FFEFD5; /* Light amber background, matching the code list pages */
            color: #1a1a1a;
          }

          .logo { position: absolute; top: 10px; left: 10px; }

          h1 { text-align: center; margin: 0 0 12px 0; padding-top: 18px; }

          .description {
            border: 2px solid black;
            padding: 8px 12px;
            text-align: left;
            display: inline-block;
            max-width: 1000px;
            line-height: 1.45;
          }

          .toolbar { text-align: center; margin-top: 14px; }

          #myInput {
            background-image: url('https://diggsml.org/def/img/searchIcon.png');
            background-size: 26px;
            background-position: 8px 8px;
            background-repeat: no-repeat;
            width: 40%;
            min-width: 260px;
            font-size: 16px;
            padding: 12px 20px 12px 44px;
            border: 1px solid #bbb;
            margin: 4px 0 6px 0;
          }

          #counter { font-size: 14px; padding: 5px; display: inline-block; }

          .hint { font-size: 13px; color: #555; margin: 2px 0 14px 0; }

          .cards { max-width: 1100px; margin: 0 auto; padding: 0 16px; }

          .card {
            background-color: #f7f7f7;
            border: 1px solid #999;
            box-shadow: 0 1px 5px rgba(0,0,0,.28);
            margin-bottom: 18px;
            padding: 0;
          }

          .card-head {
            background-color: #000;
            color: #fff;
            padding: 10px 14px;
            display: flex;
            flex-wrap: wrap;
            align-items: baseline;
            gap: 10px;
          }

          .card-head .nm { font-size: 18px; font-weight: bold; }

          .card-head .id {
            font-family: Consolas, "Courier New", monospace;
            font-size: 15px;
            background: #fff;
            color: #000;
            padding: 2px 8px;
            border-radius: 3px;
          }

          .badge {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: .04em;
            padding: 2px 8px;
            border-radius: 10px;
            font-weight: bold;
          }
          .badge.active     { background:#1e7a34; color:#fff; }
          .badge.superseded { background:#b06a00; color:#fff; }
          .badge.withdrawn  { background:#a01818; color:#fff; }

          table.kv { border-collapse: collapse; width: 100%; }

          table.kv th {
            text-align: left;
            vertical-align: top;
            width: 210px;
            padding: 7px 14px;
            background-color: #e4e4e4;
            border-bottom: 1px solid #cfcfcf;
            font-size: 14px;
            white-space: nowrap;
          }

          table.kv td {
            padding: 7px 14px;
            border-bottom: 1px solid #cfcfcf;
            font-size: 15px;
            line-height: 1.45;
          }

          table.kv tr:last-child th, table.kv tr:last-child td { border-bottom: none; }

          code, .mono { font-family: Consolas, "Courier New", monospace; font-size: 14px; }

          .xpath {
            display: block;
            background: #ececec;
            border-left: 3px solid #888;
            padding: 3px 8px;
            margin: 2px 0;
            word-break: break-all;
          }

          .cite {
            border-top: 2px solid #000;
            background: #fffdf5;
            padding: 10px 14px;
          }

          .cite-label {
            font-size: 13px;
            font-weight: bold;
            display: block;
            margin-bottom: 6px;
          }

          .cite-code {
            display: block;
            background: #1e1e1e;
            color: #e8e8e8;
            padding: 10px 12px;
            white-space: pre-wrap;
            word-break: break-all;
            font-family: Consolas, "Courier New", monospace;
            font-size: 13.5px;
            line-height: 1.5;
          }

          .copy-btn {
            margin-top: 8px;
            font-size: 13px;
            padding: 5px 12px;
            border: 1px solid #666;
            background: #eee;
            cursor: pointer;
          }
          .copy-btn:hover { background: #ddd; }
          .copy-btn.copied { background:#1e7a34; color:#fff; border-color:#1e7a34; }

          a { color: #10457f; }

          .noresults {
            display: none;
            text-align: center;
            font-size: 17px;
            padding: 40px 10px;
            color: #444;
          }
        </style>
        <script src="https://diggsml.org/def/scripts/registry.js"/>
      </head>

      <body>
        <div class="logo">
          <img src="https://diggsml.org/def/img/diggs-logo.png" style="width:150px" alt="DIGGS"/>
        </div>

        <h1><xsl:value-of select="/diggs:SpecificationRegistry/gml:name"/></h1>

        <div style="text-align:center">
          <span class="description">
            <xsl:value-of select="/diggs:SpecificationRegistry/gml:description"/>
          </span>
        </div>

        <div class="toolbar">
          <div>
            <input type="text" id="myInput" onkeyup="filterRegistry()"
              placeholder="Search standards, identifiers, XPaths..."/>
          </div>
          <div id="counter"></div>
          <div class="hint">
            Find the standard you need, then copy the citation snippet at the foot of its card.
          </div>
        </div>

        <!-- The registry's own URL, read by registry.js to build citation snippets. -->
        <span id="registryUrl" style="display:none"><xsl:value-of select="$registryUrl"/></span>

        <div class="cards" id="cards">
          <xsl:for-each select="/diggs:SpecificationRegistry/diggs:registryEntry/diggs:SpecificationRegistryEntry">
            <xsl:sort select="diggs:specification/diggs:Specification/gml:name"/>
            <xsl:apply-templates select="."/>
          </xsl:for-each>
        </div>

        <div class="noresults" id="noresults">No standard matches that search.</div>
      </body>
    </html>
  </xsl:template>

  <!-- ============ one registry entry ============ -->
  <xsl:template match="diggs:SpecificationRegistryEntry">
    <xsl:variable name="spec" select="diggs:specification/diggs:Specification"/>
    <xsl:variable name="id" select="$spec/@gml:id"/>
    <xsl:variable name="status">
      <xsl:choose>
        <xsl:when test="diggs:registryStatus"><xsl:value-of select="diggs:registryStatus"/></xsl:when>
        <xsl:otherwise>active</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <div class="card">
      <div class="card-head">
        <span class="nm"><xsl:value-of select="$spec/gml:name"/></span>
        <span class="id"><xsl:value-of select="$id"/></span>
        <span class="badge {$status}"><xsl:value-of select="$status"/></span>
      </div>

      <table class="kv">
        <xsl:if test="$spec/gml:description">
          <tr><th>Description</th><td><xsl:value-of select="$spec/gml:description"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:standardReferenceNumber">
          <tr><th>Reference number</th>
            <td class="mono"><xsl:value-of select="$spec/diggs:standardReferenceNumber"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:standardTitle">
          <tr><th>Title</th><td><xsl:value-of select="$spec/diggs:standardTitle"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:standardVersion">
          <tr><th>Version</th><td><xsl:value-of select="$spec/diggs:standardVersion"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:standardPart">
          <tr><th>Part</th><td><xsl:value-of select="$spec/diggs:standardPart"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:standardClause">
          <tr><th>Clause</th><td><xsl:value-of select="$spec/diggs:standardClause"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:shortMethodName">
          <tr><th>Short method name</th><td><xsl:value-of select="$spec/diggs:shortMethodName"/></td></tr>
        </xsl:if>
        <xsl:if test="$spec/diggs:accreditingBody or $spec/diggs:accredtingBody">
          <tr><th>Accrediting body</th>
            <td>
              <xsl:value-of select="$spec/diggs:accreditingBody"/>
              <xsl:value-of select="$spec/diggs:accredtingBody"/>
            </td></tr>
        </xsl:if>

        <!-- registration metadata: about the entry, not the standard -->
        <xsl:if test="diggs:authority">
          <tr><th>Registry authority</th><td><xsl:value-of select="diggs:authority"/></td></tr>
        </xsl:if>
        <xsl:if test="diggs:reference">
          <tr><th>Publisher link</th>
            <td>
              <a target="_blank" href="{diggs:reference}"><xsl:value-of select="diggs:reference"/></a>
            </td></tr>
        </xsl:if>
        <xsl:if test="diggs:supersededByRef/@xlink:href">
          <tr><th>Superseded by</th>
            <td class="mono">
              <a href="{diggs:supersededByRef/@xlink:href}">
                <xsl:value-of select="diggs:supersededByRef/@xlink:href"/>
              </a>
            </td></tr>
        </xsl:if>

        <tr>
          <th>May be cited at</th>
          <td>
            <xsl:choose>
              <xsl:when test="diggs:occurrences/diggs:Occurrence">
                <xsl:for-each select="diggs:occurrences/diggs:Occurrence">
                  <span class="xpath"><xsl:value-of select="diggs:sourceElementXpath"/></span>
                  <xsl:if test="diggs:conditionalElementXpath">
                    <span class="xpath">
                      <xsl:text>&#8627; only when: </xsl:text>
                      <xsl:value-of select="diggs:conditionalElementXpath"/>
                    </span>
                  </xsl:if>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <em>Unrestricted &#8212; may be cited wherever a diggs:Specification is permitted.</em>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
      </table>

      <!-- Citation snippet. The element name is taken from the FIRST occurrence's XPath so the
           example shows the property this standard is actually meant to be cited from. -->
      <div class="cite">
        <span class="cite-label">Cite it like this</span>
        <span class="cite-code" data-id="{$id}">
          <xsl:attribute name="data-xpath">
            <xsl:value-of select="diggs:occurrences/diggs:Occurrence[1]/diggs:sourceElementXpath"/>
          </xsl:attribute>
        </span>
        <button class="copy-btn" onclick="copyCitation(this)">Copy</button>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
