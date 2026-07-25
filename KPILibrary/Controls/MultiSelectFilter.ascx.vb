Public Class MultiSelectFilter
    Inherits System.Web.UI.UserControl


    Public Property LabelText As String
        Get
            Return lblTitle.Text
        End Get
        Set(value As String)
            lblTitle.Text = value
        End Set
    End Property

    'Public Property IsPeriodFilter As Boolean = False
    Public Property IsReportFromFilter As Boolean = False
    Public Property IsReportToFilter As Boolean = False


    Public Property IsSingleSelect As Boolean = False
    Public Property IsPeriodFilter As Boolean = False

    Public Property CheckBoxListDataSource As DataTable
        Get
            Return DirectCast(ViewState("DS"), DataTable)
        End Get
        Set(value As DataTable)
            ViewState("DS") = value
            BindList()
        End Set
    End Property

    ' Return selected value(s)
    Public ReadOnly Property MultiSelectValue As String
        Get
            Dim selected = CheckBoxList.Items.Cast(Of ListItem).
                           Where(Function(i) i.Selected).
                           Select(Function(i) i.Text)

            Return String.Join(",", selected)
        End Get
    End Property


    Private Sub BindList()
        If CheckBoxListDataSource Is Nothing Then Exit Sub

        CheckBoxList.DataSource = CheckBoxListDataSource
        CheckBoxList.DataTextField = CheckBoxListDataSource.Columns(0).ColumnName
        CheckBoxList.DataValueField = CheckBoxListDataSource.Columns(0).ColumnName
        CheckBoxList.DataBind()

        txtSelected.Text = ""
    End Sub


    Protected Sub CheckBoxList_SelectedIndexChanged(sender As Object, e As EventArgs) Handles CheckBoxList.SelectedIndexChanged

        'If this is the Period filter, auto-fill From/To
        If IsPeriodFilter Then
            AutoFillQuarterDates()
        End If

        UpdateSelectedText()



        If IsSingleSelect Then
            ' Uncheck all other items
            For Each item As ListItem In CheckBoxList.Items
                If item IsNot CheckBoxList.SelectedItem Then
                    item.Selected = False
                End If
            Next
        End If

    End Sub

    Private Sub AutoFillQuarterDates()
        If CheckBoxList.SelectedItem Is Nothing Then Exit Sub




        Dim selectedQuarter As String = CheckBoxList.SelectedItem.Text

        System.Diagnostics.Debug.WriteLine("AutoFillQuarterDates HIT → Selected: " & selectedQuarter)

        Dim parent As FilterBoxControl =
        CType(Me.NamingContainer.NamingContainer, FilterBoxControl)

        Dim dt As DataTable = parent.GetQuarterDates(selectedQuarter)

        If dt.Rows.Count > 0 Then
            Dim dates = dt.AsEnumerable().Select(Function(r) CDate(r("ReportDate")))

            Dim fDate As String = dates.Min().ToString("dd-MM-yyyy")
            Dim tDate As String = dates.Max().ToString("dd-MM-yyyy")

            parent.SetReportFrom(fDate)
            parent.SetReportTo(tDate)
        End If
    End Sub

    Public ReadOnly Property SelectedTextValue As String
        Get
            Try
                ' Try to find the actual inner textbox control that renders the display text.
                ' Adjust inner control IDs if your control uses different IDs.
                Dim tb As TextBox = TryCast(FindControl("ListView_TextBox"), TextBox)
                If tb IsNot Nothing Then
                    Return tb.Text
                End If

                ' If not found, try to locate by common naming pattern
                Dim ctl = FindControl("ListView")
                If ctl IsNot Nothing Then
                    tb = TryCast(ctl.FindControl("TextBox"), TextBox)
                    If tb IsNot Nothing Then Return tb.Text
                End If

                ' Fallback to Request.Form using the control unique id + known suffix
                Dim formKey = Me.UniqueID & "_ListView_TextBox"
                Dim posted = HttpContext.Current.Request.Form(formKey)
                If Not String.IsNullOrEmpty(posted) Then Return posted.ToString()

            Catch ex As Exception
                ' swallow/log if needed
            End Try

            Return String.Empty
        End Get
    End Property


    Public Sub UpdateSelectedText()
        Dim selectedItems = CheckBoxList.Items.Cast(Of ListItem)().
                        Where(Function(i) i.Selected).
                        Select(Function(i) i.Text)

        txtSelected.Text = String.Join(",", selectedItems)
    End Sub




    Public Event BubbleEvent(sender As Object, e As EventArgs)

    Protected Sub btnToggle_Click(sender As Object, e As EventArgs) Handles btnToggle.Click
        pnlList.Visible = Not pnlList.Visible
    End Sub

    ' Allows parent to set the selected text
    Public WriteOnly Property SelectedText As String
        Set(value As String)
            txtSelected.Text = value
        End Set
    End Property



End Class