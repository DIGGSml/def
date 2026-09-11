/*
 * Behaviour for DIGGS Specification Registry pages rendered by
 * https://diggsml.org/def/stylesheets/registry.xsl
 *
 * Each entry is a pair of adjacent table rows: a summary row (.entry-row,
 * showing only Code and Title) immediately followed by its detail row
 * (.detail-row, the full record, display:none until expanded). Four jobs:
 *   1. Search - filter on any text in EITHER row of the pair (name, id,
 *      title, accrediting body, ...), so a provider can confirm a standard is
 *      registered before citing it, whether or not its panel happens to be
 *      open. The detail row's markup stays in the DOM at all times so its
 *      text is always there for textContent to see, even while display:none.
 *   2. Domain filter (R15) - a single registry now spans every domain of
 *      practice, so the "All domains" dropdown narrows the row list to one
 *      domain first; the search box then searches WITHIN that narrowed list -
 *      a row pair must pass both to show. The dropdown's own options are
 *      built at load time from whatever domains the document actually
 *      declares, never hand-maintained here.
 *   3. Accordion - clicking a summary row toggles its detail row open/closed;
 *      opening one closes whichever other row was open, so at most one entry
 *      is expanded at a time.
 *   4. Citation - build a ready-to-paste xlink:href for EVERY property the
 *      entry may be cited from, each independently copyable. A standard
 *      registered for both governingStandard and testProcedureMethod gets one
 *      snippet per use, because a provider populating a test procedure needs
 *      that element name, not the first one that happened to be declared.
 *
 * Deliberately not shared with scripts.js: that file filters plain table rows
 * of a columnar code list with no notion of a summary/detail pair or an
 * accordion, even though both pages render as tables now.
 */

/* ------------------------------------------------------------------ *
 * Citation snippets
 * ------------------------------------------------------------------ */

/* Fallback when an entry declares no occurrences and so has no XPath to
 * derive an element name from. governingStandard is by far the most common
 * property holding a Specification in a registry-citing document. */
var DEFAULT_CITING_ELEMENT = "diggs:governingStandard";

/*
 * Derive the citing element's QName from an Occurrence sourceElementXpath.
 * "//diggs:RIProgramBasis/diggs:governingStandard" -> "diggs:governingStandard"
 * "//diggs:testProcedureMethod"                    -> "diggs:testProcedureMethod"
 */
function citingElementFromXPath(xpath) {
    if (!xpath) return DEFAULT_CITING_ELEMENT;
    var steps = xpath.split("/").filter(function (s) { return s.length > 0; });
    if (!steps.length) return DEFAULT_CITING_ELEMENT;
    // Drop any predicate, e.g. foo[@bar='x'] -> foo
    var last = steps[steps.length - 1].replace(/\[.*$/, "").trim();
    return last.length ? last : DEFAULT_CITING_ELEMENT;
}

/*
 * Fill in every citation block on the page. Runs once at load: the registry
 * URL and each entry's id are already in the DOM, courtesy of the XSLT.
 */
function buildCitations() {
    var urlNode = document.getElementById("registryUrl");
    var registryUrl = urlNode ? urlNode.textContent.trim() : "";
    var blocks = document.getElementsByClassName("cite-code");

    for (var i = 0; i < blocks.length; i++) {
        var block = blocks[i];
        var id = block.getAttribute("data-id") || "";
        var element = citingElementFromXPath(block.getAttribute("data-xpath"));

        block.textContent =
            "<" + element + "\n    xlink:href=\"" + registryUrl + "#" + id + "\"/>";

        // Label the snippet with the element it populates, so a card offering
        // several uses is readable without showing raw XPaths.
        var item = block.parentNode;
        var use = item ? item.querySelector(".cite-use") : null;
        if (use) use.textContent = element;
    }
}

/*
 * Copy one snippet. The button and its snippet share a .cite-item parent, so
 * scope the lookup to that - NOT to the enclosing .cite block, which holds
 * every snippet on the card and would always return the first.
 */
function copyCitation(button) {
    var item = button.closest ? button.closest(".cite-item") : null;
    if (!item) {
        // closest() unavailable: walk up manually.
        item = button.parentNode;
        while (item && item.className.indexOf("cite-item") === -1) item = item.parentNode;
    }
    if (!item) return;

    var block = item.querySelector(".cite-code");
    if (!block) return;
    var text = block.textContent;

    var done = function () {
        var original = button.textContent;
        button.textContent = "Copied";
        button.className = "copy-btn copied";
        setTimeout(function () {
            button.textContent = original;
            button.className = "copy-btn";
        }, 1400);
    };

    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, function () { legacyCopy(text, done); });
    } else {
        legacyCopy(text, done);
    }
}

