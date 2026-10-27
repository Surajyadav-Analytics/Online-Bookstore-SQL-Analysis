CREATE DATABASE Online_BookStore;
USE Online_BookStore;


-- Create Tables
CREATE TABLE Books (
    Book_ID SERIAL PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(100),
    Genre VARCHAR(50),
    Published_Year INT,
    Price NUMERIC(10, 2),
    Stock INT
);

CREATE TABLE Customers (
    Customer_ID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(15),
    City VARCHAR(50),
    Country VARCHAR(150)
);

CREATE TABLE Orders (
    Order_ID SERIAL PRIMARY KEY,
    Customer_ID INT REFERENCES Customers(Customer_ID),
    Book_ID INT REFERENCES Books(Book_ID),
    Order_Date DATE,
    Quantity INT,
    Total_Amount NUMERIC(10, 2)
);

SELECT * FROM Books;
SELECT * FROM Customers;
SELECT * FROM Orders;

-- 1) Retrieve all books in the "Fiction" genre:
SELECT * FROM Books
WHERE Genre = 'Fiction';

-- 2) Find books published after the year 1950:
SELECT * FROM Books 
WHERE Published_Year > 1950;

-- 3) List all customers from the Canada:
SELECT * FROM Customers
WHERE Country = 'Canada';

-- 4) Show orders placed in November 2023:
SELECT * FROM Orders 
WHERE Order_Date BETWEEN '2023-11-01' AND '2023-11-30';

-- 5) Retrieve the total stock of books available:
SELECT SUM(Stock) AS Total_Stock 
FROM Books;

-- 6) Find the details of the most expensive book:
SELECT * FROM Books 
ORDER BY Price DESC 
LIMIT 1;

-- 7) Show all customers who ordered more than 1 quantity of a book:
SELECT * FROM Orders
WHERE Quantity > 1;

-- 8) Retrieve all orders where the total amount exceeds $20:
SELECT * FROM Orders
WHERE Total_Amount > 20;

-- 9) List all genres available in the Books table:
SELECT DISTINCT Genre 
FROM Books;

-- 10) Find the book with the lowest stock:
SELECT * FROM Books 
ORDER BY Stock ASC 
LIMIT 1;

-- 11) Calculate the total revenue generated from all orders:
SELECT SUM(Total_Amount) AS Revenue 
FROM Orders;

-- ADVANCED

-- 1) Retrieve the total number of books sold for each genre:
SELECT Books.Genre, SUM(Orders.Quantity) AS Total_Sold_Books
FROM Orders 
INNER JOIN Books USING (Book_ID)
GROUP BY Genre;

-- 2) Find the average price of books in the "Fantasy" genre:
SELECT Genre, ROUND(AVG(Price),2) AS Average_Price
FROM Books 
GROUP BY Genre
HAVING Genre = 'Fantasy';

-- 3) List customers who have placed at least 2 orders:
SELECT Customers.Customer_ID, Customers.Name, COUNT(Order_ID) AS Orders_Count
FROM Customers 
INNER JOIN Orders USING (Customer_ID) 
GROUP BY 1,2 HAVING Orders_Count >=2;

-- 4) Find the most frequently ordered book:
SELECT Books.Book_ID, Books.Title, COUNT(Orders.Order_ID) AS Order_Count
FROM Books 
INNER JOIN Orders USING (Book_ID)
GROUP BY 1,2
ORDER BY Order_Count DESC;

-- 5) Show the top 3 most expensive books of 'Fantasy' Genre :
SELECT * FROM Books
WHERE Genre = 'Fantasy'
ORDER BY Price DESC
LIMIT 3;

-- 6) Retrieve the total quantity of books sold by each author:
SELECT Books.Author, SUM(Orders.Quantity) AS Total_Quantity
FROM Books 
INNER JOIN Orders USING (Book_ID)
GROUP BY 1;

-- 7) List the cities where customers who spent over $30 are located:
SELECT DISTINCT Customers.City, Orders.Total_Amount
FROM Orders
INNER JOIN Customers USING (Customer_ID)
WHERE Orders.Total_Amount > 30;

-- 8) Find the customer who spent the most on orders:
SELECT Customers.Customer_ID, Customers.Name, SUM(Orders.Total_Amount) AS Total_Spent
FROM Orders
INNER JOIN Customers USING (Customer_ID)
GROUP BY 1,2
ORDER BY Total_Spent DESC
LIMIT 1;

