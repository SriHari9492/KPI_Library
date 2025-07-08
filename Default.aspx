<%@ Page Title="Home Page" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Default.aspx.vb" Inherits="KPILibrary2._Default" %>

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
            margin-left: 10px; 
            display:none;
            visibility:hidden;
            font-weight: bold;
        }
        .error-span.show {
            display: inline;
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
        table { width: 100%; border-collapse: collapse; }
        table td, table th { padding: 8px; border: 1px solid #ccc; }
        .grid-style { border-collapse: collapse; width: 100%; }
        .grid-style td, .grid-style th { border: 1px solid #ddd; padding: 8px; }
        .grid-style th { background-color: #f2f2f2; }
        .modal input[type="text"], .modal textarea {
            width: 520px; max-width: none !important; box-sizing: border-box;
        }
    </style>

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script>
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
                console.error("Cannot create error label: Input field not found");
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
            if (isCheckingKPI) {
                return;
            }

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
                console.error("Input field or error label not found");
                return;
            }

            var kpiID = inputField.value.trim().replace(/\s{2,}/g, ' ');
            inputField.value = kpiID;

            if (kpiID === "") {
                hideElement(lblKPIError);
                return;
            }

            var isEdit = document.getElementById('<%=hfIsEdit.ClientID%>');
            var originalKPIID = document.getElementById('<%=hfKPIID.ClientID%>');
            if (isEdit && originalKPIID && isEdit.value === "true" && kpiID === originalKPIID.value) {
                hideElement(lblKPIIDError);
                return;
            }

            isCheckingKPI = true;

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
                        showElement(lblKPIError);
                    } else {
                        hideElement(lblKPIError);
                    }
                    isCheckingKPI = false;
                },
                error: function (xhr, status, error) {
                    console.error("AJAX error:", xhr.status, xhr.responseText, error);
                    isCheckingKPI = false;
                }
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
            console.log("Document ready, initializing KPI ID validation");

            inputField = document.getElementById('<%=txtKPIID.ClientID%>');
            lblKPIError = document.getElementById('<%=lblKPIError.ClientID%>');
            if (!lblKPIError) {
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
            }

            var submitButton = document.getElementById('<%=btnSubmit.ClientID%>');
            if (submitButton) {
                $(submitButton).off('click.kpivalidation').on('click.kpivalidation', function (e) {
                    if (!validateBeforeSubmit()) {
                        e.preventDefault();
                        showPopup();
                        return false;
                    }
                });
            }
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
            <tr><td>Active:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkActive" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_DIVISINAL:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagDivisinal" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_VENDOR:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagVendor" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_ENGAGEMENTID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagEngagement" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_CONTRACTID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagContract" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_COSTCENTRE:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagCostcentre" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_DEUBALvl4:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagDeuballvl4" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_HRID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagHRID" runat="server" /><span class="slider"></span></label></td></tr>
            <tr><td>FLAG_REQUESTID:</td><td><label class="toggle-switch"><asp:CheckBox ID="chkFlagRequest" runat="server" /><span class="slider"></span></label></td></tr>
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
        UpdateCommandType="StoredProcedure">
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
            <asp:Parameter Name="Active" />
            <asp:Parameter Name="FLAG_DIVISINAL" />
            <asp:Parameter Name="FLAG_VENDOR" />
            <asp:Parameter Name="FLAG_ENGAGEMENTID" />
            <asp:Parameter Name="FLAG_CONTRACTID" />
            <asp:Parameter Name="FLAG_COSTCENTRE" />
            <asp:Parameter Name="FLAG_DEUBALvl4" />
            <asp:Parameter Name="FLAG_HRID" />
            <asp:Parameter Name="FLAG_REQUESTID" />
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
            <asp:Parameter Name="Active" />
            <asp:Parameter Name="FLAG_DIVISINAL" />
            <asp:Parameter Name="FLAG_VENDOR" />
            <asp:Parameter Name="FLAG_ENGAGEMENTID" />
            <asp:Parameter Name="FLAG_CONTRACTID" />
            <asp:Parameter Name="FLAG_COSTCENTRE" />
            <asp:Parameter Name="FLAG_DEUBALvl4" />
            <asp:Parameter Name="FLAG_HRID" />
            <asp:Parameter Name="FLAG_REQUESTID" />
        </UpdateParameters>
    </asp:SqlDataSource>

    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" DataSourceID="SqlDataSource1" CssClass="grid-style" OnRowCommand="GridView1_RowCommand">
        <Columns>
            <asp:TemplateField>
                <HeaderTemplate>
                    <asp:Button ID="btnAddKPI" runat="server" Text="+ Add KPI" CssClass="btn-add" OnClick="btnAddKPI_Click" />
                </HeaderTemplate>
                <ItemTemplate>
                    <asp:Button ID="btnEdit" runat="server" Text="Edit" CommandName="EditKPI" CommandArgument='<%# Container.DataItemIndex %>' CssClass="btn-edit" />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="KPI or Standalone Metric" HeaderText="Metric" />
            <asp:BoundField DataField="KPI Name" HeaderText="KPI Name" />
            <asp:BoundField DataField="KPI ID" HeaderText="KPI ID" />
            <asp:BoundField DataField="KPI Short Description" HeaderText="Short Description" />
            <asp:BoundField DataField="KPI Impact" HeaderText="Impact" />
            <asp:BoundField DataField="Numerator Description" HeaderText="Numerator" />
            <asp:BoundField DataField="Denominator Description" HeaderText="Denominator" />
            <asp:BoundField DataField="Unit" HeaderText="Unit" />
            <asp:BoundField DataField="Datasource" HeaderText="Datasource" />
            <asp:BoundField DataField="OrderWithinSecton" HeaderText="Order" />
            <asp:TemplateField HeaderText="Active"><ItemTemplate><%# If(Eval("Active").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG DIVISINAL"><ItemTemplate><%# If(Eval("FLAG_DIVISINAL").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG VENDOR"><ItemTemplate><%# If(Eval("FLAG_VENDOR").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG ENGAGEMENTID"><ItemTemplate><%# If(Eval("FLAG_ENGAGEMENTID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG CONTRACTID"><ItemTemplate><%# If(Eval("FLAG_CONTRACTID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG COSTCENTRE"><ItemTemplate><%# If(Eval("FLAG_COSTCENTRE").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG DEUBALvl4"><ItemTemplate><%# If(Eval("FLAG_DEUBALvl4").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG HRID"><ItemTemplate><%# If(Eval("FLAG_HRID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
            <asp:TemplateField HeaderText="FLAG REQUESTID"><ItemTemplate><%# If(Eval("FLAG_REQUESTID").ToString() = "Y", "YES", "NO") %></ItemTemplate></asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>


