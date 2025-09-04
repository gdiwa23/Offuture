SELECT *
FROM all_2506.fantabulous_offuture
WHERE fantabulous_offuture.order_id IN (
    SELECT fantabulous_offuture.order_id
    FROM all_2506.fantabulous_offuture
    WHERE 
    fantabulous_offuture.sub_category = 'Tables'
)

-- sum of profits 
SELECT SUM(fo.profit) AS profit_sum
FROM all_2506.fantabulous_offuture AS fo; -- 1467456.55

-- sum where positive profits 

SELECT SUM(fo.profit) AS profit_sum
FROM all_2506.fantabulous_offuture AS fo
WHERE fo.profit > '0'; -- 2,388,106.77

SELECT SUM(fo.profit) AS profit_negative
FROM all_2506.fantabulous_offuture AS fo   -- -920631.72 (w discount)
WHERE fo.profit < '0' AND fo.discount > '0'; -- -920650.22 (no discount)

-- sum of all sales
SELECT SUM(fo.sales) AS sum_ofsales
FROM all_2506.fantabulous_offuture AS fo; -- 12,642,507.25

-- check if 0 discount has neg profits associated
SELECT --fo.profit, fo.discount, fo.customer_name, fo.shipping_cost 
--*
    SUM(fo.profit)
FROM all_2506.fantabulous_offuture AS fo -- sum loss = -18.50
-- 13 instances of 0 discount but led to losses , all in south america 
WHERE fo.profit < '0' AND fo.discount = '0';


-- count of all  orders that made profit and used a discount 
SELECT SUM(fo.profit)
FROM all_2506.fantabulous_offuture AS fo -- 
WHERE fo.profit > '0' AND fo.discount > '0';-- 559416.06

-- take out the proif t> 0 clause, to check net 
SELECT SUM(fo.profit)
FROM all_2506.fantabulous_offuture AS fo -- -361215.66
WHERE fo.discount > '0'; -- checking net, took out profit > 0 clause

-- count unique customer names
SELECT COUNT(DISTINCT fo.customer_name)
FROM all_2506.fantabulous_offuture AS fo; -- 795


-- how many discount orders were from distinct first time customers/buyers ?

SELECT COUNT(fo.customer_name) AS first_time_buyer_count
FROM all_2506.fantabulous_offuture AS fo
WHERE fo.discount > '0';
-- 
-- finds first order date for each customer_name
WITH customer_first_order AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date
    FROM
        all_2506.fantabulous_offuture
    GROUP BY
        customer_name
)

-- joins to mains query
SELECT COUNT(DISTINCT fo.customer_name) AS first_time_discount_customers
-- makes sure to count distinct customer ids only
FROM all_2506.fantabulous_offuture AS fo
INNER JOIN customer_first_order AS cfo
    ON fo.customer_name = cfo.customer_name
WHERE                 -- customers first order date has discount
    -- clause discount, and order date matches first order date
    fo.discount > 0 AND
    fo.order_date = cfo.first_order_date; -- 371  = first time customers 


-- change to sum of profit, not sales q1 -- make sure mustafa has this one!! 
-- this is net, so also counts positive profit alongside, so balances to net 
WITH customer_first_order AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date   -- first order date
    FROM
        all_2506.fantabulous_offuture
    GROUP BY
        customer_name
)

-- sums profit from orders where customers used a discount in their first order
SELECT
    SUM(fo.profit) AS total_profit_from_first_time_discount_orders
FROM
    all_2506.fantabulous_offuture AS fo
INNER JOIN
    customer_first_order AS cfo
    ON fo.customer_name = cfo.customer_name
WHERE
    fo.discount > 0 AND
    fo.order_date = cfo.first_order_date;   --   -20140.06


-- clean returning customers only , count
WITH first_time_discount_customers AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date -- first order date
    FROM all_2506.fantabulous_offuture
    GROUP BY customer_name
),

discounted_first_orders AS (
    SELECT
        f.customer_name,
        ft.first_order_date
    FROM all_2506.fantabulous_offuture AS f
    INNER JOIN first_time_discount_customers AS ft
        ON
            f.customer_name = ft.customer_name AND
            f.order_date = ft.first_order_date
    WHERE f.discount > 0     -- where orders had a discoutn applied
),