-- 9) Calculate the stock remaining after fulfilling all orders:
WITH Count_of_Orders AS (
SELECT Books.Book_ID, Books.Title, Books.Stock, COALESCE(SUM(Quantity),0) AS Order_Count
FROM Books 
LEFT JOIN Orders USING (Book_ID)
GROUP BY 1)

SELECT *, Stock - Order_Count AS Remaining_Stock FROM Count_of_Orders;

-- 10) Which customers contribute more revenue than the average customer:
SELECT Customers.Customer_ID, Customers.Name, SUM(Orders.Total_Amount) AS Contribute_High_revenue
FROM Customers
INNER JOIN Orders USING (Customer_ID)
GROUP BY 1,2
HAVING SUM(Orders.Total_Amount) > (SELECT AVG(Customer_rev) 
FROM (SELECT SUM(Total_Amount) AS Customer_rev 
FROM Orders 
GROUP BY Customer_ID)
AS Total_rev);

-- 11) Which books are outperforming the average book in revenue generation:
SELECT Books.Book_ID, Books.Title, SUM(Orders.Total_Amount) AS Outperforming_Books
FROM Books
INNER JOIN Orders USING (Book_ID)
GROUP BY 1,2
HAVING SUM(Orders.Total_Amount) > (SELECT AVG(Total_rev)
FROM (SELECT SUM(Total_Amount) AS Total_rev 
FROM Orders
GROUP BY Book_ID) 
AS Book_rev);

-- 12) Find customers whose Customer_ID does not exist in the Orders table:
SELECT * FROM Customers
WHERE NOT EXISTS (SELECT Customer_ID FROM Orders
WHERE Customers.Customer_ID = Orders.Customer_ID);

-- 13) Calculate monthly revenue and compare it with the previous month's revenue:
WITH Monthly_Rev AS (
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Months, SUM(Total_Amount) AS Total_Revenue
FROM Orders
GROUP BY 1),

Previous_Month_Rev AS (
SELECT *, LAG(Total_Revenue) OVER (ORDER BY Months) AS Previous_Month_Revenue
FROM Monthly_Rev)

SELECT *, Total_Revenue - Previous_Month_Revenue AS Revenue_Difference 
FROM Previous_Month_Rev;

-- 14) Calculate each customer's total spending and classify them into three categories:
WITH Total_Spent AS (
SELECT Customers.Customer_ID, Customers.Name, SUM(Total_Amount) AS Total_Spending 
FROM Customers 
INNER JOIN Orders USING (Customer_ID)
GROUP BY 1,2)

SELECT *, CASE WHEN Total_Spending >=900 THEN 'High Value' 
		       WHEN Total_Spending >=300 THEN 'Average Value' 
               ELSE 'Low Value'
          END AS Segment
FROM Total_Spent
ORDER BY Total_Spending DESC;

-- 15) Calculate total revenue for each genre and identify the genre with the highest revenue:
SELECT Genre, SUM(Orders.Quantity) AS Total_Quantity, SUM(Orders.Total_Amount) AS Total_Revenue
FROM Orders 
INNER JOIN Books USING (Book_ID)
GROUP BY 1
ORDER BY Total_Revenue DESC;

-- 16) Calculate each book's total revenue and rank books within their respective genres:
WITH Total_rev AS (
SELECT Books.Title, Books.Genre,  SUM(Total_Amount) AS Total_Revenue
FROM Books
INNER JOIN Orders USING (Book_ID)
GROUP BY 1,2),

Ranking AS (
SELECT *, RANK() OVER (PARTITION BY Genre ORDER BY Total_Revenue DESC) AS Rnk 
FROM Total_rev)

SELECT * FROM Ranking WHERE Rnk <= 3;

-- 17) Calculate monthly revenue and cumulative revenue, resetting the cumulative total at the beginning of each year:
WITH Monthly_Sales AS (
SELECT YEAR(Order_Date) AS Year, MONTH(Order_Date) AS Month_Number,
DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
SUM(Total_Amount) AS Monthly_Revenue
FROM Orders
GROUP BY 1,2,3)

SELECT Year, Month, Monthly_Revenue, SUM(Monthly_Revenue) OVER (PARTITION BY Year 
ORDER BY Month_Number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_Revenue
FROM Monthly_Sales
ORDER BY Year, Month_Number;
