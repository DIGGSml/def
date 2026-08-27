/*
 * Behaviour for DIGGS Specification Registry pages rendered by
 * https://diggsml.org/def/stylesheets/registry.xsl
 *
 * Two jobs:
 *   1. Search - filter the entry cards on any visible text (name, id, title,
 *      accrediting body, ...), so a provider can confirm a standard is
 *      registered before citing it.
 *   2. Citation - build a ready-to-paste xlink:href for EVERY property the
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
 * Search
 * ------------------------------------------------------------------ */

function filterRegistry() {
    var input = document.getElementById("myInput");
    var filter = input.value.toUpperCase().trim();
    var cards = document.getElementsByClassName("card");
    var shown = 0;

    for (var i = 0; i < cards.length; i++) {
        var text = (cards[i].textContent || cards[i].innerText).toUpperCase();
        var match = filter === "" || text.indexOf(filter) > -1;
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
    filterRegistry();
    focusFragment();
}

window.onload = loadRegistry;
