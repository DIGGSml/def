/*
 * Behaviour for DIGGS Specification Registry pages rendered by
 * https://diggsml.org/def/stylesheets/registry.xsl
 *
 * Three jobs:
 *   1. Search - filter the entry cards on any visible text (name, id, title,
 *      accrediting body, ...), so a provider can confirm a standard is
 *      registered before citing it.
 *   2. Domain filter (R15) - a single registry now spans every domain of
 *      practice, so the "All domains" dropdown narrows the card list to one
 *      domain first; the search box then searches WITHIN that narrowed list -
 *      a card must pass both to show. The dropdown's own options are built at
 *      load time from whatever domains the document actually declares, never
 *      hand-maintained here.
 *   3. Citation - build a ready-to-paste xlink:href for EVERY property the
 *      entry may be cited from, each independently copyable. A standard
 *      registered for both governingStandard and testProcedureMethod gets one
 *      snippet per use, because a provider populating a test procedure needs
 *      that element name, not the first one that happened to be declared.
 *
 * Deliberately not shared with scripts.js: that file filters TABLE ROWS of a
 * columnar code list, and a registry renders one card per entry instead.
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
 * Reads each card's data-domains attribute (space-separated ids) rather than the badges
 * themselves, so a domain still gets an option even if a future layout stops rendering badges.
 */
function populateDomainFilter() {
    var select = document.getElementById("domainFilter");
    if (!select) return;
    var cards = document.getElementsByClassName("card");
    var seen = {};
    var ids = [];

    for (var i = 0; i < cards.length; i++) {
        var raw = cards[i].getAttribute("data-domains") || "";
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
 * Search + domain filter (combined - a card must satisfy both)
 * ------------------------------------------------------------------ */

function filterRegistry() {
    var input = document.getElementById("myInput");
    var filter = input.value.toUpperCase().trim();
    var domainSelect = document.getElementById("domainFilter");
    var domain = domainSelect ? domainSelect.value : "";
    var cards = document.getElementsByClassName("card");
    var shown = 0;

    for (var i = 0; i < cards.length; i++) {
        var text = (cards[i].textContent || cards[i].innerText).toUpperCase();
        var textMatch = filter === "" || text.indexOf(filter) > -1;

        var domainMatch = true;
        if (domain !== "") {
            var cardDomains = (cards[i].getAttribute("data-domains") || "").split(/\s+/);
            domainMatch = cardDomains.indexOf(domain) > -1;
        }

        var match = textMatch && domainMatch;
        cards[i].style.display = match ? "" : "none";
        if (match) shown++;
    }

    var counter = document.getElementById("counter");
    if (counter) {
        counter.innerHTML = "Showing " + shown + " of " + cards.length + " registered standards";
    }

    var none = document.getElementById("noresults");
    if (none) none.style.display = (shown === 0 && cards.length > 0) ? "block" : "none";
}

/* ------------------------------------------------------------------ *
 * Deep links
 * ------------------------------------------------------------------ */

/*
 * A registry href carries the Specification's gml:id as its fragment, so
 * following one from an instance document lands here. The id sits on the
 * Specification, which the XSLT does not emit as an element - so scroll to the
 * card whose citation blocks carry that id and flag it. Scrolling happens
 * inside the .cards pane, which is the scroll container.
 */
function focusFragment() {
    var frag = window.location.hash.replace(/^#/, "");
    if (!frag) return;
    var blocks = document.getElementsByClassName("cite-code");
    for (var i = 0; i < blocks.length; i++) {
        if (blocks[i].getAttribute("data-id") === frag) {
            var card = blocks[i].closest ? blocks[i].closest(".card") : null;
            if (card) {
                card.scrollIntoView({ block: "center" });
                card.style.outline = "3px solid #b06a00";
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
