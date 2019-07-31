SELECT	Categories.Category AS 'JCR Category', --This is the level of analysis that we'll group by here
		COUNT(m.ISSN) AS 'Overlap Count',		-- Because JCR Journals without an ISSN match will be blank, we can count ISSNs for a count of JCR Journals present in local holdings
		COUNT(Journals.[Journal Title]) as 'JCR journals Count',	-- Count all of the JCR journals in this category
		CONVERT(VARCHAR(10),CAST(ROUND(COUNT(m.ISSN) * 100.0 / COUNT(Journals.[Journal Title]), 2,1) AS decimal(5,2))) + '%' AS 'Overlap Rate',
		SUM(m.[Total Cites]) as 'Total Cites',		-- The sum total of all citations for the JCR journals in this category
		ROUND(AVG(m.[Normalized Eigenfactor]), 3) as 'Average Eigenfactor score',			-- The average Eigenfactor score for JCR Journals in this category, in local holdings
		ROUND(AVG(m.[Journal Impact Factor]), 3) as 'Average Impact Factor in Holdings',	-- The average impact factor for JCR Journals in this category, in local holdings
		AVG(Categories.[Aggregate Impact Factor]) as 'JCR Holdings Aggregate Impact Factor' -- The average impact factor of all JCR Journals in this category

--This is where we construct the collated virtual table that we'll select from in the future
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

GROUP BY Categories.Category

