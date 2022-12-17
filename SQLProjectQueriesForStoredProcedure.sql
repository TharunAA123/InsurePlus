-- Step 1
-- Query 1
/*
SELECT ClaimantID, ReopenedDate FROM Claimant;

-- Query 2
SELECT PK, MAX(EntryDate) AS LatestAssigningDate FROM ClaimLog WHERE FieldName = 'ExaminerCode' GROUP BY PK;

-- Query 3
SELECT ClaimNumber, MAX(EnteredOn) AS LatestPublishDate FROM ReservingTool WHERE IsPublished = 1 GROUP BY ClaimNumber;
*/


-- Step 6
CREATE PROCEDURE SPGetOutstandingRTPublish (
@DaysToComplete AS INT = NULL,
@DaysOverdue AS INT = NULL,
@Office AS VARCHAR(31) = NULL,
@ManagerCode AS VARCHAR(31) = NULL,
@SupervisorCode AS VARCHAR(31) = NULL,
@ExaminerCode AS VARCHAR(31) = NULL,
@Team AS VARCHAR(250) = NULL,
@ClaimsWithoutRTPublish AS BIT = 0
)
AS
BEGIN
    -- Step 4
    DECLARE @DateAsOf DATE
    SET @DateAsOf = '1/1/2019'

    DECLARE @ReservingToolPbl TABLE
    (
        ClaimNumber VARCHAR(30),
        LastPublishedDate DATETIME
    )

    DECLARE @AssignedDateLog TABLE
    (
        PK INT,
        ExaminerAssignedDate DATETIME
    )
     -- Step 5
        INSERT INTO @ReservingToolPbl
        SELECT ClaimNumber, MAX(EnteredOn) AS LatestPublishDate FROM ReservingTool WHERE IsPublished = 1 GROUP BY ClaimNumber;

        INSERT INTO @AssignedDateLog
        SELECT PK, MAX(EntryDate) AS LatestAssigningDate FROM ClaimLog WHERE FieldName = 'ExaminerCode' GROUP BY PK;

        -- SELECT * FROM @ReservingToolPbl
        -- SELECT * FROM @AssignedDateLog

    SELECT *
    FROM
    (
        -- Step 3
        SELECT ClaimNumber,
            ManagerCode,
            ManagerTitle,
            ManagerName,
            SupervisorCode,
            SupervisorTitle,
            SupervisorName,
            ExaminerCode,
            ExaminerTitle,
            ExaminerName,
            Office,
            ClaimStatusDesc,
            ClaimantName,
            ClaimantTypeDesc,
            ExaminerAssignedDate,
            ReopenedDate,
            AdjustedAssignedDate,
            LastPublishedDate,
            DaysSinceAdjustedAssignDate,
            DaysSinceLastPublishedDate,
            CASE WHEN DaysSinceAdjustedAssignDate > 14 AND (DaysSinceLastPublishedDate >90 OR DaysSincelastPublishedDate IS NULL) THEN 0
                WHEN 91 - DaysSinceLastPublishedDate >= 15 - DaysSinceAdjustedAssignDate AND DaysSinceLastPublishedDate IS NOT NULL
                    THEN 91 - DaysSinceLastPublishedDate
                ELSE 15 - DaysSinceAdjustedAssignDate
            END AS DaysToComplete,

            CASE WHEN DaysSinceAdjustedAssignDate <= 14 AND (DaysSinceLastPublishedDate <=90 OR DaysSincelastPublishedDate IS NOT NULL) THEN 0
                WHEN DaysSinceLastPublishedDate - 90 <= DaysSinceAdjustedAssignDate - 14 AND DaysSinceLastPublishedDate IS NOT NULL
                    THEN DaysSinceLastPublishedDate - 90
                ELSE DaysSinceAdjustedAssignDate - 14
            END AS DaysOverdue
        FROM
        (
            -- Step 2
            SELECT 
                C.ClaimNumber,
                R.ReserveAmount,
                CASE 
                    WHEN RT.ParentID IN (1,2,3,4,5) THEN RT.ParentID
                    ELSE RT.reserveTypeID
                    END AS ReserveTypeBucketID,
                O.OfficeDesc AS Office,
                U.Username AS ExaminerCode,
                Users2.UserName AS SupervisorCode,
                Users3.UserName AS ManagerCode,
                U.Title AS ExaminerTitle,
                Users2.Title AS SupervisorTitle,
                Users3.Title AS ManagerTitle,
                U.LastFirstName AS ExaminerName,
                Users2.LastFirstName AS SupervisorName,
                Users3.LastFirstName AS ManagerName,
                CS.ClaimStatusDesc,
                P.LastName + ', ' + TRIM(P.FirstName + ' ' + P.MiddleName) AS ClaimantName,
                CL.ReopenedDate,
                CT.ClaimantTypeDesc,
                O.State,
                U.ReserveLimit,
                ADL.ExaminerAssignedDate,
                CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN CL.ReopenedDate
                    ELSE ADL.ExaminerAssignedDate
                    END AS AdjustedAssignedDate,
                CASE WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN DATEDIFF(DAY, ReopenedDate, @DateAsOf)
                    ELSE DATEDIFF(DAY, ExaminerAssignedDate, @DateAsOf)
                    END AS DaysSinceAdjustedAssignDate,
                RTP.LastPublishedDate,
                DATEDIFF(DAY, LastPublishedDate, @DateAsOf) AS DaysSinceLastPublishedDate
                
            FROM Claimant CL
            INNER JOIN Claim C ON C.ClaimID = CL.ClaimID
            INNER JOIN Users U ON U.UserName = C.ExaminerCode
            INNER JOIN Users Users2 ON U.Supervisor = Users2.UserName
            INNER JOIN Users Users3 ON Users2.Supervisor = Users3.UserName
            INNER JOIN Office O ON U.OFficeID = O.OfficeID
            INNER JOIN ClaimantType CT ON CT.ClaimantTypeID = CL.ClaimantTypeID
            INNER JOIN Reserve R ON R.ClaimantID = CL.ClaimantID
            INNER JOIN ClaimStatus CS ON CS.ClaimStatusID = CL.claimStatusID
            INNER JOIN ReserveType RT ON RT.reserveTypeID = R.ReserveTypeID
            INNER JOIN Patient P ON P.PatientID = CL.PatientID
            INNER JOIN @AssignedDateLog ADL ON C.ClaimID = ADL.PK
            LEFT JOIN @ReservingToolpbl RTP ON C.ClaimNumber = RTP.ClaimNumber
            WHERE (RT.ParentID IN (1, 2, 3, 4, 5) or RT.reserveTypeID IN (1, 2, 3, 4, 5))
            AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID <> 3 ))
        )BaseData
        PIVOT
        (
            SUM(ReserveAmount)
                FOR ReserveTypeBucketID IN ([1], [2], [3], [4], [5])
        )PivotTable
    )MainQuery
 WHERE (@DaysToComplete IS NULL OR DaysToComplete <=@DaysToComplete)
    AND (@DaysOverdue IS NULL OR DaysOverdue <=@DaysOverdue)
    AND (@Office IS NULL OR Office =@Office)
    AND (@ManagerCode IS NULL OR ManagerCode =@ManagerCode)
    AND (@ExaminerCode IS NULL OR ExaminerCode =@ExaminerCode)
    AND (@Team IS NULL OR ExaminerTitle LIKE '%' + @Team + '%'
        OR SupervisorTitle LIKE '%' + @Team + '%'
        OR ManagerTitle LIKE '%' + @Team + '%' )
    AND (@ClaimsWithoutRTPublish = 0 OR LastPublishedDate IS NULL)
    

END

SPGetOutstandingRTPublish