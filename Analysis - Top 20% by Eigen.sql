Select	mp.[JCR Category],
		COUNT([ISSN Match]) as 'JCR Top Quintile Overlap Count in Holdings',
		count([Journal Title]) as 'JCR Top Quintile Total Count',
		CONVERT(VARCHAR(10),CAST(ROUND(COUNT([ISSN Match]) * 100.0 / count([Journal Title]), 2,1) AS decimal(5,2))) + '%' AS 'Top 20% Overlap Rate',
		SUM([JCt]) as 'Total Cites',
		ROUND(AVG([Normalized Eigenfactor]), 3) as 'Average Eigenfactor score'
FROM
(
	SELECT	*,
				-- seqnum is inducing an ordered row ranking that we can use to delimit upper/lower percentiles of our selected data, while cnt is a total count of rows.
				-- At the bottom of this query, we just select where seqnum <= cnt/5, which returns any rows ranked higher than the first quintile.
				-- For the top quartile, we would select based on "seqnum <= cnt/4", or 
				-- for the top decile, we'd use "seqnum <= cnt/10". The same pattern extends to selecting the bottom n-tile.
			row_number() over (partition by [JCR Category] order by [JCR Category],[Normalized Eigenfactor] DESC) as seqnum,
			count([Journal Title]) over (partition by [JCR Category]) as cnt
	From
	(
		SELECT	Categories.Category AS 'JCR Category',
				Journals.[Journal Title],
				m.ISSN as 'ISSN Match',
				Journals.[Total Cites] as 'JCt',
				Journals.[Article Influence Score],
				Journals.[Journal Impact Factor],
				Categories.[Aggregate Immediacy Index],
				Categories.[Aggregate Impact Factor],
				Categories.[# Journals] AS 'JCR Category Journal Count',
				Categories.[Articles] AS 'JCR Category Article Count',
				Categories.[Median Impact Factor],
				Journals.[Normalized Eigenfactor]
		FROM
		(
			Select DISTINCT Journals.[Journal Title], Journals.ISSN, Journals.JournID, Journals.[Article Influence Score] ,Journals.[Total Cites],Journals.[Journal Impact Factor], Journals.[Normalized Eigenfactor]
			FROM JCR.dbo.Journals
			INNER JOIN EJournals.dbo.EJournals
				ON EJournals.dbo.EJournals.ISSN = Journals.ISSN
			UNION
			Select DISTINCT Journals.[Journal Title], Journals.ISSN, Journals.JournID, Journals.[Article Influence Score] ,Journals.[Total Cites],Journals.[Journal Impact Factor], Journals.[Normalized Eigenfactor]
			FROM JCR.dbo.Journals
			INNER JOIN EJournals.dbo.EJournals
				ON EJournals.dbo.EJournals.eISSN = Journals.ISSN
			WHERE EJournals.dbo.EJournals.eISSN <> EJournals.dbo.EJournals.ISSN
		) m
		RIGHT JOIN	Journals			ON Journals.ISSN = m.ISSN
		LEFT JOIN	categories_journals ON Journals.JournID = categories_journals.Journ_ID
		LEFT JOIN	Categories			ON categories_journals.Cat_ID = Categories.CatID
	) mt
) mp
WHERE seqnum <= 0.2*cnt
GROUP BY [JCR Category]
ORDER BY [JCR Category]
