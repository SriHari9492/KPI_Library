
KPI Library – Release Document
Project: KPI Library Management System
Module: KPI Management
Release Version: v3.0
Release Date: 13-Aug-2025
Prepared By: Sri Harinatha Reddy

Release Summary
This release introduces two new fields in the KPI Management module:

Dropdown – "Subjective & Objective" (Subj_Obj)

**Text Area – "Comment"** (Comment`)

Changes include database table updates, modifications to stored procedures for insertion, updating, and retrieval, as well as front-end changes in ASPX to support new input fields. Backend VB code was updated to handle new parameters and ensure proper data binding. These additions enhance the KPI Library’s ability to capture qualitative assessments and related remarks for each KPI.

1. Overview
The KPI Library now supports capturing and managing two additional pieces of information for each KPI record: a subjective/objective classification via dropdown selection, and free-text comments.
This feature enhances tracking, classification, and qualitative reporting capabilities.

2. Scope of Changes
Included:

Addition of new database columns: [Subj_Obj] and [Comment] in KPITable.

Updates to stored procedures:

InsertKPI

UpdateKPIByID

GetAllKPITable

Backend VB code changes to handle new fields.

Frontend ASPX UI changes to add dropdown control and comment input field.

Not Included:

No changes to KPI calculation logic.

No changes to reporting or dashboard modules at this stage.

3. Change Details
Area	Type	Description
Database – Table	Schema Update	Added [Subj_Obj] NVARCHAR(50) and [Comment] NVARCHAR(MAX) columns to KPITable.
Database – Stored Procedures	Insert	Modified InsertKPI to accept and insert @Subj_Obj and @Comment.
Database – Stored Procedures	Update	Modified UpdateKPIByID to update @Subj_Obj and @Comment values.
Database – Stored Procedures	Get	Modified GetAllKPITable to include [Subj_Obj] and [Comment] in the SELECT list.
Backend (VB)	Data Handling	Added parameters for Subj_Obj and Comment in insert/update logic. Bound data to dropdown and text area in edit mode.
Frontend (ASPX)	UI Update	Added dropdown control for "Subjective & Objective" with predefined options. Added textarea for "Comment" input.

4. Implementation Steps
Database Changes
Altered KPITable:

sql
Copy
Edit
ALTER TABLE KPITable
ADD [Subj_Obj] NVARCHAR(50), [Comment] NVARCHAR(MAX);
Updated InsertKPI stored procedure to include @Subj_Obj and @Comment.

Updated UpdateKPIByID stored procedure to include @Subj_Obj and @Comment.

Updated GetAllKPITable stored procedure to include [Subj_Obj] and [Comment] in SELECT.

Backend Code Changes (VB)
Added code to capture Subj_Obj dropdown selected value.

Added code to capture Comment text input value.

Passed these values as parameters to the stored procedure calls.

UI Changes (ASPX)
Added dropdown for "Subjective & Objective" with options:

Subjective

Objective

Added multiline textbox/textarea for "Comment".

5. Testing
Unit Testing: Insert, update, and fetch KPI records with Subj_Obj and Comment.

UI Testing: Verified dropdown selection persists on edit and displays correctly.

Integration Testing: Confirmed stored procedures receive and store correct values.

6. Impact Analysis
Positive:

Enhanced KPI classification and documentation.

Allows qualitative data storage alongside quantitative metrics.

Neutral:

Minor increase in table storage usage.

Negative:

None identified.

7. Rollback Plan
If rollback is required:

Drop the [Subj_Obj] and [Comment] columns from KPITable.

Restore previous versions of stored procedures.

Revert ASPX and VB files to pre-change versions.

8. Attachments
Before vs After SQL Scripts for table and stored procedure changes.

Before vs After VB Code for parameter handling and binding.

UI screenshots showing new fields in create and edit modes
