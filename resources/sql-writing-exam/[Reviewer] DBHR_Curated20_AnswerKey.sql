/*

[README]

This file contains the answer key for the 20 questions in DBHR_Curated20.sql. The focus is on providing 
correct SQL queries that rely on subqueries, along with explanations on how and why subqueries are used.

FAQs

1. Why does ordering by employee name appear in several answers?

		For consistency and information requirements, the answers involving employee data are ordered by 
    employee name unless otherwise specified.

2. What are common mistakes when using joins?

		One of the most common issues is not specifying the correct join type, which may lead to missing data 
    (e.g., using INNER JOIN when LEFT JOIN is needed).

3. How can small mistakes affect aggregate functions?

		Failing to group by non-aggregated columns or using the wrong column in an aggregate function can 
    drastically change the output. Always ensure that non-aggregated columns are correctly included 
    in your GROUP BY clause.
    
4. How do invalid or null values affect query results?

		Queries may return fewer rows if NULL values are not handled properly in filtering conditions. 
    For example, NULL values require special handling using IS NULL.

5. How do I improve my skills with subqueries?

		Practice writing subqueries in different contexts. Try using them for filtering (WHERE), generating 
    derived tables (FROM), and calculating values (SELECT).
    
6. What are common mistakes when using subqueries?

		Not understanding how subqueries are evaluated in different contexts (e.g., WHERE vs. FROM). For 
    instance, a subquery in the WHERE clause must return a single value when using comparison 
    operators like =, while subqueries in the FROM clause can return a full dataset.
*/

-- You can run these queries to see all of the data stored within the database.

SELECT * FROM countries;
SELECT * FROM departments;
SELECT * FROM employees;
SELECT * FROM job_history;
SELECT * FROM jobs;
SELECT * FROM locations;
SELECT * FROM regions;

-- The DESCRIBE keyword shows the structure of the table. You can run these queries to get all 
-- of the information of each field in the table.

DESCRIBE countries;
DESCRIBE departments;
DESCRIBE employees;
DESCRIBE job_history;
DESCRIBE jobs;
DESCRIBE locations;
DESCRIBE regions;

-- Question 22: Returns 11 row(s)
-- Retrieve all employees where the hire date is within 2 days (inclusive) after their manager's 
-- hire date. Return the full name and hire date of both employee and their manager.

SELECT
	CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name`
, e1.HIRE_DATE
, CONCAT(e2.LAST_NAME, ', ', e2.FIRST_NAME) AS `Manager Name`
, e2.HIRE_DATE
FROM
	employees e1
		JOIN	employees e2
			ON	e1.MANAGER_ID = e2.EMPLOYEE_ID
WHERE
	TIMESTAMPDIFF(DAY, e2.HIRE_DATE, e1.HIRE_DATE) <= 2
ORDER BY
	e2.LAST_NAME
, e2.FIRST_NAME
, e1.LAST_NAME
, e1.FIRST_NAME;

/*
	The date difference can ALSO be written as: (NOTE THE ORDER OF HIRE_DATES COMPARED)
  
		TIMESTAMPDIFF(DAY, e2.HIRE_DATE, e1.HIRE_DATE) BETWEEN 0 AND 2
		TIMESTAMPDIFF(DAY, e2.HIRE_DATE, e1.HIRE_DATE) <= 2
		DATEDIFF(e1.HIRE_DATE, e2.HIRE_DATE) BETWEEN 0 AND 2
		DATEDIFF(e1.HIRE_DATE, e2.HIRE_DATE) <= 2
*/

-- Question 24: Returns 27 row(s)
-- Find the total salary for each department ordered by the total. Include departments with a 
-- total salary of zero.

-- Query 1: Without using CASE expressions

SELECT
	de.DEPARTMENT_NAME
, SUM(em.SALARY) AS `Total Salary`
FROM
	departments de
		LEFT JOIN	employees em
			ON	de.DEPARTMENT_ID = em.DEPARTMENT_ID
GROUP BY
	de.DEPARTMENT_NAME
ORDER BY
	`Total Salary` DESC;

-- Query 2: Using CASE expressions

SELECT
	de.DEPARTMENT_NAME
, CASE
		WHEN 	SUM(em.SALARY) IS NULL
    THEN 	0
    
    ELSE	SUM(em.SALARY)
	END AS `Total Salary`
FROM
	departments de
		LEFT JOIN	employees em
			ON	de.DEPARTMENT_ID = em.DEPARTMENT_ID
GROUP BY
	de.DEPARTMENT_NAME
ORDER BY
	`Total Salary` DESC;

-- Question 27: Returns 4 row(s)
-- Find the full name of all employees who have the same job title as their manager. Include 
-- the full name of their manager.

SELECT
	CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name`