/* Clipboard API needs a secure context; a registry opened as file:// has none. */
function legacyCopy(text, done) {
    var ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand("copy"); done(); } catch (e) { /* clipboard unavailable */ }
    document.body.removeChild(ta);
}

/* ------------------------------------------------------------------ *
 * Domain filter
 * ------------------------------------------------------------------ */

/*
 * "rigid_inclusions" -> "Rigid Inclusions". Domain codes are lower_snake_case ids (the
 * dictionary-wide convention - see specificationDomain.xml); text content on diggs:domain is not
 * guaranteed to be a display label, so every domain badge and dropdown option is labelled purely
 * from the id, never from whatever text an instance happened to carry.
 */
function formatDomainLabel(id) {
    if (!id) return "";
    var words = id.split("_");
    for (var i = 0; i < words.length; i++) {
        if (words[i].length) words[i] = words[i].charAt(0).toUpperCase() + words[i].slice(1);
    }
    return words.join(" ");
}

/* Replace every domain badge's text with its formatted label, derived from data-domain-id. */
function prettifyDomainBadges() {
    var badges = document.getElementsByClassName("domain-badge");
    for (var i = 0; i < badges.length; i++) {
        badges[i].textContent = formatDomainLabel(badges[i].getAttribute("data-domain-id"));
    }
}

/*
 * Build the "All domains" dropdown from whatever domains actually appear on the page - never
 * hand-maintained, so a new domain added to the registry shows up here with no stylesheet change.
 * Reads each summary row's data-domains attribute (space-separated ids) rather than the badges
 * themselves, so a domain still gets an option even though the badges only render inside the
 * (possibly collapsed) detail row.
 */
function populateDomainFilter() {
    var select = document.getElementById("domainFilter");
    if (!select) return;
    var rows = document.getElementsByClassName("entry-row");
    var seen = {};
    var ids = [];

    for (var i = 0; i < rows.length; i++) {
        var raw = rows[i].getAttribute("data-domains") || "";
        var tokens = raw.split(/\s+/).filter(function (s) { return s.length > 0; });
        for (var j = 0; j < tokens.length; j++) {
            if (!seen[tokens[j]]) { seen[tokens[j]] = true; ids.push(tokens[j]); }
        }
    }

    ids.sort(function (a, b) {
        return formatDomainLabel(a).localeCompare(formatDomainLabel(b));
    });

    for (var k = 0; k < ids.length; k++) {
        var opt = document.createElement("option");
        opt.value = ids[k];
        opt.textContent = formatDomainLabel(ids[k]);
        select.appendChild(opt);
    }
}

/* ------------------------------------------------------------------ *
 * Accordion - at most one entry's detail row expanded at a time
 * ------------------------------------------------------------------ */

/*
 * summaryRow is the .entry-row that was clicked; its .detail-row is always
 * the very next sibling, emitted immediately after it by the XSLT. Toggles
 * that pair open/closed, and force-closes every other pair first, so opening
 * one entry always closes whichever other one was open - including the
 * degenerate case of re-clicking the already-open row, which this closes
 * without opening anything new.
 */
