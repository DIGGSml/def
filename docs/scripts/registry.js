/*
 * Behaviour for DIGGS Specification Registry pages rendered by
 * https://diggsml.org/def/stylesheets/registry.xsl
 *
 * Two jobs:
 *   1. Search - filter the entry cards on any visible text (name, id, title,
 *      accrediting body, XPath, ...), so a provider can confirm a standard is
 *      registered before citing it.
 *   2. Citation - build and copy the exact xlink:href a provider must paste
 *      into an instance document.
 *
 * Deliberately not shared with scripts.js: that file filters TABLE ROWS of a
 * columnar code list, and a registry renders one card per entry instead.
 */

/* ------------------------------------------------------------------ *
 * Citation snippets
 * ------------------------------------------------------------------ */

/*
 * Derive the citing element's QName from an Occurrence sourceElementXpath.
 * "//diggs:RIProgramBasis/diggs:governingStandard" -> "diggs:governingStandard"
 * Falls back to diggs:governingStandard, the overwhelmingly common case, when
 * an entry declares no occurrences.
 */
function citingElementFromXPath(xpath) {
    if (!xpath) return "diggs:governingStandard";
    var steps = xpath.split("/").filter(function (s) { return s.length > 0; });
    if (!steps.length) return "diggs:governingStandard";
    // Drop any predicate, e.g. foo[@bar='x'] -> foo
    return steps[steps.length - 1].replace(/\[.*$/, "");
}

/*
 * Fill in every citation block. Runs once at load: the registry URL and each
 * entry's id are already in the DOM, courtesy of the XSLT.
 */
function buildCitations() {
    var urlNode = document.getElementById("registryUrl");
    var registryUrl = urlNode ? urlNode.textContent.trim() : "";
    var blocks = document.getElementsByClassName("cite-code");

    for (var i = 0; i < blocks.length; i++) {
        var block = blocks[i];
        var id = block.getAttribute("data-id") || "";
        var element = citingElementFromXPath(block.getAttribute("data-xpath"));
        block.textContent = "<" + element + "\n    xlink:href=\"" + registryUrl + "#" + id + "\"/>";
    }
}

function copyCitation(button) {
    var block = button.parentNode.querySelector(".cite-code");
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
 * card whose citation block carries that id and flag it.
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