, CONCAT(e2.LAST_NAME, ', ', e2.FIRST_NAME) AS `Manager Name`
FROM
	employees e1
		JOIN	employees e2
			ON	e1.MANAGER_ID = e2.EMPLOYEE_ID
WHERE
	e1.JOB_ID = e2.JOB_ID
ORDER BY
	e1.LAST_NAME
, e1.FIRST_NAME;

-- Question 31: Returns 31 row(s)
-- Retrieve the full names of employees who were hired within the last 30 days (inclusive) of the 
-- most recent hire date.

-- Query 1: Normal subquery (but called on every record)

SELECT
	CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
, em.HIRE_DATE
FROM
	employees em
WHERE
	DATEDIFF(
		(	SELECT 
				MAX(e1.HIRE_DATE) 
			FROM employees e1
		), em.HIRE_DATE
	) <= 30
ORDER BY
	em.LAST_NAME
, em.FIRST_NAME;

-- Query 2: Optimized subquery to be called only once using a CTE and CROSS JOIN (credits: ChatGPT)

WITH 
	max_hire AS (
    SELECT 
			MAX(em.HIRE_DATE) AS max_date 
		FROM 
			employees em
	)

SELECT
	CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
, em.HIRE_DATE
FROM 
	employees em
		CROSS JOIN 
			max_hire
WHERE 
	DATEDIFF(max_hire.max_date, em.HIRE_DATE) <= 30
ORDER BY 
	em.LAST_NAME
, em.FIRST_NAME;

-- Question 32: Returns 11 row(s)
-- Find the full name of all employees, their salary, and their department ID whose salary is 
-- within 10% of the highest salary in their department ordered decreasingly by their salary.

SELECT
	CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
, em.SALARY
, em.DEPARTMENT_ID
FROM
	employees em
WHERE
	em.SALARY >= (
		SELECT
			MAX(e1.SALARY)
		FROM
			employees e1
		WHERE
			em.DEPARTMENT_ID = e1.DEPARTMENT_ID
  ) * 0.9
  AND EXISTS (
		SELECT
			1
		FROM
			employees e1
		WHERE
			em.EMPLOYEE_ID <> e1.EMPLOYEE_ID
			AND em.DEPARTMENT_ID = e1.DEPARTMENT_ID   
  )
ORDER BY
	em.SALARY DESC;

-- Question 34: Returns 1 row(s)
-- Retrieve the full name of all employees where at least 1 field in the department's location is 
-- empty (different from NULL or INVALID).

SELECT
	CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
FROM 
	employees em
		JOIN	departments de
			ON	em.DEPARTMENT_ID = de.DEPARTMENT_ID
		JOIN	locations lo
			ON	de.LOCATION_ID = lo.LOCATION_ID
WHERE
	lo.STREET_ADDRESS = ''
	OR lo.POSTAL_CODE = ''
  OR lo.CITY = ''
  OR lo.STATE_PROVINCE = ''
ORDER BY
	em.LAST_NAME
, em.FIRST_NAME;

/*
	The WHERE clause can be written using the TRIM function, which would take into account records
  whose data includes multiple empty spaces (e.g. '      ') instead of just ' '.
  
		TRIM(lo.STREET_ADDRESS) = ''
		OR TRIM(lo.POSTAL_CODE) = ''
		OR TRIM(lo.CITY) = ''
		OR TRIM(lo.STATE_PROVINCE) = ''
*/

-- Question 37: Returns 9 row(s)
-- Retrieve the names of the employees who have the second highest salary in each department 
-- and their department name.

SELECT
	CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
, de.DEPARTMENT_NAME
FROM
	employees em
		JOIN 	departments de
			ON	em.DEPARTMENT_ID = de.DEPARTMENT_ID
WHERE
	(
		SELECT
			COUNT(DISTINCT e1.SALARY)
		FROM
			employees e1
		WHERE
			em.EMPLOYEE_ID <> e1.EMPLOYEE_ID
      AND em.DEPARTMENT_ID = e1.DEPARTMENT_ID
      AND em.SALARY < e1.SALARY
  ) = 1
ORDER BY
	em.LAST_NAME
, em.FIRST_NAME;

-- Question 39: Returns 24 row(s)
-- Find the full name of employees who have the same first or last name. Do not include redundant records.

SELECT
	CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name 1`
, CONCAT(e2.LAST_NAME, ', ', e2.FIRST_NAME) AS `Employee Name 2`
FROM
	employees e1
		JOIN 	employees e2
			ON	e1.EMPLOYEE_ID > e2.EMPLOYEE_ID
      AND	(e1.FIRST_NAME = e2.FIRST_NAME
      OR	e1.LAST_NAME = e2.LAST_NAME)
ORDER BY
	e1.LAST_NAME
, e1.FIRST_NAME
, e2.LAST_NAME
, e2.FIRST_NAME;

-- Question 41: Returns 1 row(s)
-- Find the number of employees whose salary is greater than 1.5 times the average salary of the 
-- company and whose job_title does not contain manager.

-- Query 1: Using a subquery

SELECT
	COUNT(em.EMPLOYEE_ID) AS `# of Employees`
FROM
	employees em
		JOIN 	jobs jo 
			ON 	em.JOB_ID = jo.JOB_ID
WHERE 
	em.SALARY > (SELECT AVG(SALARY) * 1.5 FROM employees)
  AND jo.JOB_TITLE NOT LIKE '%Manager%';

-- Query 2: Subquery factored out as CTE

WITH
	salary_stats AS (
		SELECT
			AVG(em.SALARY) AS `Average Salary`
		FROM
			employees em
	)

SELECT
	COUNT(em.EMPLOYEE_ID) AS `# of Employees`
FROM
	employees em
		JOIN	jobs jo
			ON 	em.JOB_ID = jo.JOB_ID
, salary_stats
WHERE
	em.SALARY > salary_stats.`Average Salary` * 1.5
  AND jo.JOB_TITLE NOT LIKE '%Manager%';

-- Question 42: Returns 8 row(s)
-- For all departments, get its name and calculate the number of employees who earn more than 
-- the department’s average salary. Order the results by the number of employees in descending order.

WITH
	department_stats AS (
		SELECT
			em.DEPARTMENT_ID
		, AVG(em.SALARY) AS average_salary
		FROM
			employees em
		GROUP BY
			em.DEPARTMENT_ID
	)
  
SELECT
	de.DEPARTMENT_NAME
, COUNT(em.EMPLOYEE_ID) AS `# of Employees`
FROM
	departments de
		LEFT JOIN	employees em
			ON	de.DEPARTMENT_ID = em.DEPARTMENT_ID
		LEFT JOIN department_stats 
			ON 	em.DEPARTMENT_ID = department_stats.DEPARTMENT_ID
WHERE
	em.SALARY > department_stats.average_salary
GROUP BY
	de.DEPARTMENT_NAME
ORDER BY
	`# of Employees` DESC;

-- Question 43: Returns 7 row(s)
-- Find the full name of all superiors who joined the company at least 30 days after its company president.

SELECT
	CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Manager Name`
FROM
	employees e1
		JOIN 	employees e2
			ON	e1.EMPLOYEE_ID = e2.MANAGER_ID
WHERE
	TIMESTAMPDIFF(day, 
		(
			SELECT
				em.HIRE_DATE
			FROM
				employees em
			WHERE
				em.JOB_ID = 'AD_PRES'
		)
  , e1.HIRE_DATE) >= 30
GROUP BY
	e1.EMPLOYEE_ID
ORDER BY
	e1.LAST_NAME
, e1.FIRST_NAME;

-- Question 44: Returns 20 row(s)
-- List the full name and hiring date of employees in the Americas whose hire date falls 
-- on a weekend (Saturday or Sunday).

SELECT
	CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
, em.HIRE_DATE
FROM
	employees em
		JOIN	departments de
			ON	em.DEPARTMENT_ID = de.DEPARTMENT_ID
		JOIN	locations lo
			ON	de.LOCATION_ID = lo.LOCATION_ID
		JOIN	countries co
			ON	lo.COUNTRY_ID = co.COUNTRY_ID
		JOIN	regions re
			ON	co.REGION_ID = re.REGION_ID
WHERE
	DAYNAME(em.HIRE_DATE) IN ('Saturday', 'Sunday')
  AND	re.REGION_NAME = 'Americas'
ORDER BY
	em.LAST_NAME
, em.FIRST_NAME;

-- Question 45: Returns 20 row(s)
-- For each department, retrieve the department name, full name and salary of the employee 
-- with the highest salary and the employee with the lowest salary. Only include departments
-- with at least one employee.

SELECT
	de.DEPARTMENT_NAME
, CONCAT(em.LAST_NAME, ', ', em.FIRST_NAME) AS `Employee Name`
, em.SALARY
FROM
	employees em
		JOIN 	departments de 
			ON 	em.DEPARTMENT_ID = de.DEPARTMENT_ID
WHERE
	em.SALARY = (
		SELECT
			MAX(e1.SALARY)
		FROM
			employees e1
		WHERE
			e1.DEPARTMENT_ID = em.DEPARTMENT_ID
	)
	OR em.SALARY = (
		SELECT
			MIN(e2.SALARY)
		FROM
			employees e2
		WHERE
			e2.DEPARTMENT_ID = em.DEPARTMENT_ID
	)
ORDER BY
	de.DEPARTMENT_NAME
, em.LAST_NAME
, em.FIRST_NAME;

-- Question 46: Returns 2 row(s)
-- List the regions where the total number of locations in the region exceeds the number 
-- of employees working in that particular region. Include said data in the resulting table.

SELECT 
	re.region_name
, COUNT(em.EMPLOYEE_ID) AS `# of Employees`
, COUNT(DISTINCT lo.LOCATION_ID) AS `# of Locations`
FROM
	regions re
		JOIN	countries co 
			ON 	re.REGION_ID = co.REGION_ID
		JOIN 	locations lo 
			ON 	co.COUNTRY_ID = lo.COUNTRY_ID
		LEFT JOIN	departments de 
			ON 	lo.LOCATION_ID = de.LOCATION_ID
		LEFT JOIN	employees em 
			ON 	de.DEPARTMENT_ID = em.DEPARTMENT_ID
GROUP BY 
	re.region_name
HAVING 
	`# of Employees` < `# of Locations`;
  
-- Question 47: Returns 4 row(s)
-- Find the number of employees per region whose salary is greater than the average salary in their 
-- region. Include all regions.

-- Query 1: Query using RIGHT JOIN

SELECT
	re.REGION_NAME
, COUNT(em.EMPLOYEE_ID) AS `# of Employees`
FROM
	employees em
		RIGHT JOIN	departments de
			ON	em.DEPARTMENT_ID = de.DEPARTMENT_ID
		RIGHT JOIN	locations lo
			ON	de.LOCATION_ID = lo.LOCATION_ID
		RIGHT JOIN	countries co
			ON	lo.COUNTRY_ID = co.COUNTRY_ID
		RIGHT JOIN	regions re
			ON	co.REGION_ID = re.REGION_ID
WHERE
	em.SALARY > (
		SELECT
			AVG(e1.SALARY)
		FROM
			employees e1
				JOIN	departments d1
					ON	e1.DEPARTMENT_ID = d1.DEPARTMENT_ID
				JOIN	locations l1
					ON	d1.LOCATION_ID = l1.LOCATION_ID
				JOIN	countries c1
					ON	l1.COUNTRY_ID = c1.COUNTRY_ID
				JOIN	regions r1
					ON	c1.REGION_ID = r1.REGION_ID
		WHERE
			re.REGION_NAME = r1.REGION_NAME
  )
  OR em.EMPLOYEE_ID IS NULL
GROUP BY
	re.REGION_NAME;

-- Query 2: Query using LEFT JOIN

SELECT
	re.REGION_NAME
, COUNT(em.EMPLOYEE_ID) AS `# of Employees`
FROM
	regions re
		LEFT JOIN	countries co 
			ON re.REGION_ID = co.REGION_ID
		LEFT JOIN locations lo 
			ON co.COUNTRY_ID = lo.COUNTRY_ID
		LEFT JOIN departments de 
			ON lo.LOCATION_ID = de.LOCATION_ID
		LEFT JOIN employees em 
			ON de.DEPARTMENT_ID = em.DEPARTMENT_ID
WHERE
	em.SALARY > (
		SELECT
			AVG(e1.SALARY)
		FROM
			employees e1
				JOIN	departments d1
					ON	e1.DEPARTMENT_ID = d1.DEPARTMENT_ID
				JOIN	locations l1
					ON	d1.LOCATION_ID = l1.LOCATION_ID
				JOIN	countries c1
					ON	l1.COUNTRY_ID = c1.COUNTRY_ID
				JOIN	regions r1
					ON	c1.REGION_ID = r1.REGION_ID
		WHERE
			re.REGION_NAME = r1.REGION_NAME
  )
  OR em.EMPLOYEE_ID IS NULL
GROUP BY
	re.REGION_NAME;
  
-- Question 48: Returns 1 row(s)
-- Find the region whose maximum salary is the lowest compared to all other regions. Include said salary
-- in the resulting table

SELECT
	re.REGION_NAME
, MAX(em.SALARY) AS `Highest Salary`
FROM
	regions re
		LEFT JOIN	countries co 
			ON re.REGION_ID = co.REGION_ID
		LEFT JOIN locations lo 
			ON co.COUNTRY_ID = lo.COUNTRY_ID
		LEFT JOIN departments de 
			ON lo.LOCATION_ID = de.LOCATION_ID
		LEFT JOIN employees em 
			ON de.DEPARTMENT_ID = em.DEPARTMENT_ID
GROUP BY
	re.REGION_NAME
HAVING
	COUNT(em.EMPLOYEE_ID) > 0
ORDER BY
	`Highest Salary`
LIMIT 1;

-- Question 49: Returns 4 row(s)
-- Find the city and country of all locations where the average salary is higher than the 
-- average salary of the entire company.

SELECT
	lo.CITY
, co.COUNTRY_NAME
FROM
	locations lo
		JOIN	countries co
			ON	lo.COUNTRY_ID = co.COUNTRY_ID
		JOIN	departments de
			ON	lo.LOCATION_ID = de.LOCATION_ID
		JOIN	employees em
			ON	de.DEPARTMENT_ID = em.DEPARTMENT_ID
	GROUP BY
		lo.CITY
	, co.COUNTRY_NAME
	HAVING
		AVG(em.SALARY) > (SELECT AVG(em.SALARY) FROM employees em);
    
-- Question 51: Returns 18 row(s)
-- Retrieve the records of employees with three or more consecutive hire dates where 
-- their salary is at least 9000. Return the name, hire date, and salary of the employees 
-- ordered by hire_date in ascending order.

-- Query 1: Using UNION through a Divide-and-Conquer approach (shoutout to ALGCM)

SELECT
	*
