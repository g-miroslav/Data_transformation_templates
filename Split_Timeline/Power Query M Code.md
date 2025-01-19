## Power Query M Code

#### 1. Load Data
```m
let
    Source = #"Device Status (Raw Data)",
```
#### 2. Add Total Shift Start
Identify the start of the first shift associated with this event.
```m
#"Added TotalShiftStart" = Table.AddColumn(Source, "TotalShiftStart", each 
    let result =
        if varStartTime >= #time(6, 0, 0) and varStartTime <#time(14, 0, 0) then #duration(0, 6, 0, 0)
        else if varStartTime >= #time(14, 0, 0) and varStartTime < #time(22, 0, 0) then #duration(0, 14, 0, 0)
        else if varStartTime >= #time(22, 0, 0) then #duration (0, 22, 0, 0)
        else if varStartTime < #time(6, 0, 0) then #duration(0, 22, 0, 0) - #duration(1, 0, 0, 0)
        else "error",

        varStartTime = DateTime.Time([tStart])

        in DateTime.From(Date.From([tStart])) + result, type datetime
    ),
```
#### 3. Add Total Shift End
Identify the end of the last shift associated with this event.
```m
#"Added TotalShiftEnd" = Table.AddColumn(#"Added TotalShiftStart", "TotalShiftEnd", each 
    let result =
        if varEndTime >= #time(6, 0, 0) and varEndTime < #time(14, 0, 0) then #duration(0, 14, 0, 0)
        else if varEndTime >= #time(14, 0, 0) and varEndTime < #time(22, 0, 0) then #duration(0, 22, 0, 0)
        else if varEndTime >= #time(22, 0, 0) then #duration(1, 6, 0, 0)
        else if varEndTime < #time(6, 0, 0) then #duration(0, 6, 0, 0)
        else "error",

        varEndTime = DateTime.Time([tEnd])

        in DateTime.From(Date.From([tEnd])) + result, type datetime
    ),
```
#### 4. Split Data into 3 shifts
This step creates a list for each row.
##### List.DateTimes syntax:
```
List.DateTimes(start as datetime, count as number, step as duration) as list
```
```m
#"Added ShiftStart" = Table.AddColumn(#"Added TotalShiftEnd", "ShiftStart", each 
        List.DateTimes(
            [TotalShiftStart],
            Duration.TotalHours([TotalShiftEnd]-[TotalShiftStart])/8,
            #duration(0, 8, 0, 0)
        )
    ),
```
#### 5. Expand the lists into rows & change to datetime
```m
#"Expanded ShiftStart" = Table.ExpandListColumn(#"Added ShiftStart", "ShiftStart"),
#"Changed ShiftStart Type" = Table.TransformColumnTypes(#"Expanded ShiftStart",{{"ShiftStart", type datetime}}),
```
#### 6. Add Shift End
```m
#"Added ShiftEnd" = Table.AddColumn(#"Changed ShiftStart Type", "ShiftEnd", each
        [ShiftStart] + #duration(0, 8, 0, 0), type datetime
    ),
```
#### 7. Add Start and End
```m
#"Added Start" = Table.AddColumn(#"Added ShiftEnd", "Start", each List.Max({[tStart], [ShiftStart]}), type datetime),
#"Added End" = Table.AddColumn(#"Added Start", "End", each List.Min({[tEnd], [ShiftEnd]}), type datetime),
```
#### 8. Calculate Duration
```m
#"Added Duration" = Table.AddColumn(#"Added End", "Duration", each Duration.TotalHours([End] - [Start]), type number),
```
#### 8. Add Date
Since each starts at 6am, a date column is created from the ShiftStart column. This can be linked to a Calendar table.
```m
#"Inserted Date" = Table.AddColumn(#"Added Duration", "Date", each DateTime.Date([ShiftStart]), type date),
```
#### 9. Add Shift Number
```m
#"Added ShiftNumber" = Table.AddColumn(#"Inserted Date", "ShiftNumber", each 
    let result =
        if varShiftStart = #time(6, 0, 0) then 1
        else if varShiftStart = #time(14, 0, 0) then 2
        else if varShiftStart = #time(22, 0, 0) then 3
        else "error",

        varShiftStart = DateTime.Time([ShiftStart])

        in result, Int64.Type
    )
```
#### 10. End of M code
```
in
    #"Added ShiftNumber"
```
### Credits
**Antti Suanto** - `as Timeline` 1.5.1 custom visual for Power BI
