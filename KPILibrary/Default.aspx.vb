Imports System.Data.SqlClient
Imports System.Configuration
Imports System.Web.Script.Services
Imports System.Web.Services
Imports System.Text.RegularExpressions



<ScriptService()>
Public Class _Default
    Inherits Page
        
    Private Property SortExpression As String
        Get
            Return If(ViewState("SortExpression"), "[KPI or Standalone Metric]") ' Default sort column
        End Get
        Set(value As String)
            ViewState("SortExpression") = value
        End Set
    End Property

    Private Property SortDirection As SortDirection
        Get
            Dim dir As Object = ViewState("SortDirection")
            If dir IsNot Nothing Then
                Return CType(dir, SortDirection)
            End If
            Return SortDirection.Ascending ' Default sort direction
        End Get
        Set(value As SortDirection)
            ViewState("SortDirection") = value
        End Set
    End Property

    ' --- Page Events ---



    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Initialize the HiddenField to the default filter state ('Y' for Active)
            hfStatusFilter.Value = "Y" ' Or "N" if you prefer Inactive as default

            ' Optional: Set initial SqlDataSource parameters if defaults don't align
            ' If SqlDataSource1.SelectParameters("SortColumn").DefaultValue <> "YourDesiredInitialSort" Then
            '     SqlDataSource1.SelectParameters("SortColumn").DefaultValue = "YourDesiredInitialSort"
            ' End If

            ' Bind the GridView with the default filter/sort
            GridView1.DataBind()
        End If

    End Sub

    Protected Sub btnSubmit_Click(sender As Object, e As EventArgs) Handles btnSubmit.Click
        Dim originalKPIID As String = hfKPIID.Value.Trim()
        Dim orderValue As Integer = 0
        Dim valid As Boolean = True

        ' Clean and normalize inputs
        Dim kpiID As String = CleanInput(txtKPIID.Text)
        Dim metric As String = CleanInput(txtMetric.Text)
        Dim kpiName As String = CleanInput(txtKPIName.Text)
        Dim shortDesc As String = CleanInput(txtShortDesc.Text)
        Dim impact As String = CleanInput(txtImpact.Text)
        Dim numerator As String = CleanInput(txtNumerator.Text)
        Dim denom As String = CleanInput(txtDenom.Text)
        Dim unit As String = CleanInput(txtUnit.Text)
        Dim datasource As String = CleanInput(txtDatasource.Text)
        Dim orderText As String = CleanInput(txtOrder.Text)
        Dim Constraints As String = CleanInput(txtConstraints.Text)
        Dim Subject_ME_Email As String = CleanInput(txtSubject_ME_Email.Text)


        ' Reset all error labels
        lblKPIError.Visible = False
        lblOrderError.Visible = False
        lblDuplicateMetricKPIError.Visible = False

        ' Basic field validation
        If String.IsNullOrWhiteSpace(kpiID) OrElse String.IsNullOrWhiteSpace(metric) OrElse
           String.IsNullOrWhiteSpace(kpiName) OrElse String.IsNullOrWhiteSpace(shortDesc) OrElse
           String.IsNullOrWhiteSpace(impact) OrElse String.IsNullOrWhiteSpace(numerator) OrElse
           String.IsNullOrWhiteSpace(denom) OrElse String.IsNullOrWhiteSpace(unit) OrElse
           String.IsNullOrWhiteSpace(datasource) OrElse String.IsNullOrWhiteSpace(orderText) OrElse
           String.IsNullOrWhiteSpace(Constraints) OrElse String.IsNullOrWhiteSpace(Subject_ME_Email) Then

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowModal_" & Guid.NewGuid().ToString(), "showPopup();", True)
            Return
        End If

        ' Order Validation
        If Not Integer.TryParse(orderText, orderValue) OrElse orderValue < 1 OrElse orderValue > 999 Then
            lblOrderError.Text = "Order must be between 1 and 999."
            lblOrderError.Visible = True
            valid = False
        Else
            ' Check for duplicate order within same metric
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("
                    SELECT COUNT(*) FROM KPITable 
                    WHERE [KPI or Standalone Metric] = @Metric 
                      AND OrderWithinSecton = @Order 
                      AND [KPI ID] <> @OriginalKPIID", conn)
                    cmd.Parameters.AddWithValue("@Metric", metric)
                    cmd.Parameters.AddWithValue("@Order", orderValue)
                    cmd.Parameters.AddWithValue("@OriginalKPIID", originalKPIID)
                    Dim count = Convert.ToInt32(cmd.ExecuteScalar())
                    If count > 0 Then
                        lblOrderError.Text = "No duplicate order allowed for same metric."
                        lblOrderError.Visible = True
                        valid = False
                    End If
                End Using
            End Using
        End If

        ' KPI ID uniqueness validation (if new or modified)
        If hfIsEdit.Value <> "true" OrElse kpiID <> originalKPIID Then
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("SELECT COUNT(*) FROM KPITable WHERE [KPI ID] = @KPI_ID", conn)
                    cmd.Parameters.AddWithValue("@KPI_ID", kpiID)
                    Dim count = Convert.ToInt32(cmd.ExecuteScalar())
                    If count > 0 Then
                        lblKPIError.Visible = True
                        lblKPIError.Text = "KPI ID already exists"
                        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowKPIError_" & Guid.NewGuid().ToString(),
                            "showKPIError('KPI ID already exists');", True)
                        System.Diagnostics.Debug.WriteLine("KPI ID validation failed: " & kpiID)
                        valid = False
                    End If
                End Using
            End Using
        End If

        ' KPI Name uniqueness per metric
        Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString)
            conn.Open()
            Using cmd As New SqlCommand("
                SELECT COUNT(*) FROM KPITable 
                WHERE [KPI or Standalone Metric] = @Metric 
                  AND [KPI Name] = @KPIName 
                  AND [KPI ID] <> @OriginalKPIID", conn)
                cmd.Parameters.AddWithValue("@Metric", metric)
                cmd.Parameters.AddWithValue("@KPIName", kpiName)
                cmd.Parameters.AddWithValue("@OriginalKPIID", originalKPIID)
                Dim count = Convert.ToInt32(cmd.ExecuteScalar())
                If count > 0 Then
                    lblDuplicateMetricKPIError.Text = "No duplicate names should be given to a single metric."
                    lblDuplicateMetricKPIError.Visible = True
                    valid = False
                End If
            End Using
        End Using

        ' If validation failed, show modal and return
        If Not valid Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowModal_" & Guid.NewGuid().ToString(), "showPopup();", True)
            Return
        End If

        ' If we reach here, validation passed - proceed with save
        Try
            If hfIsEdit.Value = "true" Then
                ' Update existing record
                SqlDataSource1.UpdateParameters("OriginalKPIID").DefaultValue = originalKPIID
                SqlDataSource1.UpdateParameters("KPI_ID").DefaultValue = kpiID
                SqlDataSource1.UpdateParameters("KPI_or_Standalone_Metric").DefaultValue = metric
                SqlDataSource1.UpdateParameters("KPI_Name").DefaultValue = kpiName
                SqlDataSource1.UpdateParameters("KPI_Short_Description").DefaultValue = shortDesc
                SqlDataSource1.UpdateParameters("KPI_Impact").DefaultValue = impact
                SqlDataSource1.UpdateParameters("Numerator_Description").DefaultValue = numerator
                SqlDataSource1.UpdateParameters("Denominator_Description").DefaultValue = denom
                SqlDataSource1.UpdateParameters("Unit").DefaultValue = unit
                SqlDataSource1.UpdateParameters("Datasource").DefaultValue = datasource
                SqlDataSource1.UpdateParameters("OrderWithinSecton").DefaultValue = orderValue.ToString()
                SqlDataSource1.UpdateParameters("Constraints").DefaultValue = Constraints
                SqlDataSource1.UpdateParameters("Subject_ME_Email").DefaultValue = Subject_ME_Email
                SqlDataSource1.UpdateParameters("Active").DefaultValue = If(chkActive.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_DIVISINAL").DefaultValue = If(chkFlagDivisinal.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_VENDOR").DefaultValue = If(chkFlagVendor.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_ENGAGEMENTID").DefaultValue = If(chkFlagEngagement.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_CONTRACTID").DefaultValue = If(chkFlagContract.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_COSTCENTRE").DefaultValue = If(chkFlagCostcentre.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_DEUBALvl4").DefaultValue = If(chkFlagDeuballvl4.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_HRID").DefaultValue = If(chkFlagHRID.Checked, "Y", "N")
                SqlDataSource1.UpdateParameters("FLAG_REQUESTID").DefaultValue = If(chkFlagRequest.Checked, "Y", "N")


                SqlDataSource1.Update()
            Else
                ' Insert new record
                SqlDataSource1.InsertParameters("KPI_ID").DefaultValue = kpiID
                SqlDataSource1.InsertParameters("KPI_or_Standalone_Metric").DefaultValue = metric
                SqlDataSource1.InsertParameters("KPI_Name").DefaultValue = kpiName
                SqlDataSource1.InsertParameters("KPI_Short_Description").DefaultValue = shortDesc
                SqlDataSource1.InsertParameters("KPI_Impact").DefaultValue = impact
                SqlDataSource1.InsertParameters("Numerator_Description").DefaultValue = numerator
                SqlDataSource1.InsertParameters("Denominator_Description").DefaultValue = denom
                SqlDataSource1.InsertParameters("Unit").DefaultValue = unit
                SqlDataSource1.InsertParameters("Datasource").DefaultValue = datasource
                SqlDataSource1.InsertParameters("OrderWithinSecton").DefaultValue = orderValue.ToString()
                SqlDataSource1.InsertParameters("Constraints").DefaultValue = Constraints
                SqlDataSource1.InsertParameters("Subject_ME_Email").DefaultValue = Subject_ME_Email
                SqlDataSource1.InsertParameters("Active").DefaultValue = If(chkActive.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_DIVISINAL").DefaultValue = If(chkFlagDivisinal.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_VENDOR").DefaultValue = If(chkFlagVendor.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_ENGAGEMENTID").DefaultValue = If(chkFlagEngagement.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_CONTRACTID").DefaultValue = If(chkFlagContract.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_COSTCENTRE").DefaultValue = If(chkFlagCostcentre.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_DEUBALvl4").DefaultValue = If(chkFlagDeuballvl4.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_HRID").DefaultValue = If(chkFlagHRID.Checked, "Y", "N")
                SqlDataSource1.InsertParameters("FLAG_REQUESTID").DefaultValue = If(chkFlagRequest.Checked, "Y", "N")

                SqlDataSource1.Insert()
            End If

            ' Success - clear form and refresh grid
            ClearForm()
            GridView1.DataBind()

            ' Hide modal and show success message
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "HideModal_" & Guid.NewGuid().ToString(),
                "hidePopup(); alert('KPI saved successfully!');", True)

        Catch ex As Exception
            ' Handle any database errors
            System.Diagnostics.Debug.WriteLine("Error saving KPI: " & ex.Message & " StackTrace: " & ex.StackTrace)
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowModalError_" & Guid.NewGuid().ToString(),
                "showPopup(); alert('Error saving KPI: " & ex.Message.Replace("'", "\'") & "');", True)
        End Try
    End Sub

    Private Function CleanInput(text As String) As String
        If String.IsNullOrWhiteSpace(text) Then Return ""
        Return Regex.Replace(text.Trim(), "\s{2,}", " ")
    End Function

    Protected Sub GridView1_RowCommand(sender As Object, e As GridViewCommandEventArgs)
        If e.CommandName = "EditKPI" Then
            Dim index As Integer = Convert.ToInt32(e.CommandArgument)
            LoadEditData(index)
        ElseIf e.CommandName = "DeleteKPI" Then
            Dim index As Integer = Convert.ToInt32(e.CommandArgument)
            DeleteKPI(index)
        End If
    End Sub

    '>>>>Start Of Sorting code <<<<<<<<<<<<<<<<
    ' >>>>>>>>>> START OF SORTING CODE <<<<<<<<<<
    Protected Sub GridView1_Sorting(sender As Object, e As GridViewSortEventArgs)
        ' Get the current sort expression and sort direction from ViewState or set defaults
        Dim sortExpression As String = Nothing
        Dim sortDirection As SortDirection = SortDirection.Ascending ' Default value

        ' Check if ViewState items exist and are not Nothing before casting
        If ViewState("SortExpression") IsNot Nothing Then
            sortExpression = ViewState("SortExpression").ToString()
        End If

        If ViewState("SortDirection") IsNot Nothing Then
            ' Use CType for value types retrieved from ViewState
            sortDirection = CType(ViewState("SortDirection"), SortDirection)
        End If

        ' Determine the new sort direction
        If sortExpression = e.SortExpression Then
            ' If clicking the same column, toggle the direction
            sortDirection = If(sortDirection = SortDirection.Ascending, SortDirection.Descending, SortDirection.Ascending)
        Else
            ' If clicking a new column, default to Ascending
            sortExpression = e.SortExpression
            sortDirection = SortDirection.Ascending
        End If

        ' Store the new sort expression and direction in ViewState
        ViewState("SortExpression") = sortExpression
        ViewState("SortDirection") = sortDirection

        ' Apply sorting by updating SqlDataSource parameters and rebinding directly
        Try
            ' --- Sorting Parameters ---
            ' Set the parameters for the stored procedure (match combined SP parameter names)
            ' The CASE statement in the SP handles mapping the column name
            If SqlDataSource1.SelectParameters("SortColumn") IsNot Nothing Then
                SqlDataSource1.SelectParameters("SortColumn").DefaultValue = sortExpression ' e.g., "KPI Name"
            End If

            Dim sortOrder As String = If(sortDirection = SortDirection.Ascending, "ASC", "DESC")
            If SqlDataSource1.SelectParameters("SortOrder") IsNot Nothing Then
                SqlDataSource1.SelectParameters("SortOrder").DefaultValue = sortOrder
            End If

            ' --- IMPORTANT: Maintain Filter State ---
            ' Ensure the @Status parameter reflects the current filter selection from the HiddenField
            ' This is crucial because sorting might not automatically carry over the filter state.
            Dim currentFilter As String = hfStatusFilter.Value ' Get current filter value from HiddenField

            If SqlDataSource1.SelectParameters("Status") IsNot Nothing Then
                ' Pass the value from the HiddenField to ensure filter is applied during sort
                SqlDataSource1.SelectParameters("Status").DefaultValue = currentFilter
            End If

            ' Rebind the GridView to apply both sorting and filtering
            GridView1.DataBind()

        Catch ex As Exception
            ' Handle potential errors (e.g., invalid sort column names)
            System.Diagnostics.Debug.WriteLine("Sorting Error: " & ex.Message)
            ' Reset parameters to default/no sort if error occurs
            ' Note: Resetting SortColumn/SortOrder to defaults, but keeping the current filter state
            If SqlDataSource1.SelectParameters("SortColumn") IsNot Nothing Then
                SqlDataSource1.SelectParameters("SortColumn").DefaultValue = "KPI or Standalone Metric" ' Match SP default
            End If
            If SqlDataSource1.SelectParameters("SortOrder") IsNot Nothing Then
                SqlDataSource1.SelectParameters("SortOrder").DefaultValue = "ASC" ' Match SP default
            End If
            ' Filter state should remain from hfStatusFilter.Value via ControlParameter or explicit setting above
            GridView1.DataBind()
        End Try
    End Sub
    ' >>>>>>>>>> END OF SORTING CODE <<<<<<<<<<
    ' >>>>>>>>>> END OF SORTING CODE <<<<<<<<<<
    Private Sub DeleteKPI(rowIndex As Integer)
        Dim row As GridViewRow = GridView1.Rows(rowIndex)
        Dim kpiID As String = row.Cells(3).Text.Trim() ' KPI ID is in column index 3

        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString)
                Using cmd As New SqlCommand("DELETE FROM KPITable WHERE [KPI ID] = @KPI_ID", conn)
                    cmd.Parameters.AddWithValue("@KPI_ID", kpiID)
                    conn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using

            ' Refresh GridView
            GridView1.DataBind()
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "DeleteSuccess", "alert('KPI deleted successfully!');", True)

        Catch ex As Exception
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "DeleteError", "alert('Error deleting KPI: " & ex.Message.Replace("'", "\'") & "');", True)
        End Try
    End Sub
    Private Sub LoadEditData(rowIndex As Integer)
        Dim row As GridViewRow = GridView1.Rows(rowIndex)
        Dim kpiId As String = row.Cells(3).Text.Trim()

        hfIsEdit.Value = "true"
        hfKPIID.Value = kpiId
        lblFormTitle.Text = "Edit KPI"
        txtKPIID.Text = kpiId
        txtKPIID.Enabled = True

        Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString)
            conn.Open()
            Using cmd As New SqlCommand("SELECT * FROM KPITable WHERE [KPI ID] = @KPI_ID", conn)
                cmd.Parameters.AddWithValue("@KPI_ID", kpiId)
                Using reader As SqlDataReader = cmd.ExecuteReader()
                    If reader.Read() Then
                        txtMetric.Text = reader("KPI or Standalone Metric").ToString()
                        txtKPIName.Text = reader("KPI Name").ToString()
                        txtShortDesc.Text = reader("KPI Short Description").ToString()
                        txtImpact.Text = reader("KPI Impact").ToString()
                        txtNumerator.Text = reader("Numerator Description").ToString()
                        txtDenom.Text = reader("Denominator Description").ToString()
                        txtUnit.Text = reader("Unit").ToString()
                        txtDatasource.Text = reader("Datasource").ToString()
                        txtOrder.Text = reader("OrderWithinSecton").ToString()
                        txtConstraints.Text = reader("Constraints").ToString()
                        txtSubject_ME_Email.Text = reader("Subject_ME_Email").ToString()
                        chkActive.Checked = reader("Active").ToString().ToUpper() = "Y"
                        chkFlagDivisinal.Checked = reader("FLAG_DIVISINAL").ToString().ToUpper() = "Y"
                        chkFlagVendor.Checked = reader("FLAG_VENDOR").ToString().ToUpper() = "Y"
                        chkFlagEngagement.Checked = reader("FLAG_ENGAGEMENTID").ToString().ToUpper() = "Y"
                        chkFlagContract.Checked = reader("FLAG_CONTRACTID").ToString().ToUpper() = "Y"
                        chkFlagCostcentre.Checked = reader("FLAG_COSTCENTRE").ToString().ToUpper() = "Y"
                        chkFlagDeuballvl4.Checked = reader("FLAG_DEUBALvl4").ToString().ToUpper() = "Y"
                        chkFlagHRID.Checked = reader("FLAG_HRID").ToString().ToUpper() = "Y"
                        chkFlagRequest.Checked = reader("FLAG_REQUESTID").ToString().ToUpper() = "Y"

                    End If
                End Using
            End Using
        End Using

        ' Hide error labels when loading edit data
        lblKPIError.Visible = False
        lblOrderError.Visible = False
        lblDuplicateMetricKPIError.Visible = False

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowModal_" & Guid.NewGuid().ToString(), "showPopup(); hideKPIError();", True)
    End Sub

    Private Sub ClearForm()
        hfIsEdit.Value = "false"
        hfKPIID.Value = ""
        lblFormTitle.Text = "Add KPI"
        txtMetric.Text = ""
        txtKPIName.Text = ""
        txtKPIID.Text = ""
        txtShortDesc.Text = ""
        txtImpact.Text = ""
        txtNumerator.Text = ""
        txtDenom.Text = ""
        txtUnit.Text = ""
        txtDatasource.Text = ""
        txtOrder.Text = ""
        txtConstraints.Text = ""
        txtSubject_ME_Email.Text = ""
        txtKPIID.Enabled = True


        chkActive.Checked = False
        chkFlagDivisinal.Checked = False
        chkFlagVendor.Checked = False
        chkFlagEngagement.Checked = False
        chkFlagContract.Checked = False
        chkFlagCostcentre.Checked = False
        chkFlagDeuballvl4.Checked = False
        chkFlagHRID.Checked = False
        chkFlagRequest.Checked = False


        ' Hide all error labels 
        lblKPIError.Visible = False
        lblOrderError.Visible = False
        lblDuplicateMetricKPIError.Visible = False
    End Sub

    Protected Sub btnAddKPI_Click(sender As Object, e As EventArgs)
        ClearForm()
        lblFormTitle.Text = "Add KPI"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowModal_" & Guid.NewGuid().ToString(), "showPopup(); hideKPIError();", True)
    End Sub


    ' >>>>>>>>>> START OF TOGGLE FILTER CODE Sri Hari 1234567890 <<<<<<<<<<
    ' >>>>>>>>>> START OF FILTERING CODE <<<<<<<<<<
    Protected Sub btnApplyStatusFilter_Click(sender As Object, e As EventArgs)
        ' Get the filter value from the HiddenField
        Dim selectedStatus As String = hfStatusFilter.Value ' Will now be "Y" or "N"

        ' Optional: Log for debugging
        System.Diagnostics.Debug.WriteLine($"Toggle Filter applied: Status='{selectedStatus}'")

        Try
            ' --- Maintain Sorting State ---
            ' Retrieve current sort state from ViewState (set by GridView1_Sorting)
            Dim currentSortExpression As String = TryCast(ViewState("SortExpression"), String)
            Dim currentSortDirection As SortDirection = SortDirection.Ascending
            If ViewState("SortDirection") IsNot Nothing Then
                currentSortDirection = CType(ViewState("SortDirection"), SortDirection)
            End If

            ' Map SortDirection Enum to String expected by stored procedure
            Dim sortDirectionString As String = If(currentSortDirection = SortDirection.Ascending, "ASC", "DESC")

            ' --- Update SqlDataSource Parameters ---
            ' 1. Update the @Status parameter for filtering
            ' Check if the Status parameter exists before setting
            If SqlDataSource1.SelectParameters("Status") IsNot Nothing Then
                SqlDataSource1.SelectParameters("Status").DefaultValue = selectedStatus ' Pass "Y" or "N"
            End If

            ' 2. Update sorting parameters to ensure they are passed correctly
            ' This ensures sorting is maintained when filtering.
            If SqlDataSource1.SelectParameters("SortColumn") IsNot Nothing Then
                ' Use the SortExpression from ViewState
                ' The SP's CASE statement handles mapping this to the actual column name with brackets
                Dim columnForSP As String = If(String.IsNullOrEmpty(currentSortExpression), "KPI or Standalone Metric", currentSortExpression)
                SqlDataSource1.SelectParameters("SortColumn").DefaultValue = columnForSP
            End If

            If SqlDataSource1.SelectParameters("SortOrder") IsNot Nothing Then
                SqlDataSource1.SelectParameters("SortOrder").DefaultValue = sortDirectionString
            End If

            ' --- Rebind the GridView ---
            ' The SqlDataSource will automatically use the updated parameter values
            ' and execute the SelectCommand (dbo.GetAllKPITable) with the new filter/sort.
            GridView1.DataBind()

            System.Diagnostics.Debug.WriteLine($"Toggle Filter processed: Status='{selectedStatus}', SortColumn='{currentSortExpression}', SortDirection='{sortDirectionString}'")

        Catch ex As Exception
            ' Handle potential errors
            System.Diagnostics.Debug.WriteLine("Toggle Filter Error: " & ex.Message)
            ' Optionally, show an error message to the user
            ' You might want to reset the toggle UI or parameters here on error
        End Try
    End Sub
    ' >>>>>>>>>> END OF FILTERING CODE <<<<<<<<<< ' >>>>>>>>>> END OF TOGGLE FILTER CODE <<<<<<<<<<
    ' >>>>>>>>>> START OF SORTING CODE <<<<<<<<<<

    ' >>>>>>>>>> END OF SORTING CODE <<<<<<<<<<

    <WebMethod(EnableSession:=False)>
    <ScriptMethod(ResponseFormat:=ResponseFormat.Json)>
    Public Shared Function CheckKPIExists(kpiID As String) As Boolean
        Try
            ' Clean the input
            If String.IsNullOrWhiteSpace(kpiID) Then
                System.Diagnostics.Debug.WriteLine("CheckKPIExists: Empty or null KPI ID")
                Return False
            End If

            kpiID = kpiID.Trim()
            System.Diagnostics.Debug.WriteLine("CheckKPIExists: Checking KPI ID: " & kpiID)

            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("MyDbConnection").ConnectionString)
                Using cmd As New SqlCommand("SELECT COUNT(*) FROM KPITable WHERE [KPI ID] = @KPI_ID", conn)
                    cmd.Parameters.AddWithValue("@KPI_ID", kpiID)
                    conn.Open()
                    Dim count As Integer = Convert.ToInt32(cmd.ExecuteScalar())
                    System.Diagnostics.Debug.WriteLine("CheckKPIExists: Result for " & kpiID & ": " & (count > 0))
                    Return count > 0
                End Using
            End Using
        Catch ex As Exception
            ' Log detailed error information
            System.Diagnostics.Debug.WriteLine("CheckKPIExists Error: " & ex.Message & " StackTrace: " & ex.StackTrace)
            Return False ' Allow server-side validation to handle
        End Try
    End Function
End Class