<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="FReport.aspx.vb" Inherits="KPILibrary.FReport" %>

<%@ Register Src="~/Controls/FilterBoxControl.ascx" TagPrefix="uc" TagName="FilterBox" %>

<%@ Register Src="~/Controls/MultiSelectFilter.ascx" TagPrefix="uc" TagName="MultiSelectFilter" %>


<!DOCTYPE html>

<html>
<head runat="server">
    <title>Stakeholder Report</title>

    <script>

        document.addEventListener("DOMContentLoaded", function () {

            console.log("StakeholderReport.js Loaded");

            // SINGLE SELECT HANDLER
            window.handleSingleSelect = function (cbListClientId, index) {

                let cbList = document.getElementById(cbListClientId);
                if (!cbList) return;

                let items = cbList.querySelectorAll("input[type='checkbox']");
                items.forEach((box, i) => {
                    if (i !== index) box.checked = false;
                });

                updateText(cbList);
                updateReportDates(cbList);
            };


            // UPDATE TEXTBOX
            function updateText(cbList) {
                let wrapper = cbList.closest(".listViewBox");
                let txt = wrapper.previousElementSibling.querySelector("input[type='text']");
                let labels = cbList.querySelectorAll("label");
                let boxes = cbList.querySelectorAll("input[type='checkbox']");

                let selected = [];

                boxes.forEach((b, i) => {
                    if (b.checked)
                        selected.push(labels[i].innerText.trim());
                });

                txt.value = selected.join(",");
            }

            // AUTO UPDATE REPORTFROM / REPORTTO
            function updateReportDates(cbList) {

                let wrapper = cbList.closest(".listViewBox");
                let period = wrapper.previousElementSibling.querySelector("input[type='text']").value;

                if (!period) return;

                fetch("GetQuarterDates.aspx?period=" + period)
                    .then(r => r.json())
                    .then(d => {

                        document.getElementById("ctl00_MainContent_FilterBoxControl_fltReportFrom_ListView_TextBox").value = d.from;
                        document.getElementById("ctl00_MainContent_FilterBoxControl_fltReportTo_ListView_TextBox").value = d.to;

                    });
            }

        });

    </script>

    <style>
      .filter-panel {
            padding: 12px;
              background: #f0f0f0;
            border: 1px solid #ccc;
            margin-bottom: 20px;
        }
    </style>
</head>

<body>
    <form id="form2" runat="server">

        <div class="filter-panel">
            <uc:FilterBox ID="FilterBoxControl" runat="server" />
        </div>

        <asp:Panel ID="pnlReport" runat="server">
            <asp:Literal ID="litMessage" runat="server"></asp:Literal>
        </asp:Panel>

    </form>
</body>
</html>