returning_customers AS (
    SELECT DISTINCT f.customer_name
    FROM all_2506.fantabulous_offuture AS f
    INNER JOIN discounted_first_orders AS dfo
        -- joining on customers that had a discount in first order  
        ON f.customer_name = dfo.customer_name
    -- returning only, so where order date is greater than first order dates
    WHERE f.order_date > dfo.first_order_date
)

-- Final count of returning customers
SELECT COUNT(*) AS num_returning_customers --counts how many were return
FROM returning_customers;  --371  returned !!


--q1
-- sum of profit from cusotmers returning 
-- Clean returning customers only
WITH first_time_discount_customers AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date -- first order date 
    FROM all_2506.fantabulous_offuture
    GROUP BY customer_name
),

discounted_first_orders AS (
    SELECT
        f.customer_name,
        ft.first_order_date
    FROM all_2506.fantabulous_offuture AS f -- it had a discount on first order
    INNER JOIN first_time_discount_customers AS ft
        ON
            f.customer_name = ft.customer_name AND
            f.order_date = ft.first_order_date
    WHERE f.discount > 0
),

returning_customers AS (
    SELECT DISTINCT f.customer_name, f.order_date -- if they came back 
    FROM all_2506.fantabulous_offuture AS f
    INNER JOIN discounted_first_orders AS dfo
        ON f.customer_name = dfo.customer_name
    -- looks at every other order except first
    WHERE f.order_date > dfo.first_order_date
)

-- Final: Join back to get profit from return orders
SELECT
    COUNT(DISTINCT rc.customer_name) AS num_returning_customers,
    SUM(f.profit) AS profit_from_returning   -- after first order profitd
FROM returning_customers AS rc
INNER JOIN all_2506.fantabulous_offuture AS f
    ON
        rc.customer_name = f.customer_name AND   -- this includes all orders, even if they used discounts in later orders !
        f.order_date = rc.order_date;  -- net !! 672380.96


-- how many times did first time discount users use discounts 
WITH first_time_discount_customers AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date
    FROM all_2506.fantabulous_offuture
    GROUP BY customer_name
),

customers_with_discount_first_order AS (
    SELECT
        ft.customer_name
    FROM first_time_discount_customers AS ft
    INNER JOIN all_2506.fantabulous_offuture AS f
        ON
            ft.customer_name = f.customer_name AND
            ft.first_order_date = f.order_date
    WHERE f.discount > 0
),

discounted_orders_by_these_customers AS (
    SELECT
        customer_name,
        COUNT(*) AS discounted_order_count
    FROM all_2506.fantabulous_offuture
    WHERE
        discount > 0 AND
        customer_name IN (
            SELECT customer_name FROM customers_with_discount_first_order
        )
    GROUP BY customer_name
)

SELECT
    AVG(
        discounted_order_count
    ) AS avg_discounted_orders_per_first_time_discount_user
FROM discounted_orders_by_these_customers;   -- 28.4932614555256065 times 


-- did NOT use discount in first order 
WITH first_order_dates AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date
    FROM all_2506.fantabulous_offuture
    GROUP BY customer_name
),

customers_no_discount_first_order AS (
    SELECT
        f.customer_name
    FROM all_2506.fantabulous_offuture AS f
    INNER JOIN first_order_dates AS fo
        ON
            f.customer_name = fo.customer_name AND
            f.order_date = fo.first_order_date
    WHERE f.discount = 0
),

discounted_orders_for_these_customers AS (
    SELECT
        customer_name,
        COUNT(*) AS discounted_order_count
    FROM all_2506.fantabulous_offuture
    WHERE
        discount > 0 AND
        customer_name IN (
            SELECT customer_name FROM customers_no_discount_first_order
        )
    GROUP BY customer_name
)

SELECT
    AVG(
        discounted_order_count
    ) AS avg_discounted_orders_for_non_discount_first_order_customers
FROM discounted_orders_for_these_customers; --26.5502092050209205
