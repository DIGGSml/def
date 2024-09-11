function myFunction() {
    // Declare variables
    var input, filter, table, tr, td, i, txtValue, cnt, rec;
    input = document.getElementById("myInput");
    filter = input.value.toUpperCase();
    table = document.getElementById("myTable");
    tr = table.getElementsByTagName("tr");
    rec = 0;
    // Loop through all table rows and cells, and hide those who don't match the search query
    for (i = 0; i < tr.length; i++) {
        var len = table.rows[i].cells.length;
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
    document.getElementById("counter").innerHTML = "Showing "+ (rec-1) +" of "+ (tr.length-1) + " records";
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
            var identifier = rowSelected.cells[0].innerHTML;
            var element = document.getElementById("gmlid").innerHTML;
            var url = document.getElementById("url").innerHTML.split('#')[0]+"&quot;&gt;";
            var txt = 'Example instance:<p style="color: red;">&lt;';
            txt += url;
           // txt += "#" + id +"&quot;&gt;";
            txt += id + "&lt;/" + element + '&gt;</p>';
            
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