Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

Public Class GetQuarterDates
    Inherits System.Web.UI.Page

    Private ReadOnly ConnStr As String =
           ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        Dim period As String = Request.QueryString("period")

        Dim sql As String =
                "SELECT MIN(ReportDate) AS FromDate,
                        MAX(ReportDate) AS ToDate
                 FROM EMSSTAGING_fact_KPILibrary_Union
                 WHERE KPIReportingRun = @Period"

        Dim dt As New DataTable()

        Using con As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand(sql, con)
                cmd.Parameters.AddWithValue("@Period", period)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        Dim fromDate As String = ""
        Dim toDate As String = ""

        If dt.Rows.Count > 0 AndAlso Not IsDBNull(dt.Rows(0)("FromDate")) Then
            fromDate = CDate(dt.Rows(0)("FromDate")).ToString("dd-MM-yyyy")
            toDate = CDate(dt.Rows(0)("ToDate")).ToString("dd-MM-yyyy")
        End If

        Dim js As New JavaScriptSerializer()

        Response.ContentType = "application/json"
        Response.Write(js.Serialize(New With {
                .from = fromDate,
                .to = toDate
            }))
        Response.End()

    End Sub

End Class
