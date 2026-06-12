-- 连接orders,customers,order_items,sellers等四张表
-- 便于后续用于核心指标、地域分布、时间趋势、商品品类等四个维度的基础分析
-- 选取已送达的订单，否则没有分析的意义
SELECT 
        -- 1、订单基本信息
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,

        -- 2、买家信息
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,

        -- 3、商品和交易信息
        oi.product_id,
        oi.price,
        oi.freight_value,

        -- 4、卖家信息
        s.seller_id,
        s.seller_city,
        s.seller_state,

        -- 5、产品种类
        ca.product_category_name_english
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi on o.order_id = oi.order_id
INNER JOIN sellers s ON oi.seller_id = s.seller_id
LEFT JOIN products p ON oi.product_id = p.product_id -- 防止部分商品因null而被删除
LEFT JOIN category_translation ca ON p.product_category_name = ca.product_category_name
WHERE o.order_status = 'delivered';
       

-- 单独拿出完整的orders表，进行订单健康情况分析
SELECT order_id,
       customer_id,
       order_status,
       order_purchase_timestamp,
       order_approved_at,
       order_delivered_carrier_date,
       order_delivered_customer_date,
       order_estimated_delivery_date
FROM orders
       

-- 需要：用户唯一ID、订单时间（算R）、订单数（算F）、消费金额（m）
-- 进行深入探究用户分层部分
SELECT c.customer_unique_id,
       MAX(o.order_purchase_timestamp) AS last_purchase_time,
       COUNT(DISTINCT o.order_id) AS orders_frequency,
       SUM(oi.price) AS monetary
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id


-- 提取物流、价格、运费及评分数据，用于深入探究物流情况
SELECT 
    o.order_id,
    o.order_status,
    c.customer_unique_id,
    c.customer_state,
    o.order_purchase_timestamp,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.price,
    oi.freight_value,
    r.review_score
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL  -- 只要发了货的都算


-- 提取支付与订单状态数据，用于深入探究用户支付等情况
SELECT 
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM orders o
INNER JOIN order_payments p ON o.order_id = p.order_id


-- 提取品类与销售数据，用于深入探究商品与卖家生态
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    oi.order_id,
    oi.price
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name

-- 提起商家服务质量数据，用于深入探究商品与商家生态
SELECT 
    oi.seller_id,
    oi.order_id,
    oi.price,
    o.order_purchase_timestamp,
    o.order_delivered_carrier_date,
    r.review_score
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL
