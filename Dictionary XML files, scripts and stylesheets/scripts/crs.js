function myFunction() {
    // Declare variables
    var input, filter, table, tr, td, i, txtValue, cnt, rec;
    input = document.getElementById("myInput");
    filter = input.value.toUpperCase();
    table = document.getElementById("myTable");
    tr = table.getElementsByTagName("tr");
    
    // Loop through all table rows, looking at the first two cells, and hide those who don't match the search query
    rec = 0;
    for (i = 0; i < tr.length; i++) {
        var len = 2 // Search the first two columns only
        cnt = 0;
        for (j = 0; j < len; j++) {
            td = tr[i].getElementsByTagName("td")[j];
            if (! td) break;
            txtValue = td.textContent || td.innerText;
            if (txtValue.toUpperCase().indexOf(filter) < 0) {
                cnt++
            }
        }
        if (cnt == len) {
            tr[i].style.display = "none";
        } else {
            tr[i].style.display = "";
            rec++
        }
    }
    document.getElementById("counter").innerHTML = "Showing " + (rec -1) + " of " + (tr.length -1) + " records";
}

function highlight_row() {
    var table = document.getElementById('myTable');
    var cells = table.getElementsByTagName('td');
    for (var i = 0; i < cells.length; i++) {
        // Take each cell
        var cell = cells[i];
        // do something on onclick event for cell
        cell.onclick = function () {
            // Get the row id where the cell exists
            var rowId = this.parentNode.rowIndex;
            
            var rowsNotSelected = table.getElementsByTagName('tr');
            for (var row = 0; row < rowsNotSelected.length; row++) {
                rowsNotSelected[row].style.backgroundColor = "";
                rowsNotSelected[row].classList.remove('selected');
            }
            var rowSelected = table.getElementsByTagName('tr')[rowId];
            rowSelected.style.backgroundColor = "gray";
            rowSelected.className += "selected";
            
            // Now get cell info to show instance example
            
            var id = rowSelected.cells[1].innerHTML;
            var identifier = rowSelected.cells[2].innerHTML;
            var element = "srsName";
            var url = 'http://diggsml.org/def/crs/DIGGS/0.1/'+ document.getElementById("gmlid").innerHTML+'.xml';
            var txt = 'Example instances:<p style="color: red;">' + element + '="';
            txt += url;
            txt += "#" + id + '"</p>';
            txt += "<p>or can simply reference the identifier with the numbers following the last colon being the EPSG codes for horizontal and vertical CRS's repectively:</p>";;
            txt += '<p style="color: red;">' + element + '="' + identifier + '"</p>';;
            txt += '<p>The above can be used to reference a compound CRS not otherwise maintained in this dictionary.</p>';
             
            //Send to page
            document.getElementById("instance").innerHTML = txt;
            
        }
    }
}

function loadScripts() {
    highlight_row();
    myFunction();
}

window.onload = loadScripts;