FROM
	(
		SELECT
			CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name`
		, e1.HIRE_DATE
    , e1.SALARY
    FROM
			employees e1
				JOIN	employees e2
					ON	e1.HIRE_DATE = e2.HIRE_DATE + 1
				JOIN	employees e3
					ON	e1.HIRE_DATE = e3.HIRE_DATE + 2
		WHERE
			e1.SALARY >= 9000
      AND e2.SALARY >= 9000
      AND e3.SALARY >= 9000

		UNION

    SELECT
			CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name`
		, e1.HIRE_DATE
    , e1.SALARY
    FROM
			employees e1
				JOIN	employees e2
					ON	e1.HIRE_DATE = e2.HIRE_DATE - 1
				JOIN	employees e3
					ON	e1.HIRE_DATE = e3.HIRE_DATE + 1
		WHERE
			e1.SALARY >= 9000
      AND e2.SALARY >= 9000
      AND e3.SALARY >= 9000

		UNION

		SELECT
			CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name`
		, e1.HIRE_DATE
    , e1.SALARY
    FROM
			employees e1
				JOIN	employees e2
					ON	e1.HIRE_DATE = e2.HIRE_DATE - 1
				JOIN	employees e3
					ON	e1.HIRE_DATE = e3.HIRE_DATE - 2
		WHERE
			e1.SALARY >= 9000
      AND e2.SALARY >= 9000
      AND e3.SALARY >= 9000
  ) AS `Employees`
ORDER BY
	`Employees`.HIRE_DATE;

-- Query 2: Without using subqueries (credits: lowestofthelow)

SELECT 
	CONCAT(e1.LAST_NAME, ', ', e1.FIRST_NAME) AS `Employee Name`
, e1.HIRE_DATE
, e1.SALARY
FROM
	employees e1
		LEFT JOIN employees e2 
			ON e1.HIRE_DATE = e2.HIRE_DATE - 2 
      AND e2.SALARY >= 9000
    LEFT JOIN employees e3 
			ON e1.HIRE_DATE = e3.HIRE_DATE - 1 
      AND e3.SALARY >= 9000
		LEFT JOIN employees e4 
			ON e1.HIRE_DATE = e4.HIRE_DATE + 1 
      AND e4.SALARY >= 9000
		LEFT JOIN employees e5 
			ON e1.HIRE_DATE = e5.HIRE_DATE + 2 
			AND e5.SALARY >= 9000
WHERE 
    e1.SALARY >= 9000 
    AND (e2.HIRE_DATE IS NOT NULL AND e3.HIRE_DATE IS NOT NULL 
    OR 	e3.HIRE_DATE IS NOT NULL AND e4.HIRE_DATE IS NOT NULL
    OR 	e4.HIRE_DATE IS NOT NULL AND e5.HIRE_DATE IS NOT NULL)
ORDER BY 
	e1.HIRE_DATE;

-- Question 54: Returns 8 row(s)
-- Find all invalid locations.

SELECT
	*
FROM
	locations lo
WHERE
	lo.POSTAL_CODE = ''
  OR lo.CITY = ''
  OR lo.STATE_PROVINCE = ''
  OR lo.COUNTRY_ID NOT IN (SELECT co.COUNTRY_ID FROM countries co)
  OR lo.POSTAL_CODE NOT REGEXP '[0-9]';

-- Question 55: Returns 11 row(s)
-- For all department managers, calculate the number of employees in their department who joined 
-- the company in July or August. Include those who do not have other employees in the department or those
-- with no employees who fit the criteria.

SELECT 
	CONCAT(dm.LAST_NAME, ', ', dm.FIRST_NAME) AS `Manager Name`,
	COUNT(em.EMPLOYEE_ID) AS `# of Employees`
FROM 
	departments de
		JOIN 	employees dm 
			ON 	de.MANAGER_ID = dm.EMPLOYEE_ID
		LEFT JOIN	employees em 
			ON 	em.DEPARTMENT_ID = de.DEPARTMENT_ID 
			AND em.HIRE_DATE >= '1987-07-01' 
			AND em.HIRE_DATE <= '1987-08-30'
GROUP BY 
    dm.EMPLOYEE_ID
ORDER BY 
    `# of Employees` DESC;