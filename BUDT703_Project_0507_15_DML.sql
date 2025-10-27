USE BUDT703_Project_0507_15

--1. 
-- Q:  Which state has demonstrated the lowest average on-time performance across the years, 
-- and how do states rank in terms of their average performance over this three-year period?
SELECT s.stateCode AS 'State Code', stateName AS 'State Name',
    CAST(AVG(CASE WHEN p.performanceYear = 2021 THEN p.onTimePerformance END) AS DECIMAL(3,1)) AS  'Avg On Time Performance 2021',
    CAST(AVG(CASE WHEN p.performanceYear = 2022 THEN p.onTimePerformance END) AS DECIMAL(3,1)) AS 'Avg On Time Performance 2022',
    CAST(AVG(CASE WHEN p.performanceYear = 2023 THEN p.onTimePerformance END) AS DECIMAL(3,1)) AS 'Avg On Time Performance 2023',
    CAST(AVG(AVG(p.onTimePerformance)) OVER (PARTITION BY s.stateName, m.StateCode)  AS DECIMAL(3,1)) AS 'Total Avg On Time Performance'
FROM [OnTrack.State] s
JOIN [OnTrack.Map] m ON s.stateCode = m.stateCode
JOIN [OnTrack.Route] r ON m.routeID = r.routeID
JOIN [OnTrack.Performance] p ON r.routeID = p.routeID 
GROUP BY s.stateName, m.stateCode, s.stateCode
ORDER BY 'Total Avg On Time Performance'


-- 2. 
--Q: How does ridership levels compare to Amtrak Guest Rewards enrollment across states, 
-- and what patterns can be observed in loyalty program participation relative to passenger trends?
SELECT s.stateName AS 'State Name',
    (riders.[2023] + riders.[2022] + riders.[2021]) AS 'Riders Total',
	CAST((riders.[2023] - riders.[2021]) * 100.0 / (riders.[2021]) AS DECIMAL(5,2)) AS 'Riders 21-23 %age',
	 (rewards.[2023] + rewards.[2022] + rewards.[2021]) AS 'Guest Rewards Total',
	CAST((rewards.[2023] - rewards.[2021]) * 100.0 / (rewards.[2021]) AS DECIMAL(5,2)) AS 'Guest Rewards 21-23 %age',
	 (riders.[2023] + riders.[2022] + riders.[2021])/(rewards.[2023] + rewards.[2022] + rewards.[2021]) as 'Rider-to-Reward Ratio'
FROM [OnTrack.Map] m, [OnTrack.Performance] p, [OnTrack.State] s
LEFT JOIN (SELECT c.StateCode,
        SUM(CASE WHEN r.riderYear = 2021 THEN r.ridersTotal END) AS [2021],
        SUM(CASE WHEN r.riderYear = 2022 THEN r.ridersTotal END) AS [2022],
        SUM(CASE WHEN r.riderYear = 2023 THEN r.ridersTotal END) AS [2023]
    FROM [OnTrack.Ridership] r
    JOIN [OnTrack.StationCity] c ON r.stationCityCode = c.stationCityCode
    GROUP BY c.StateCode) riders 
ON s.StateCode = riders.StateCode
LEFT JOIN (SELECT g.StateCode,
        SUM(CASE WHEN g.guestRewardsYear = 2021 THEN g.guestRewardsTotal END) AS [2021],
        SUM(CASE WHEN g.guestRewardsYear = 2022 THEN g.guestRewardsTotal END) AS [2022],
        SUM(CASE WHEN g.guestRewardsYear = 2023 THEN g.guestRewardsTotal END) AS [2023]
    FROM [OnTrack.GuestRewards] g
    GROUP BY  g.StateCode) rewards 
ON s.StateCode = rewards.StateCode
WHERE (rewards.[2021] IS NOT NULL) AND (rewards.[2023] IS NOT NULL) AND (m.routeID = p.routeID) AND (m.stateCode = s.stateCode)
GROUP BY s.stateName, rewards.[2021], rewards.[2022], rewards.[2023], riders.[2021], riders.[2022], riders.[2023], m.stateCode
ORDER BY 'Riders 21-23 %age' DESC, 'Guest Rewards Total' DESC


