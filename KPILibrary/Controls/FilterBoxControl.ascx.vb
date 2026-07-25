Imports System.Data.SqlClient

Public Class FilterBoxControl
    Inherits System.Web.UI.UserControl

    Private ReadOnly ConnStr As String =
            ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString

    Public Sub LoadFilters()
        LoadPeriodFilter()
        LoadGroupFilter()
        LoadVendorFilter()
    End Sub


    ' ============================
    ' PERIOD
    ' ============================
    Private Sub LoadPeriodFilter()
        Dim dt As New DataTable()

        Using con As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("
                SELECT DISTINCT KPIReportingRun 
                FROM EMSSTAGING_fact_KPILibrary_Union 
                ORDER BY KPIReportingRun", con)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        fltPeriod.CheckBoxListDataSource = dt
        fltPeriod.IsSingleSelect = True
        fltPeriod.IsPeriodFilter = True
    End Sub


    ' ============================
    ' GROUP NAME
    ' ============================
    Private Sub LoadGroupFilter()
        Dim dt As New DataTable()

        Using con As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("
                SELECT DISTINCT GroupName 
                FROM EMSSTAGING_fact_KPILibrary_Union 
                ORDER BY GroupName", con)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        fltGroupName.CheckBoxListDataSource = dt
        fltGroupName.IsSingleSelect = True
    End Sub


    ' ============================
    ' VENDOR
    ' ============================
    Private Sub LoadVendorFilter()
        Dim dt As New DataTable()

        Using con As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("
                SELECT DISTINCT VendorName 
                FROM EMSSTAGING_fact_KPILibrary_Union 
                WHERE VendorName IS NOT NULL
                ORDER BY VendorName", con)
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        fltVendor.CheckBoxListDataSource = dt
        fltVendor.IsSingleSelect = False
    End Sub



    ' ===================================
    '  PERIOD EVENT → AUTO-FILL DATES
    ' ===================================
    Public Sub fltPeriod_Raised(sender As Object, e As EventArgs) _
        Handles fltPeriod.BubbleEvent

        Dim selectedPeriod As String = fltPeriod.MultiSelectValue
        If String.IsNullOrEmpty(selectedPeriod) Then Exit Sub

        Dim dt As New DataTable()

        Using con As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("
                SELECT ReportDate
                FROM EMSSTAGING_fact_KPILibrary_Union
                WHERE KPIReportingRun = @p", con)

                cmd.Parameters.AddWithValue("@p", selectedPeriod)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        If dt.Rows.Count > 0 Then
            Dim dates = dt.AsEnumerable().Select(Function(r) CDate(r("ReportDate")))

            fltReportFrom.SelectedText = dates.Min().ToString("dd-MM-yyyy")
            fltReportTo.SelectedText = dates.Max().ToString("dd-MM-yyyy")

        End If

    End Sub

    ' Public method to allow child controls to set ReportFrom value
    Public Sub SetReportFrom(value As String)
        fltReportFrom.SelectedText = value
    End Sub

    Public Sub SetReportTo(value As String)
        fltReportTo.SelectedText = value
    End Sub


    Public Function GetQuarterDates(quarter As String) As DataTable
        Dim dt As New DataTable()

        Using con As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand("
                SELECT ReportDate 
                FROM EMSSTAGING_fact_KPILibrary_Union
                WHERE KPIReportingRun = @q", con)

                cmd.Parameters.AddWithValue("@q", quarter)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dt)
                End Using
            End Using
        End Using

        Return dt
    End Function



    Protected Sub btnGenerateReport_Click(sender As Object, e As EventArgs) _
        Handles btnGenerateReport.Click

        ' Prefer the explicitly filled text (SelectedText). If empty, try to compute using selected period.
        Dim fromDate As String = fltReportFrom.SelectedTextValue
        Dim toDate As String = fltReportTo.SelectedTextValue

        If String.IsNullOrWhiteSpace(fromDate) OrElse String.IsNullOrWhiteSpace(toDate) Then
            Dim selPeriod As String = fltPeriod.MultiSelectValue
            If Not String.IsNullOrWhiteSpace(selPeriod) Then
                Dim dt As DataTable = GetQuarterDates(selPeriod)
                If dt.Rows.Count > 0 Then
                    Dim dates = dt.AsEnumerable().Select(Function(r) CDate(r("ReportDate")))
                    fromDate = dates.Min().ToString("dd-MM-yyyy")
                    toDate = dates.Max().ToString("dd-MM-yyyy")

                    ' keep UI in sync
                    fltReportFrom.SelectedText = fromDate
                    fltReportTo.SelectedText = toDate
                End If
            End If
        End If

        ' If still empty, show a friendly error instead of passing empty strings
        If String.IsNullOrWhiteSpace(fromDate) OrElse String.IsNullOrWhiteSpace(toDate) Then
            ' you can surface a message in the page or throw; here we call ShowReportMessage with empty values
            CType(Page, FReport).ShowReportMessage(String.Empty, String.Empty)
            Return
        End If

        CType(Page, FReport).ShowReportMessage(fromDate, toDate)
    End Sub

End Class