function toggleRow(summaryRow) {
    var detailRow = summaryRow.nextElementSibling;
    if (!detailRow) return;
    var wasExpanded = summaryRow.classList.contains("expanded");

    var rows = document.getElementsByClassName("entry-row");
    for (var i = 0; i < rows.length; i++) {
        if (rows[i] !== summaryRow && rows[i].classList.contains("expanded")) {
            rows[i].classList.remove("expanded");
            var otherDetail = rows[i].nextElementSibling;
            if (otherDetail) otherDetail.style.display = "none";
        }
    }

    if (wasExpanded) {
        summaryRow.classList.remove("expanded");
        detailRow.style.display = "none";
    } else {
        summaryRow.classList.add("expanded");
        detailRow.style.display = "table-row";
    }
}

/* ------------------------------------------------------------------ *
 * Search + domain filter (combined - a row pair must satisfy both)
 * ------------------------------------------------------------------ */

function filterRegistry() {
    var input = document.getElementById("myInput");
    var filter = input.value.toUpperCase().trim();
    var domainSelect = document.getElementById("domainFilter");
    var domain = domainSelect ? domainSelect.value : "";
    var rows = document.getElementsByClassName("entry-row");
    var shown = 0;

    for (var i = 0; i < rows.length; i++) {
        var summaryRow = rows[i];
        var detailRow = summaryRow.nextElementSibling;

        // Match against BOTH rows' text, so a search term that only appears in the
        // (possibly collapsed) detail panel - a description, an accrediting body -
        // still finds the entry, exactly as it did when everything was always visible.
        var text = (summaryRow.textContent || summaryRow.innerText || "") + " " +
            (detailRow ? (detailRow.textContent || detailRow.innerText || "") : "");
        var textMatch = filter === "" || text.toUpperCase().indexOf(filter) > -1;

        var domainMatch = true;
        if (domain !== "") {
            var rowDomains = (summaryRow.getAttribute("data-domains") || "").split(/\s+/);
            domainMatch = rowDomains.indexOf(domain) > -1;
        }

        var match = textMatch && domainMatch;
        summaryRow.style.display = match ? "" : "none";

        if (detailRow) {
            if (!match) {
                // A row filtered out of view shouldn't stay "open" underneath.
                detailRow.style.display = "none";
                summaryRow.classList.remove("expanded");
            } else {
                detailRow.style.display = summaryRow.classList.contains("expanded") ? "table-row" : "none";
            }
        }

        if (match) shown++;
    }

    var counter = document.getElementById("counter");
    if (counter) {
        counter.innerHTML = "Showing " + shown + " of " + rows.length + " registered standards";
    }

    var none = document.getElementById("noresults");
    if (none) none.style.display = (shown === 0 && rows.length > 0) ? "block" : "none";
}

/* ------------------------------------------------------------------ *
 * Deep links
 * ------------------------------------------------------------------ */

/*
 * A registry href carries the Specification's gml:id as its fragment, so
 * following one from an instance document lands here. The id sits on the
 * Specification, which the XSLT does not emit as an element - so find the
 * detail row whose citation blocks carry that id, expand its entry (deep
 * links should reveal the record, not just scroll near it), and flag the
 * summary row. Scrolling happens inside the .cards pane, which is the
 * scroll container.
 */
function focusFragment() {
    var frag = window.location.hash.replace(/^#/, "");
    if (!frag) return;
    var blocks = document.getElementsByClassName("cite-code");
    for (var i = 0; i < blocks.length; i++) {
        if (blocks[i].getAttribute("data-id") === frag) {
            var detailRow = blocks[i].closest ? blocks[i].closest(".detail-row") : null;
            var summaryRow = detailRow ? detailRow.previousElementSibling : null;
            if (summaryRow) {
                toggleRow(summaryRow);
                summaryRow.scrollIntoView({ block: "center" });
                summaryRow.style.outline = "3px solid #b06a00";
            }
            return;
        }
    }
}

function loadRegistry() {
    buildCitations();
    prettifyDomainBadges();
    populateDomainFilter();
    filterRegistry();
    focusFragment();
}

window.onload = loadRegistry;