--3. During the 2022-2023 fiscal year, have states experiencing notable increases in ridership been 
-- allocated proportional increases in their budgetary funding to support this growth?
SELECT s.stateName AS 'State Name',
	(ISNULL(budget.[2022], 0) + ISNULL(budget.[2023], 0)) AS 'Budget Construction Total',
    CAST((riders.[2023] - riders.[2022]) * 100.0 / (riders.[2022]) AS DECIMAL(5,2)) AS 'Riders 22-23 %age'
FROM [OnTrack.State] s
LEFT JOIN (SELECT c.StateCode,
        SUM(CASE WHEN r.riderYear = 2021 THEN r.ridersTotal END) AS [2021],
        SUM(CASE WHEN r.riderYear = 2022 THEN r.ridersTotal END) AS [2022],
        SUM(CASE WHEN r.riderYear = 2023 THEN r.ridersTotal END) AS [2023]
   FROM [OnTrack.Ridership] r
    JOIN [OnTrack.StationCity] c ON r.stationCityCode = c.stationCityCode
    JOIN [OnTrack.Budget] b ON r.stationCityCode = b.stationCityCode
    WHERE b.budgetType = 'Construction' 
    GROUP BY c.StateCode) riders
ON s.StateCode = riders.StateCode
JOIN (SELECT c.stateCode, b.budgetType,
        SUM(CASE WHEN b.budgetYear = 2022 THEN b.budgetAmt ELSE 0 END) AS [2022],
        SUM(CASE WHEN b.budgetYear = 2023 THEN b.budgetAmt ELSE 0 END) AS [2023]
    FROM [OnTrack.Budget] b
	JOIN [OnTrack.StationCity] c ON b.stationCityCode = c.stationCityCode
    GROUP BY c.stateCode, b.budgetType) AS budget
ON s.stateCode = budget.stateCode
WHERE budget.budgetType = 'Construction'
ORDER BY  'Riders 22-23 %age' DESC

--4.
-- Q: What is the impact of employment trends in states characterized by consistently high on-time performance,
-- and what patterns or correlations can be identified?

SELECT s.stateName AS 'State Name',
    (employee.[2022] - employee.[2021]) AS 'Net Employee Count 2021-22', 
	(avgPerformance.[2022] - avgPerformance.[2021]) AS 'Net Avg On Time Performance 2021-22',
	 (employee.[2023] - employee.[2022]) AS 'Net Employee Count 2022-23',
	 (avgPerformance.[2023] - avgPerformance.[2022]) AS 'Net Avg On Time Performance 2022-23'
FROM [OnTrack.State] s
JOIN (SELECT t.stateCode,
        SUM(CASE WHEN e.employmentYear = 2021 THEN e.employeeTotal END) AS [2021],
        SUM(CASE WHEN e.employmentYear = 2022 THEN e.employeeTotal END) AS [2022],
        SUM(CASE WHEN e.employmentYear = 2023 THEN e.employeeTotal END) AS [2023]
    FROM [OnTrack.State] t
    JOIN [OnTrack.Employment] e ON t.stateCode = e.stateCode
    GROUP BY t.stateCode) employee
ON s.stateCode = employee.stateCode
JOIN (SELECT s.stateCode, s.stateName AS 'State Name',
    CAST(AVG(CASE WHEN p.performanceYear = 2021 THEN p.onTimePerformance END) AS DECIMAL(4,2)) AS [2021],
    CAST(AVG(CASE WHEN p.performanceYear = 2022 THEN p.onTimePerformance END) AS DECIMAL(4,2)) AS [2022],
    CAST(AVG(CASE WHEN p.performanceYear = 2023 THEN p.onTimePerformance END) AS DECIMAL(4,2)) AS [2023]
	FROM [OnTrack.State] s
	JOIN [OnTrack.Map] m ON s.stateCode = m.stateCode
	JOIN [OnTrack.Route] r ON m.routeID = r.routeID
	JOIN [OnTrack.Performance] p ON r.routeID = p.routeID 
	GROUP BY s.stateName, m.stateCode, s.stateCode) avgPerformance ON avgPerformance.stateCode = s.stateCode
JOIN [OnTrack.Map] m ON s.stateCode = m.stateCode
JOIN  [OnTrack.Route] r ON r.routeID = m.routeID
JOIN[OnTrack.Performance] p ON r.routeID = p.routeID
GROUP BY s.stateName,  employee.[2021],  employee.[2022],  employee.[2023], avgPerformance.[2023],avgPerformance.[2022], avgPerformance.[2021]
ORDER BY 'Net Employee Count 2021-22'  DESC, 'Net Employee Count 2022-23' DESC





