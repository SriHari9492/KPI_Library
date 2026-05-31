<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="FilterBoxControl.ascx.vb" Inherits="KPILibrary.FilterBoxControl" %>

<%@ Register Src="~/Controls/MultiSelectFilter.ascx" TagPrefix="uc" TagName="MultiSelectFilter" %>

<div>

 <uc:MultiSelectFilter ID="fltReportFrom" runat="server" LabelText="Report From" />
<uc:MultiSelectFilter ID="fltReportTo" runat="server" LabelText="Report To" />

<uc:MultiSelectFilter ID="fltPeriod" runat="server" LabelText="Period" />
<uc:MultiSelectFilter ID="fltGroupName" runat="server" LabelText="Group Name" />
<uc:MultiSelectFilter ID="fltVendor" runat="server" LabelText="Vendor" />

<asp:Button ID="btnGenerateReport" runat="server" Text="Generate Report" />


</div>