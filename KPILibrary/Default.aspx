<%@ Page Title="KPI Management" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Default.aspx.vb" Inherits="KPILibrary._Default" %>

<%@ Import Namespace="System.Web.Services" %>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .modal {
            display: none;
            position: fixed;
            top: 50%;
            left: 50%;
            width: 800px;
            height: 500px;
            overflow-y: auto;
            background-color: #fff;
            transform: translate(-50%, -50%);
            border-radius: 12px;
            padding: 20px; 
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
            z-index: 1000;
        }
        .close-btn { float: right; font-size: 20px; font-weight: bold; cursor: pointer; }
        .error-span { 
            color: red; 
            font-size: 12px; 
           
            display:none;
            visibility:hidden;
          
        }
        .error-span.show {
            display: block;
			 margin-left: 10px; 
            visibility: visible;
        }
        .toggle-switch { position: relative; display: inline-block; width: 40px; height: 20px; }
        .toggle-switch input { opacity: 0; width: 0; height: 0; }
        .slider {
            position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0;
            background-color: #ccc; transition: .4s; border-radius: 20px;
        }
        .toggle-switch input:checked + .slider { background-color: #2196F3; }
        .slider:before {
            position: absolute; content: ""; height: 16px; width: 16px; left: 2px; bottom: 2px;
            background-color: white; transition: .4s; border-radius: 50%;
        }
        .toggle-switch input:checked + .slider:before { transform: translateX(20px); }
        .btn-add, .btn-edit { padding: 6px 12px; border: none; border-radius: 4px; color: white; cursor: pointer; }
        .btn-add { background-color: #4CAF50; }
        .btn-edit { background-color: #2196F3; }
		.btn-save{background-color:#0f439d;align-self:flex-end;color:#fff;margin-right:90px;}
		.modal table td,.modal table th { border:1px solid #c1d7f8; padding:4px; font-size:14px;}
        table { width: 100%; border-collapse: collapse; }
        table td, table th { padding: 8px; border: 1px solid #ccc; }
         .kpi-table-scroll{
            max-height:400px;
            overflow-y:auto;
            border:1px solid #ccc;
        }
         .grid-style { border-collapse: collapse; width: 100%; table-layout:auto; }
       
        .grid-style td, .grid-style th { border: 1px solid #ddd; padding: 8px; font-size:14px; text-align:left; white-space:nowrap;}
        .grid-style th { cursor :pointer;
							white-space :nowrap;
							border:solid 1px #4f93e3;
							padding :4px 6px 5px 6px ;
							background  : url('gvGradient.gif') repeat-x center top #94b6e8;	
							overflow : hidden ;
							font-weight:normal;
							text-align: left;	background-color: #f2f2f2; }
        .modal input[type="text"], .modal textarea {
            width: 520px; max-width: none !important; box-sizing: border-box; font-family: Arial,Helvetica, sans-serif; font-size:14px
        } 
        /* --- True Toggle Switch Styles --- */
/* --- True Toggle Switch Styles (Keep or remove .toggle-state-all styles) --- */
.toggle-switch-ui {
    cursor: pointer;
    user-select: none; 
}

.toggle-switch-container {
    position: relative;
    display: inline-block;
    width: 60px;
    height: 34px;
}

.toggle-switch-container input {
    opacity: 0;
    width: 0;
    height: 0;
}

.toggle-switch-slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: #ccc; /* Default/Inactive Gray----- */
    transition: .4s;
    border-radius: 34px;
}

.toggle-switch-slider:before {
    position: absolute;
    content: "";
    height: 26px;
    width: 26px;
    left: 4px;
    bottom: 4px;
    background-color: white;
    transition: .4s;
    border-radius: 50%;
}

/* Styles for Active state (Green) */
.toggle-state-active .toggle-switch-slider {
    background-color: #4CAF50; /* Green */
}
.toggle-state-active .toggle-switch-slider:before {
    transform: translateX(26px);
}

/* --- End of True Toggle Switch Styles --- */

 /* Style for client-side validation error labels */
        .client-error-label {
            color: red;
            font-size: 12px;
            margin-top: 5px;
            display: none; /* Hidden by default */
        }
        .client-error-label.show {
            display: block;
        }

        .btn-delete {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            color: white;
            cursor: pointer;
            /* Example: Red color for delete */
            background-color: red;
        }

           .select {
      font-size: 16px;
      padding: 12px;
      width: 80%;
      max-width: 500px;
      margin: 20px 0;
      border: 1px solid #ccc;
      border-radius: 8px;
      /*box-shadow: 0 2px 6px rgba(0,0,0,0.1);*/
    }
    .time {
      font-size: 18px;
      margin-top: 20px;
      color: #27ae60;
      line-height: 1.5;
      min-height: 50px;
    }
    .placeholder {
      color: #7f8c8d;
      font-style: italic;
    }
     .hidden {
      display: none;
    }

    </style>

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
        
      <h2>🌎 Select a Time Zone</h2>
  <select id="tzSelect">
    <option value="">Loading time zones...</option>
  </select>
  <div id="time" class="placeholder">Select a time zone to see live time.</div>

    <script> 

        const timeZones = Intl.supportedValuesOf('timeZone');

        const select = document.getElementById('tzSelect');
        const timeDiv = document.getElementById('time');

        // Step 2: Format each time zone as "City (Region)" for readability
        const formattedZones = timeZones.map(tz => {
            const parts = tz.split('/');
            const region = parts[0];
            const city = parts.slice(1).join(' ').replace(/_/g, ' ');
            return {
                tz,
                label: city ? `${city} (${region})` : region
            };
        });

        // Sort alphabetically by display name
        formattedZones.sort((a, b) => a.label.localeCompare(b.label));

        // Step 3: Populate dropdown
        select.innerHTML = ''; // Clear loading message
        const defaultOption = document.createElement('option');
        defaultOption.value = '';
        defaultOption.textContent = '-- Select Time Zone --';
        select.appendChild(defaultOption);

        formattedZones.forEach(({ label, tz }) => {
            const option = new Option(label, tz);
            select.appendChild(option);
        });

        // Step 4: Function to update time based on selected time zone
        function updateTime() {
            const tz = select.value;

            if (!tz) {
                timeDiv.textContent = 'Please select a time zone.';
                timeDiv.className = 'placeholder';
                return;
            }

            try {
                const now = new Date();
                const options = {
                    timeZone: tz,
                    timeStyle: 'long',
                    dateStyle: 'full',
                    hour12: true
                };

                const timeString = new Intl.DateTimeFormat(navigator.language || 'en-US', options)
                    .format(now);

                timeDiv.textContent = timeString;
                timeDiv.className = ''; // Remove placeholder style
            } catch (e) {
                timeDiv.textContent = 'Could not display time for this zone.';
                timeDiv.className = 'placeholder';
            }
        }

        // Step 5: Initial update
        updateTime();

        // Step 6: Update every second for live clock
        setInterval(updateTime, 1000);

        // Step 7: Also update when user changes selection
        select.addEventListener('change', updateTime);









        // >>>>>>>>>> UPDATED SEARCH FUNCTION <<<<<<<<<<
        function filterTable() {
            var input = document.getElementById("searchBox");
            var filter = input.value.toUpperCase();
            var table = document.getElementById("<%= GridView1.ClientID %>");
            if (!table) {
                console.error("GridView table element not found for client-side search!");
                return;
            }
            var trs = table.getElementsByTagName("tr");
            for (var i = 1; i < trs.length; i++) { // Start from 1 to skip header
                var tds = trs[i].getElementsByTagName("td");
                var showRow = false;

                // --- UPDATED SEARCH LOGIC ---
                // Check specific columns: KPI ID (index 3) and Order (index 10)
                // IMPORTANT: Adjust these indices if your column order in the GridView changes!
                // Based on your ASPX structure:
                // Columns: Actions(0), Metric(1), KPI Name(2), KPI ID(3), Short Desc(4), ... , Order(10), ...
                var kpiIdCell = tds[3]; // KPI ID is in the 4th column (index 3)
                var orderCell = tds[10]; // OrderWithinSecton is in the 11th column (index 10)

                // Check if KPI ID cell matches
                if (kpiIdCell) {
                    var kpiIdTxt = kpiIdCell.textContent || kpiIdCell.innerText;
                    if (kpiIdTxt.toUpperCase().indexOf(filter) > -1) {
                        showRow = true;
                    }
                }

                // If KPI ID didn't match, check Order cell
                if (!showRow && orderCell) {
                    var orderTxt = orderCell.textContent || orderCell.innerText;
                    // Simple text match on the cell content (e.g., "123")
                    if (orderTxt.toUpperCase().indexOf(filter) > -1) {
                        showRow = true;
                    }
                }
                // --- END UPDATED SEARCH LOGIC ---

                trs[i].style.display = showRow ? "" : "none";
            }
        }

        // >>>>>>>>>> END OF UPDATED SEARCH FUNCTION <<<<<<<<<
        let lblKPIError = null;
        let inputField = null;
        let isCheckingKPI = false;

        function showPopup() {
            document.getElementById('kpiModal').style.display = 'block';

        }

        function hidePopup() {
            document.getElementById('kpiModal').style.display = 'none';


            document.getElementById("<%= lblOrderError.ClientID %>").style.display = "none";
            document.getElementById("<%= lblDuplicateMetricKPIError.ClientID %>").style.display = "none";
            document.getElementById("<%= lblKPIError.ClientID %>").style.display = "none";
        }

        function showElement(element) {
            if (element) {
                element.classList.add('show');
            }
        }

        function hideElement(element) {
            if (element) {
                element.classList.remove('show');
            }
        }

        function debounce(func, delay) {
            let timer;
            return function () {
                clearTimeout(timer);
                timer = setTimeout(() => {
                    func.apply(this, arguments);
                }, delay);
            };
        }

        function createKPIErrorLabel() {
            const inputField = document.getElementById('<%=txtKPIID.ClientID%>');
            if (!inputField) {
                //  console.error("Cannot create error label: Input field not found");
                return null;
            }

            const errorSpan = document.createElement('span');
            errorSpan.id = 'dynamicKPIError';
            errorSpan.className = 'error-span';
            errorSpan.innerText = "KPI ID already exists";
            inputField.parentNode.appendChild(errorSpan);
            console.log("Dynamic error label created");
            return errorSpan;
        }

        function checkKPIID() {
            inputField = document.getElementById('<%=txtKPIID.ClientID%>')
            lblKPIError = document.getElementById('<%=lblKPIError.ClientID%>') || createKPIErrorLabel();
            const kpiID = inputField.value.trim().repalce(/\s{2,}/g, '');
            inputField.value = kpiID;
            if (kpiID === "") return;

            $.ajax({
                type: "POST",
                url: "Default.aspx/CheckKPIExists",
                data: JSON.stringify({ kpiID: kpiID }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                timeout: 10000,
                success: function (response) {
                    console.log("AJAX Response:", response);
                    if (response.d === true) {
                        lblKPIError.innerText = "KPI ID already exists";
                        lblKPIError.style.display = "inline";
                        // showElement(lblKPIError);
                    } else {
                        // hideElement(lblKPIError);
                        lblKPIError.style.display = "none";
                    }
                    // isCheckingKPI = false;
                },
                /*  error: function (xhr, status, error) {
                      console.error("AJAX error:", xhr.status, xhr.responseText, error);
                      isCheckingKPI = false;
                  }*/
            });
        }

        function validateBeforeSubmit() {
            if (!inputField) {
                inputField = document.getElementById('<%=txtKPIID.ClientID%>');
            }
            if (!lblKPIError) {
                lblKPIError = document.getElementById('<%=lblKPIError.ClientID%>');
                if (!lblKPIError) {
                    lblKPIError = document.getElementById('dynamicKPIError') || createKPIErrorLabel();
                }
            }

            if (!inputField || !lblKPIError) {
                console.error("Input field or error label not found during submission");
                return false;
            }

            var kpiID = inputField.value.trim().replace(/\s{2,}/g, ' ');
            inputField.value = kpiID;

            var isEdit = document.getElementById('<%=hfIsEdit.ClientID%>');
            var originalKPIID = document.getElementById('<%=hfKPIID.ClientID%>'); 
            if (isEdit && originalKPIID && isEdit.value === "true" && kpiID === originalKPIID.value) {
                hideElement(lblKPIError);
                return true;
            }

            if (lblKPIError.classList.contains('show')) {
                showElement(lblKPIError);
                return false;
            }

            let isValid = true;
            $.ajax({
                type: "POST",
                url: "Default.aspx/CheckKPIExists",
                data: JSON.stringify({ kpiID: kpiID }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                async: false,
                success: function (response) {
                    if (response.d === true) {
                        lblKPIError.innerText = "KPI ID already exists";
                        showElement(lblKPIError);
                        isValid = false;
                    } else {
                        hideElement(lblKPIError);
                    }
                },
                error: function (xhr, status, error) {
                    console.error("AJAX error on submit:", xhr.status, xhr.responseText, error);
                    isValid = false;
                }
            });

            return isValid;
        }

        $(document).ready(function () {
            //  console.log("Document ready, initializing KPI ID validation");
            const submitButton = document.getElementById('<%=btnSubmit.ClientID%>');

            inputField = document.getElementById('<%=txtKPIID.ClientID%>');
            lblKPIError = document.getElementById('<%=lblKPIError.ClientID%>') || createKPIErrorLabel();

            $(inputField).on('input', function () {
                clearTimeout(window.kpiCheckTimer);
                window.kpiCheckTimer = setTimeout(checkKPIID, 500);
            });

         /*   if (!lblKPIError) {
                lblKPIError = document.getElementById('dynamicKPIError') || createKPIErrorLabel();
            }

            console.log("Input field found:", inputField !== null);
            console.log("Error label found:", lblKPIError !== null);

            if (inputField && lblKPIError) {
                $(inputField).off('input.kpivalidation blur.kpivalidation');
                $(inputField).on('input.kpivalidation', debounce(checkKPIID, 500));
                $(inputField).on('blur.kpivalidation', checkKPIID);
                console.log("Event listeners attached for KPI ID validation");
            } else {
                console.error("Failed to initialize: Input or error label missing");
            }

            if (lblKPIError) {
                hideElement(lblKPIError);
            }*/

          //  var submitButton = document.getElementById('<%=btnSubmit.ClientID%>');
           // if (submitButton) {
                $(submitButton).off('click.kpivalidation').on('click.kpivalidation', function (e) {
                   /* if (!validateBeforeSubmit()) {
                        e.preventDefault();
                        showPopup();
                        return false;*/
                    console.log("submit clicked - letting server -side handle validation.");
                    
  
            });
        });

        function showKPIError(message) {
            if (!lblKPIError) {
                lblKPIError = document.getElementById('<%=lblKPIError.ClientID%>');
                    if (!lblKPIError) {
                        lblKPIError = document.getElementById('dynamicKPIError') || createKPIErrorLabel();
                    }
                }
                if (lblKPIError) {
                    lblKPIError.innerText = message || "KPI ID already exists";
                    showElement(lblKPIError);
                }
            }

            function hideKPIError() {
                if (!lblKPIError) {
                    lblKPIError = document.getElementById('<%=lblKPIError.ClientID%>');
                    if (!lblKPIError) {
                        lblKPIError = document.getElementById('dynamicKPIError') || createKPIErrorLabel();
                    }
                }
                if (lblKPIError) {
                    hideElement(lblKPIError);
                }
        }

        // Client-Side CSV Export Function
        function exportTableToCSV(filename) {
            var csv = [];
            var table = document.getElementById('<%= GridView1.ClientID %>'); // Get the GridView table
    if (!table) {
        alert("Could not find the data table to export.");
        console.error("Table element not found for export.");
        return;
    }

    // Get all rows in the table (including header)
    var rows = table.querySelectorAll("tr");

    for (var i = 0; i < rows.length; i++) {
        var row = [], cols = rows[i].querySelectorAll("td, th"); // Get cells (data & header)

        for (var j = 1; j < cols.length; j++) {
            // Get cell text and clean it for CSV
            // Handle potential commas, quotes, newlines within cell data
            let cellData = cols[j].innerText !== undefined ? cols[j].innerText : cols[j].textContent;
            // Escape double quotes by doubling them
            cellData = cellData.replace(/"/g, '""');
            // If data contains comma, newline, or quote, enclose it in double quotes
            if (cellData.indexOf(',') >= 0 || cellData.indexOf('\n') >= 0 || cellData.indexOf('"') >= 0) {
                cellData = '"' + cellData + '"';
            }
            row.push(cellData);
        }

        csv.push(row.join(",")); // Join cells with comma
    }

    // Create CSV string
    var csvString = csv.join("\n");
    // Add UTF-8 BOM for better Excel compatibility
    var BOM = "\uFEFF";

    // Create a Blob and trigger download
    var blob = new Blob([BOM + csvString], { type: 'text/csv;charset=utf-8;' });
    if (navigator.msSaveBlob) { // For IE
        navigator.msSaveBlob(blob, filename);
    } else {
        var link = document.createElement("a");
        if (link.download !== undefined) { // Feature detection
            // Create a link and trigger download
            var url = URL.createObjectURL(blob);
            link.setAttribute("href", url);
            link.setAttribute("download", filename);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } else {
            // Fallback: Open in new window (less ideal)
            alert("Your browser might not support direct downloads. The CSV data will open in a new tab. Please copy and save it.");
            window.open(URL.createObjectURL(blob));
        }
    }
        }


        // Function to toggle the switch state between Active and Inactive and trigger filter
        function toggleStatusFilter() {
            var hiddenField = document.getElementById('<%= hfStatusFilter.ClientID %>');
    var container = document.getElementById('statusToggleSwitch');
    var textDisplay = document.getElementById('statusFilterText');
    var currentState = hiddenField.value; // Get current value from HiddenField ('Y' or 'N')

    var newState, newDisplayText;

    // Toggle between Active ('Y') and Inactive ('N')
    if (currentState === 'Y') {
        newState = 'N';
        newDisplayText = 'Inactive';
        container.className = 'toggle-switch-container toggle-state-inactive';
    } else { // currentState === 'N'
        newState = 'Y';
        newDisplayText = 'Active';
        container.className = 'toggle-switch-container toggle-state-active';
    }

    // Update the HiddenField value
    hiddenField.value = newState;
    // Update the text display
    textDisplay.textContent = newDisplayText;

    // Trigger the hidden ASP.NET button click to initiate postback
    var hiddenButton = document.getElementById('<%= btnApplyStatusFilter.ClientID %>');
    if (hiddenButton) {
        hiddenButton.click();
    }
}

// Ensure the toggle UI matches the HiddenField value on initial page load/postbacks
$(document).ready(function () {
    var hiddenField = document.getElementById('<%= hfStatusFilter.ClientID %>');
    if (hiddenField) {
        var currentValue = hiddenField.value;
        var container = document.getElementById('statusToggleSwitch');
        var textDisplay = document.getElementById('statusFilterText');

        var displayText;
        // Set UI based on the current value in the HiddenField
        if (currentValue === 'Y') {
            container.className = 'toggle-switch-container toggle-state-active';
            displayText = 'Active';
        } else if (currentValue === 'N') {
            container.className = 'toggle-switch-container toggle-state-inactive';
            displayText = 'Inactive';
        } else {
            // Fallback: If value is unexpected, default to Active
            hiddenField.value = 'Y';
            container.className = 'toggle-switch-container toggle-state-active';
            displayText = 'Active';
            console.warn("Unexpected filter value '" + currentValue + "', defaulting to 'Active'.");
        }
        textDisplay.textContent = displayText;
    }
    // ... (rest of your existing $(document).ready code) ...
});


        function focusKPIInput() {
            var el = document.getElementById('<%=txtKPIID.ClientID%>');
       if (el) el.focus();
   }

    </script>
   
    <div id="kpiModal" class="modal">

        <span class="close-btn" onclick="hidePopup()">×</span>
        <h3><asp:Label ID="lblFormTitle" runat="server" Text="Add KPI" /></h3>
        <table>
            <tr><td>Metric:</td><td><asp:TextBox ID="txtMetric" runat="server" /></td></tr>
            <tr><td>Name:</td><td><asp:TextBox ID="txtKPIName" runat="server" /><asp:Label ID="lblDuplicateMetricKPIError" runat="server"   ForeColor="Red" Style="color: red;font-size: 12px; margin-top:5px;display:block;"  /></td></tr>
            <tr><td>KPI ID:</td><td><asp:TextBox ID="txtKPIID" runat="server" /><asp:Label ID="lblKPIError" runat="server" CssClass="error-span" Text="KPI ID already exists" ForeColor="Red" Visible="false" /></td></tr>
            <tr><td>Short Desc:</td><td><asp:TextBox ID="txtShortDesc" runat="server" TextMode="MultiLine" Rows="3" /></td></tr>
           <tr><td>Order:</td><td><asp:TextBox ID="txtOrder" runat="server" /><asp:Label ID="lblOrderError" runat="server"   Text="Please add numbers between 1–999" ForeColor="Red" Style="color: red;font-size: 12px; margin-top:5px;display:block;"  /></td></tr>
           
            <tr><td>Impact:</td><td><asp:TextBox ID="txtImpact" runat="server" TextMode="MultiLine" Rows="3" /></td></tr>
            <tr><td>Numerator:</td><td><asp:TextBox ID="txtNumerator" runat="server" TextMode="MultiLine" Rows="3" /></td></tr>
            <tr><td>Denominator:</td><td><asp:TextBox ID="txtDenom" runat="server" TextMode="MultiLine" Rows="3" /></td></tr>
            <tr><td>Unit:</td><td><asp:TextBox ID="txtUnit" runat="server" /></td></tr>
            <tr><td>Datasource:</td><td><asp:TextBox ID="txtDatasource" runat="server" /></td></tr>
            <tr><td>Constraints:</td><td><asp:TextBox ID="txtConstraints" runat="server" /></td></tr>
            <tr><td>Subject_ME_Email:</td><td><asp:TextBox ID="txtSubject_ME_Email" runat="server" TextMode="MultiLine" Rows="3"/></td></tr>
            <tr><td>OBJ_Subj:</td> <td> <asp:DropDownList ID="ddlSubj_Obj" runat="server"> 
               <asp:ListItem Text="Please Select" Value="NULL" />
                <asp:ListItem Text="Subjective" Value="Subjective" />
                <asp:ListItem Text="Objective" Value="Objective" />
            </asp:DropDownList></td> </tr>
            
            
            <tr><td>Active:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkActive" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_DIVISINAL:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagDivisinal" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_VENDOR:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagVendor" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_ENGAGEMENTID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagEngagement" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_CONTRACTID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagContract" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_COSTCENTRE:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagCostcentre" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_DEUBALvl4:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagDeuballvl4" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_HRID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagHRID" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_REQUESTID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagRequest" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>Comment:</td><td><asp:TextBox ID="txtComment" runat="server" TextMode="MultiLine" Rows="5" Width="520px" /></td></tr>
     
             <!-- Optional: Add a character counter or validation if needed -->
             <tr><td colspan="2" style="text-align:center;"><asp:Button ID="btnSubmit" runat="server" Text="Submit" OnClick="btnSubmit_Click" CssClass="btn-add" /></td></tr>
            
        </table>
        <asp:HiddenField ID="hfIsEdit" runat="server" />
        <asp:HiddenField ID="hfKPIID" runat="server" />
    </div>

    <asp:SqlDataSource ID="SqlDataSource1" runat="server"
        ConnectionString="<%$ ConnectionStrings:MyDbConnection %>"
        SelectCommand="dbo.GetAllKPITable"
        SelectCommandType="StoredProcedure"
        InsertCommand="dbo.InsertKPI"
        InsertCommandType="StoredProcedure"
        UpdateCommand="dbo.UpdateKPIByID"
        UpdateCommandType="StoredProcedure"
        DeleteCommand="dbo.DeleteKPIByID"
        DeleteCommandType="StoredProcedure">
        <SelectParameters>
            
            <asp:Parameter Name="SortColumn" Type="String" DefaultValue=" KPI ID" />
            <asp:Parameter Name="SortOrder" Type="String" DefaultValue="ASC" />
            <asp:ControlParameter Name="Status" ControlID="hfStatusFilter" PropertyName="Value" Type="String" ConvertEmptyStringToNull="true" DefaultValue=" " />
        </SelectParameters>

        <InsertParameters>
            <asp:Parameter Name="KPI_ID" />
            <asp:Parameter Name="KPI_or_Standalone_Metric" />
            <asp:Parameter Name="KPI_Name" />
            <asp:Parameter Name="KPI_Short_Description" />
            <asp:Parameter Name="KPI_Impact" />
            <asp:Parameter Name="Numerator_Description" />
            <asp:Parameter Name="Denominator_Description" />
            <asp:Parameter Name="Unit" />
            <asp:Parameter Name="Datasource" />
            <asp:Parameter Name="OrderWithinSecton" />
            <asp:Parameter Name="Constraints" />
            <asp:Parameter Name="Subject_ME_Email" />
            <asp:parameter Name="Subj_Obj" />
            <asp:Parameter Name="Active" />
            <asp:Parameter Name="FLAG_DIVISINAL" />
            <asp:Parameter Name="FLAG_VENDOR" />
            <asp:Parameter Name="FLAG_ENGAGEMENTID" />
            <asp:Parameter Name="FLAG_CONTRACTID" />
            <asp:Parameter Name="FLAG_COSTCENTRE" />
            <asp:Parameter Name="FLAG_DEUBALvl4" />
            <asp:Parameter Name="FLAG_HRID" />
            <asp:Parameter Name="FLAG_REQUESTID" />
            <asp:Parameter Name="Comment" />

        </InsertParameters>
        <UpdateParameters>
            <asp:Parameter Name="OriginalKPIID" Type="String" />
            <asp:Parameter Name="KPI_ID" />
            <asp:Parameter Name="KPI_or_Standalone_Metric" />
            <asp:Parameter Name="KPI_Name" />
            <asp:Parameter Name="KPI_Short_Description" />
            <asp:Parameter Name="KPI_Impact" />
            <asp:Parameter Name="Numerator_Description" />
            <asp:Parameter Name="Denominator_Description" />
            <asp:Parameter Name="Unit" />
            <asp:Parameter Name="Datasource" />
            <asp:Parameter Name="OrderWithinSecton" />
            <asp:Parameter Name="Constraints" />
            <asp:Parameter Name="Subject_ME_Email" />
            <asp:parameter Name="Subj_Obj" />
            <asp:Parameter Name="Active" />
            <asp:Parameter Name="FLAG_DIVISINAL" />
            <asp:Parameter Name="FLAG_VENDOR" />
            <asp:Parameter Name="FLAG_ENGAGEMENTID" />
            <asp:Parameter Name="FLAG_CONTRACTID" />
            <asp:Parameter Name="FLAG_COSTCENTRE" />
            <asp:Parameter Name="FLAG_DEUBALvl4" />
            <asp:Parameter Name="FLAG_HRID" />
            <asp:Parameter Name="FLAG_REQUESTID" />
            <asp:Parameter Name="Comment" />

        </UpdateParameters>
         <DeleteParameters>
        <asp:Parameter Name="KPI_ID" />
    </DeleteParameters>
    </asp:SqlDataSource>

    <!-- Add Active Status Filter Control (True Toggle Switch - Active/Inactive Only) -->
<div style="margin-bottom: 10px;">
    <label for="statusToggle" style="vertical-align: middle;"><strong>Filter Status:</strong></label>
    
    <!-- Hidden input to store the filter value ('Y' or 'N') and trigger postback -->
    <asp:HiddenField ID="hfStatusFilter" runat="server" Value="Y" /> <!-- Default to 'Y' (Active) -->

    <!-- The Visual Toggle Switch -->
    <div class="toggle-switch-ui" style="display: inline-block; margin: 0 15px; vertical-align: middle;" onclick="toggleStatusFilter()">
        <div class="toggle-switch-container toggle-state-active" id="statusToggleSwitch"> <!-- Start in Active state -->
            <div class="toggle-switch-slider" id="statusToggleSlider"></div>
        </div>
    </div>

    <!-- Display current filter state text (Active/Inactive only) -->
    <span id="statusFilterText" style="font-weight: bold;">Active</span> <!-- Default text -->

    <!-- Hidden ASP.NET Button to trigger the server-side event -->
    <asp:Button ID="btnApplyStatusFilter" runat="server" OnClick="btnApplyStatusFilter_Click" style="display:none;" />
</div>

    <div style=" text-align:right;margin-bottom: 10px;">

        <div style=" text-align:left;margin-bottom: 10px;">
    <!-- Export Button -->
    <button type="button" id="btnExportCSV" onclick="exportTableToCSV('KPIs_<%= DateTime.Now.ToString("yyyyMMdd_HHmmss") %>.csv')" class="btn-add" style="margin-right: 10px;">Export to CSV</button>
            </div>

     <label for="searchBox"><strong>Search:</strong></label>
        <input type="text" id="searchBox" placeholder="Type to search..." style="width: 250px; padding: 5px;"
               onkeyup="filterTable()" onkeydown="if(event.key==='Enter') event.preventDefault();" /> 
    </div>
    <div class="kpi-table-scroll">
    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" DataSourceID="SqlDataSource1" CssClass="grid-style"  ShowHeader ="true" UseAccessibleHeader="true" EmptyDataText="No KPI data available" OnRowCommand="GridView1_RowCommand"  AllowSorting="true" OnSorting="GridView1_Sorting" DataKeyNames="KPI ID">
        <Columns>
            <asp:TemplateField>
                <HeaderTemplate>
                    <asp:Button ID="btnAddKPI" runat="server" Text="+ Add KPI" CssClass="btn-add" OnClick="btnAddKPI_Click" />
                </HeaderTemplate>
                <ItemTemplate>
                    <asp:Button ID="btnEdit" runat="server" Text="Edit" CommandName="EditKPI" CommandArgument='<%# Container.DataItemIndex %>' CssClass="btn-edit" />
                    <asp:Button ID="btnDelete" runat="server" Text="Delete"
                    CommandName="DeleteKPI" CommandArgument='<%# Container.DataItemIndex %>'
                    CssClass="btn-delete" OnClientClick="return confirm('Are you sure you want to delete this KPI?');" />

                    <asp:Button ID="btnClone" runat="server" Text="Clone"  CommandName="CloneKPI"
            CommandArgument='<%# Container.DataItemIndex %>' CssClass="btn-add" />


            </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="KPI or Standalone Metric" HeaderText="Metric" SortExpression="KPI or Standalone Metric" />
            <asp:BoundField DataField="KPI Name" HeaderText="KPI Name" SortExpression="KPI Name" />
            <asp:BoundField DataField="KPI ID" HeaderText="KPI ID" SortExpression="KPI ID"/>
            <asp:BoundField DataField="KPI Short Description" HeaderText="Short Description" SortExpression="KPI Short Description"/>
            <asp:BoundField DataField="KPI Impact" HeaderText="Impact" SortExpression="KPI Impact"/>
            <asp:BoundField DataField="Numerator Description" HeaderText="Numerator" SortExpression="Numerator Description"/>
            <asp:BoundField DataField="Denominator Description" HeaderText="Denominator" SortExpression="Denominator Description"/>
            <asp:BoundField DataField="Unit" HeaderText="Unit" SortExpression="Unit"/>
            <asp:BoundField DataField="Datasource" HeaderText="Datasource" SortExpression="Datasource"/>
            <asp:BoundField DataField="OrderWithinSecton" HeaderText="Order" SortExpression="OrderWithinSecton" />
            <asp:BoundField DataField="Constraints" HeaderText="Constraints" SortExpression="Constraints" />
            <asp:BoundField DataField="Subject_ME_Email" HeaderText="Subject_ME_Email" SortExpression="Subject_ME_Email" />
            <asp:BoundField DataField="Subj_Obj" HeaderText="Subj/Obj" SortExpression="Subj_Obj" />
            <asp:TemplateField HeaderText="Active" SortExpression="Active"><ItemTemplate><%# If(Eval("Active").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG DIVISINAL" SortExpression="FLAG_DIVISINAL"><ItemTemplate><%# If(Eval("FLAG_DIVISINAL").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG VENDOR" SortExpression="FLAG_VENDOR"><ItemTemplate><%# If(Eval("FLAG_VENDOR").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG ENGAGEMENTID" SortExpression="FLAG_ENGAGEMENTID"><ItemTemplate><%# If(Eval("FLAG_ENGAGEMENTID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG CONTRACTID" SortExpression="FLAG_CONTRACTID"><ItemTemplate><%# If(Eval("FLAG_CONTRACTID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG COSTCENTRE" SortExpression="FLAG_COSTCENTRE"><ItemTemplate><%# If(Eval("FLAG_COSTCENTRE").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG DEUBALvl4" SortExpression="FLAG DEUBALvl4"><ItemTemplate><%# If(Eval("FLAG_DEUBALvl4").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG HRID" SortExpression="FLAG HRID"><ItemTemplate><%# If(Eval("FLAG_HRID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG REQUESTID" SortExpression="FLAG REQUESTID"><ItemTemplate><%# If(Eval("FLAG_REQUESTID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:BoundField DataField="Comment" HeaderText="Comment" SortExpression="Comment" />

            
        </Columns>
        <EmptyDataTemplate>
    <table class="grid-style">
        <thead>
            <tr>
               <%-- <th><asp:Button ID="btnAddKPIEmpty" runat="server" Text="+ Add KPI"
                        CssClass="btn-add" OnClick="btnAddKPI_Click" /></th>--%>
                <th>KPI ID</th>
                <th>KPI or Standalone Metric</th>
                <th>KPI Name</th>
                <th>KPI Short Description</th>
                <th>KPI Impact</th>
                <th>Numerator Description</th>
                <th>Denominator Description</th>
                <th>Unit</th>
               <th>Datasource</th>
                <th>OrderWithinSecton</th>
                <th>Constraints</th>
                <th>Subject_ME_Email</th>
                <th>Subj_Obj</th>
                <th>Active</th>
                <th>FLAG_DIVISINAL</th>
                <th>FLAG_VENDOR</th>
                <th>FLAG_ENGAGEMENTID</th>
                <th>FLAG_CONTRACTID</th>
                <th>FLAG_COSTCENTRE</th>
                <th>FLAG_DEUBALvl4</th>
                <th>FLAG_HRID</th>
                <th>FLAG_REQUESTID</th>
                <th>Comment</th>

                <!-- Add any other headers manually -->
            </tr>
        </thead>
        <tbody>
            <tr>
                <td colspan="22" style="text-align:center; color: gray;">No KPI data available</td>
            </tr>
        </tbody>
    </table>
</EmptyDataTemplate>

    </asp:GridView>
        </div>
</asp:Content>