<?xml version="1.0" encoding="UTF-8"?>

<!--
  Renders a DIGGS Specification Registry as a browsable, searchable page.

  Companion to codelists.xsl / propertylists.xsl, but deliberately NOT columnar: a registry entry
  carries a bibliographic record with many optional fields, most of them long, so one row per entry
  would be mostly empty cells and unreadable titles. Each entry is rendered as a card holding a
  key/value table instead, and only the fields actually present are shown.

  The page has one job beyond lookup: telling a data provider how to CITE what they found. Each
  entry therefore ends with ONE ready-to-paste snippet PER declared occurrence, each with its own
  copy button - a standard citable from both governingStandard and testProcedureMethod shows both
  forms. The raw sourceElementXpath values are deliberately NOT displayed: they are validator
  configuration, and a data provider needs the element to write, not the XPath that governs it.

  ONE UNIFIED REGISTRY, FILTERED BY DOMAIN (R15). A single registry document now spans every
  domain of practice rather than being split one file per domain - see SpecificationRegistry.xsd's
  own SCOPE note for why. Each card is tagged with its declared diggs:domain code(s) as a
  data-domains attribute plus visible badges; the "All domains" dropdown next to the search box
  filters the card list to one domain, and the search box then searches WITHIN whatever the
  dropdown has already narrowed to - both conditions must pass. registry.js builds the dropdown's
  options at load time from whatever domains actually appear in the document, so a domain never
  needs to be hand-maintained here.

  Layout is a flex column - header fixed, cards pane scrolling - so the search box and registry
  title stay visible while browsing. Sized in viewport units rather than the fixed max-height
  codelists.xsl uses, so it adapts to laptop and large-monitor heights alike.

  NOTE THE NAMESPACE. Registries are authored against http://diggsml.org/schemas/3. The published
  code list dictionaries still declare http://diggsml.org/schemas/2.6, which is why codelists.xsl
  binds that instead - do not copy the prefix binding from that file. (Tracked for correction as
  task X11, after which this note can go.)

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
          html, body { height: 100%; }

          body {
            font-family: Arial, Helvetica, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #FFEFD5; /* Light amber background, matching the code list pages */
            color: #1a1a1a;
            display: flex;
            flex-direction: column;
          }

          /* ---- fixed header ---- */
          .page-header {
            flex: 0 0 auto;
            position: relative;
            background-color: #FFEFD5;
            box-shadow: 0 3px 10px rgba(0,0,0,.30);
            z-index: 5;
            padding: 14px 16px 10px 16px;
            text-align: center;
          }

          .logo { position: absolute; top: 10px; left: 12px; }

          h1 { margin: 0 0 10px 0; font-size: 26px; }

          .description {
            border: 2px solid black;
            padding: 8px 12px;
            text-align: left;
            display: inline-block;
            max-width: 1000px;
            max-height: 20vh;
            overflow-y: auto;
            line-height: 1.45;
            font-size: 14px;
          }

          .controls {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin: 10px 0 4px 0;
          }

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
            margin: 0;
          }

          #domainFilter {
            font-size: 15px;
            padding: 11px 14px;
            border: 1px solid #bbb;
            background: #fff;
            margin: 0;
          }

          #counter { font-size: 14px; display: block; }

          .hint { font-size: 13px; color: #555; margin-top: 3px; }

          /* ---- scrolling cards pane ---- */
          .cards {
            flex: 1 1 auto;
            overflow-y: auto;
            padding: 18px 16px 40px 16px;
          }

          .cards-inner { max-width: 1100px; margin: 0 auto; }

          .card {
            background-color: #f7f7f7;
            border: 1px solid #999;
            box-shadow: 0 1px 5px rgba(0,0,0,.28);
            margin-bottom: 18px;
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

          .domain-badge {
            font-size: 12px;
            padding: 2px 8px;
            border-radius: 10px;
            font-weight: bold;
            background: #10457f;
            color: #fff;
          }

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

          .mono { font-family: Consolas, "Courier New", monospace; font-size: 14px; }

          /* ---- citations ---- */
          .cite {
            border-top: 2px solid #000;
            background: #fffdf5;
            padding: 10px 14px 12px 14px;
          }

          .cite-label {
            font-size: 13px;
            font-weight: bold;
            display: block;
            margin-bottom: 8px;
          }

          .cite-note { font-size: 13px; color: #555; margin-bottom: 8px; }

          .cite-item { margin-bottom: 12px; }
          .cite-item:last-child { margin-bottom: 0; }

          .cite-item-head {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 4px;
          }

          .cite-use {
            font-family: Consolas, "Courier New", monospace;
            font-size: 14px;
            font-weight: bold;
            color: #10457f;
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

          .cite-cond { font-size: 12.5px; color: #8a5a00; margin-top: 4px; }

          .copy-btn {
            font-size: 12.5px;
            padding: 4px 12px;
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
        <div class="page-header">
          <div class="logo">
            <img src="https://diggsml.org/def/img/diggs-logo.png" style="width:130px" alt="DIGGS"/>
          </div>

          <h1><xsl:value-of select="/diggs:SpecificationRegistry/gml:name"/></h1>

          <div>
            <span class="description">
              <xsl:value-of select="/diggs:SpecificationRegistry/gml:description"/>
            </span>
          </div>

          <div class="controls">
            <input type="text" id="myInput" onkeyup="filterRegistry()"
              placeholder="Search standards, identifiers, titles..."/>
            <select id="domainFilter" onchange="filterRegistry()">
              <option value="">All domains</option>
            </select>
          </div>
          <span id="counter"></span>
          <div class="hint">
            Find the standard you need, then copy the citation for the property you are populating.
          </div>

          <!-- The registry's own URL, read by registry.js to build citation snippets. -->
          <span id="registryUrl" style="display:none"><xsl:value-of select="$registryUrl"/></span>
        </div>

        <div class="cards" id="cards">
          <div class="cards-inner">
            <xsl:for-each select="/diggs:SpecificationRegistry/diggs:registryEntry/diggs:SpecificationRegistryEntry">
              <xsl:sort select="diggs:specification/diggs:Specification/gml:name"/>
              <xsl:apply-templates select="."/>
            </xsl:for-each>
            <div class="noresults" id="noresults">No standard matches that search.</div>
          </div>
        </div>
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

    <xsl:variable name="domainIds">
      <xsl:for-each select="diggs:domain">
        <xsl:value-of select="substring-after(@codeSpace, '#')"/>
        <xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <div class="card" data-domains="{$domainIds}">
      <div class="card-head">
        <span class="nm"><xsl:value-of select="$spec/gml:name"/></span>
        <span class="id"><xsl:value-of select="$id"/></span>
        <span class="badge {$status}"><xsl:value-of select="$status"/></span>
        <xsl:for-each select="diggs:domain">
          <span class="domain-badge" data-domain-id="{substring-after(@codeSpace, '#')}">
            <xsl:value-of select="."/>
          </span>
        </xsl:for-each>
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
      </table>

      <!-- One citation per declared occurrence, each independently copyable. registry.js fills in
           the element name and the snippet text from data-xpath / data-id. -->
      <div class="cite">
        <span class="cite-label">Cite it like this</span>
        <xsl:choose>
          <xsl:when test="diggs:occurrences/diggs:Occurrence">
            <xsl:for-each select="diggs:occurrences/diggs:Occurrence">
              <div class="cite-item">
                <div class="cite-item-head">
                  <span class="cite-use"></span>
                  <button class="copy-btn" onclick="copyCitation(this)">Copy</button>
                </div>
                <span class="cite-code" data-id="{$id}" data-xpath="{diggs:sourceElementXpath}"></span>
                <xsl:if test="diggs:conditionalElementXpath">
                  <div class="cite-cond">
                    <xsl:text>Only valid when this is also present: </xsl:text>
                    <xsl:value-of select="diggs:conditionalElementXpath"/>
                  </div>
                </xsl:if>
              </div>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <div class="cite-note">
              This entry declares no restriction, so it may be cited from any property that holds a
              <span class="mono">diggs:Specification</span>. A common one is shown.
            </div>
            <div class="cite-item">
              <div class="cite-item-head">
                <span class="cite-use"></span>
                <button class="copy-btn" onclick="copyCitation(this)">Copy</button>
              </div>
              <span class="cite-code" data-id="{$id}" data-xpath=""></span>
            </div>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
