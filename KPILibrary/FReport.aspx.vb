Public Class FReport
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            FilterBoxControl.LoadFilters()
        End If
    End Sub

    Public Sub ShowReportMessage(fromDate As String, toDate As String)
        litMessage.Text =
                $"<div style='padding:10px;border:1px solid green;color:green;'>
                    Report Generated Successfully!<br/>
                    <b>Report From:</b> {fromDate}<br/>
                    <b>Report To:</b> {toDate}
                  </div>"
    End Sub

End Class

