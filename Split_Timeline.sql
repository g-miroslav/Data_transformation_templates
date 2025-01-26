WITH ShiftBoundaries_CTE as (
SELECT
    ROW_NUMBER() OVER (ORDER BY DEVICE_ID, tStart) as ID 
    , DEVICE_ID
    , STATUS_ID
    , tStart
    , tEnd
    , CASE
        WHEN CAST(tStart as time) >= '06:00' AND CAST(tStart as time) < '14:00' THEN DATEADD(hour, 6, CAST(CAST(tStart as date) as datetime))
        WHEN CAST(tStart as time) >= '14:00' AND CAST(tStart as time) < '22:00' THEN DATEADD(hour, 14, CAST(CAST(tStart as date) as datetime))
        WHEN CAST(tStart as time) >= '22:00' THEN DATEADD(hour, 22, CAST(CAST(tStart as date) as datetime))
        WHEN CAST(tStart as time) < '06:00' THEN DATEADD(hour, 22, CAST(CAST(tStart - 1 as date) as datetime))
    END as TotalShiftStart
    , CASE
        WHEN CAST(tEnd as time) >= '06:00' AND CAST(tEnd as time) < '14:00' THEN DATEADD(hour, 14, CAST(CAST(tEnd as date) as datetime))
        WHEN CAST(tEnd as time) >= '14:00' AND CAST(tEnd as time) < '22:00' THEN DATEADD(hour, 22, CAST(CAST(tEnd as date) as datetime))
        WHEN CAST(tEnd as time) >= '22:00' THEN DATEADD(hour, 6, CAST(CAST(tEnd + 1 as date) as datetime))
        WHEN CAST(tEnd as time) < '06:00' THEN DATEADD(hour, 6, CAST(CAST(tEnd as date) as datetime))
    END as TotalShiftEnd
FROM 
	Timeline
)

, Recursive_CTE as (
SELECT
    *
    , TotalShiftStart as ShiftStart
FROM 
    ShiftBoundaries_CTE
UNION ALL
SELECT
    t.ID
    , t.DEVICE_ID
    , t.STATUS_ID
    , t.tStart
    , t.tEnd
    , t.TotalShiftStart
    , t.TotalShiftEnd
    , DATEADD(hour, 8, Recursive_CTE.ShiftStart) as ShiftStart
FROM 
    ShiftBoundaries_CTE as t 
    INNER JOIN Recursive_CTE
        ON t.ID = Recursive_CTE.ID
WHERE
     DATEADD(hour, 8, Recursive_CTE.ShiftStart) < t.TotalShiftEnd
)

, EventStartEnd_CTE as (
SELECT 
    *
    , CASE WHEN tStart > ShiftStart THEN tStart ELSE ShiftStart END as [Start]
    , CASE WHEN tEnd < DATEADD(hour, 8, ShiftStart) THEN tEnd ELSE DATEADD(hour, 8, ShiftStart) END as [End]
FROM
    Recursive_CTE
)

SELECT
    DEVICE_ID
    , STATUS_ID
    , tStart
    , tEnd
    , TotalShiftStart
    , TotalShiftEnd
    , ShiftStart
    , DATEADD(hour, 8, ShiftStart) as ShiftEnd
    , [Start]
    , [End]
    , DATEDIFF(second, [Start], [End])/60.0/60.0 as Duration
    , CAST(ShiftStart as date) as [Date]
    , CASE
        WHEN CAST(ShiftStart as time) = '06:00' THEN 1
        WHEN CAST(ShiftStart as time) = '14:00' THEN 2
        WHEN CAST(ShiftStart as time) = '22:00' THEN 3
    END as [Shift]
FROM
    EventStartEnd_CTE;
