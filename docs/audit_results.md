# Audit results

Source: `data_quality.sql`. At most 25 rows are kept per query.

## Q9: How many orders are in each status, and what share is that?

```
order_status  orders   pct
   delivered   96478 97.02
     shipped    1107  1.11
    canceled     625  0.63
 unavailable     609  0.61
    invoiced     314  0.32
  processing     301  0.30
     created       5  0.01
    approved       2  0.00
```

## Q10: Which delivered orders have no delivery date? (dropped by the pipeline)

```
                        order_id order_purchase_timestamp order_delivered_customer_date
2d1e2d5bf4dc7227b3bfebb81328c15f      2017-11-28 17:44:07                          None
f5dd62b788049ad9fc0526e3ad11a097      2018-06-20 06:58:43                          None
2ebdfc4f15f23b91474edf87475f108e      2018-07-01 17:05:11                          None
e69f75a717d64fc5ecdfae42b2e8e086      2018-07-01 22:05:55                          None
0d3268bad9b086af767785e3f0fc0133      2018-07-01 21:14:02                          None
2d858f451373b04fb5c984a1cc2defaf      2017-05-25 23:22:43                          None
ab7c89dc1bf4a1ead9d6ec1ec8968a84      2018-06-08 12:09:39                          None
20edc82cf5400ce95e1afacc25798b31      2018-06-27 16:09:12                          None
```

## Q11: How many delivered orders were dropped for a missing delivery date?

```
 delivered_without_date
                      8
```

## Q12: Does any order_id appear more than once in raw_orders?

No rows.

## Q13: Does any order_id have more than one review in raw_order_reviews?

```
                        order_id  review_count
cf73e2cb1f4a9480ed70c154da3d954a             2
169d7e0fd71d624d306f132acd791cbe             2
1c308eca3f339414a92e518e2a2e5ee9             2
2002ea16e75277eaa0b5d78632048540             2
1d297b4800ed1a3c5b0944d84c01ee99             2
0176a6846bcb3b0d3aa3116a9a768597             2
b6e5aa946acc4e29e7069510f28a0bce             2
5040757d4e06a4be96d3827b860b4e7c             2
80446aee36e09ebf4cb79585f6c9ce61             2
45390ff93f092f0de1524d486a172c33             2
0e457aee274ec7e2e18d25ab6d212921             2
fd61441ba2a7b57e6342862e779b10b0             2
4703440eb9289d3769819920e98ec061             2
2daee070f2042c8b7a8e9fdde778a31a             2
076d991923ee938761994a4255f5c5da             2
98c977c116f7779360e9fecffd3860b6             2
3df55fc07ff463109ce0422439693aee             2
0715dfcf2383aa72c181d8b47f6cb589             2
f0fbc60d51bb40c156688d9ce008237f             2
c88b1d1b157a9999ce368f218a407141             3
2acfdc5131ff2cf4433e668454c9784c             2
1544b91291000836c72384f035436fbf             2
e832fe7f7808b5f981ee02746681d40e             2
f63a31c3349b87273468ff7e66852056             2
cc1b834e8d019a8c71e3c3b1a23edc61             2
```

(first 25 rows shown, more exist)

## Q14: How many orders have 1, 2, 3 ... reviews?

```
 review_count  orders
            1   98126
            2     543
            3       4
```

## Q15: How many extra rows would a careless orders-to-reviews join create?

```
 raw_orders_rows  rows_after_join  extra_rows_from_join
           99441            99992                   551
```

## Q16: How many rows does each table hold?

```
                           table_name  row_count
                           raw_orders      99441
                        raw_customers      99441
                      raw_order_items     112650
                   raw_order_payments     103886
                    raw_order_reviews      99224
                         raw_products      32951
                          raw_sellers       3095
raw_product_category_name_translation         71
                          fact_orders      96470
                           fact_items     110189
                                  rfm      93350
```

## Q17: Order waterfall: from all raw orders down to the pipeline output

```
 step_no                                                 step  orders
       1                             All orders in raw_orders   99441
       2                                   Status = delivered   96478
       3                    Delivered and has a delivery date   96470
       4 Delivered, has a delivery date and at least one item   96470
       5              Orders in fact_orders (pipeline output)   96470
```

## Q18: Which orders have no items at all, by status?

```
order_status  orders_without_items
 unavailable                   603
    canceled                   164
     created                     5
    invoiced                     2
     shipped                     1
```

## Q19: Which timestamps are missing, by order status?

```
order_status  orders no_approved_date no_carrier_date no_delivery_date
   delivered   96478               14               2                8
     shipped    1107                0               0             1107
    canceled     625              141             550              619
 unavailable     609                0             609              609
    invoiced     314                0             314              314
  processing     301                0             301              301
     created       5                5               5                5
    approved       2                0               2                2
```

## Q20: Which product attributes are missing or zero?

```
 products no_category no_weight no_length no_height no_width zero_weight
    32951         610         2         2         2        2           4
```

## Q21: Which product categories have no English translation?

```
                        product_category_name  products
                                     pc_gamer         3
portateis_cozinha_e_preparadores_de_alimentos        10
```

## Q22: How many orders have impossible date sequences?

```
delivered_before_purchase carrier_pickup_before_purchase delivered_before_carrier_pickup estimate_before_purchase
                        0                            166                              23                        0
```

## Q23: How long do deliveries take, and how extreme are the slowest?

```
 delivered_orders  min_days avg_days  max_days over_60_days over_100_days
            96470         0     12.5       210          298            64
```

## Q24: What does the price and freight distribution look like?

```
 item_rows  min_price  avg_price  max_price non_positive_price zero_freight  max_freight freight_above_price
    112650       0.85     120.65     6735.0                  0          383       409.68                4124
```

## Q25: Which 10 items have the highest prices? (outlier review)

```
                        order_id                       product_id   price  freight_value
0812eb902a67711a1cb742b3cdaa65ae 489ae2aa008f021502940f251d4cce7f 6735.00         194.31
fefacc66af859508bf1a7934eab1e97f 69c590f7ffc7bf8db97190b6cb6ed62e 6729.00         193.21
f5136e38d1a14a4dbd87dff67da82701 1bdf5e6731585cf01aa8169c7028d6ad 6499.00         227.66
a96610ab360d42a2e5335a3998b4718a a6492cc69376c469ab6f61d8f44de961 4799.00         151.34
199af31afc78c699f0dbf71fb178d4d4 c3ed642d592594bb648ff4a04cee2747 4690.00          74.34
8dbc85d1447242f3b127dda390d56e19 259037a6a41845e455183f89c5035f18 4590.00          91.78
426a9742b533fc6fed17d1fd6d143d7e a1beef8f3992dbd4cd8726796aa69c53 4399.87         113.45
68101694e5c5dc7330c91e1bbc36214f 6cdf8fc1d741c76586d8b6b15e9eef30 4099.99          75.27
b239ca7cd485940b31882363b52e6674 dd113cb02b2af9c8e5787e8f1f0722f6 4059.00         104.51
86c4eab1571921a6a6e248ed312f5a5a 6902c1962dd19d540807d0ab8fade5c6 3999.90          17.01
```

## Q26: What are the review score values? (valid range is 1 to 5)

```
 review_score  reviews
            1    11424
            2     3151
            3     8179
            4    19142
            5    57328
```

## Q27: Do payments match items + freight per order?

```
 orders_compared mismatched_orders  net_difference
           98665               380         2870.39
```

## Q28: How are payment types used, and are there zero-value payments?

```
payment_type  payments zero_value_payments  total_paid
 credit_card     76795                   0 12542084.19
      boleto     19784                   0  2869361.27
     voucher      5775                   6   379436.87
  debit_card      1529                   0   217989.79
 not_defined         3                   3        0.00
```

## Q29: Is (order_id, order_item_id) unique in raw_order_items?

No rows.

## Q30: Are there orphan keys? (rows pointing to something that does not exist)

```
                    issue  rows_affected
   items without an order              0
orders without a customer              0
  items without a product              0
   items without a seller              0
 reviews without an order              0
payments without an order              0
```

## Q31: customer_id vs customer_unique_id: which one identifies a real person?

```
 customer_rows  distinct_customer_id  distinct_real_customers
         99441                 99441                    96096
```

## Q32: Does revenue agree across every layer?

```
 fact_orders_revenue  fact_items_revenue  rfm_revenue  rebuilt_from_raw_revenue
         13220248.93         13220248.93  13220248.93               13220248.93
```

## Q33: Do order and customer counts agree across layers?

```
 fact_orders_rows  fact_orders_distinct_orders  fact_items_distinct_orders  customers_in_fact_orders  customers_in_rfm
            96470                        96470                       96470                     93350             93350
```

## Q34: How many orders in fact_orders have no review score?

```
 orders orders_without_review pct_without_review
  96470                   646               0.67
```

## Q35: How much revenue sits in the 'unknown' category?

```
 item_rows unknown_items pct_items_unknown  unknown_revenue
    110189          1559              1.41        175967.21
```

## Q36: Which orders have an impossible delivery chronology? (detail for Q22)

```
                        order_id order_purchase_timestamp order_delivered_carrier_date order_delivered_customer_date
b9afddbdcfadc9a87b41a83271c3e888      2018-08-16 13:50:48          2018-08-16 13:27:00           2018-08-24 14:58:37
ad133696906f6a78826daa0911b7daec      2018-06-15 15:41:22          2018-06-15 14:52:00           2018-06-22 18:09:37
74e033208dc13a7b8127eb8e73d09b76      2018-05-02 10:48:44          2018-05-02 09:49:00           2018-05-07 23:06:36
a6b58794fd2ba533359a76c08df576e3      2018-05-14 15:18:23          2018-05-14 13:46:00           2018-05-19 19:33:32
5792e0b1c8c8a2bf53af468c9a422c88      2018-07-26 13:25:14          2018-07-26 12:42:00           2018-07-30 14:45:02
c3eb293fd154223498b6551a728203e8      2018-07-19 14:06:04          2018-07-19 13:49:00           2018-07-24 19:35:36
b0c2a7d04b165525254254a728c50a4e      2018-06-07 13:28:30          2018-06-07 13:22:00           2018-06-21 17:36:43
2033a4586b5bec3229ebc1675a8ae092      2018-06-12 10:10:25          2018-06-12 10:09:00           2018-06-19 14:08:27
08adcddad19d3acf37d1fa01cb9ded1e      2018-06-27 11:16:44          2018-06-27 10:57:00           2018-06-29 17:39:53
dee6298ce7d1fb2645141ef9972157aa      2018-04-30 14:06:12          2018-04-30 12:59:00                          None
4e157a36ea9cf89bde6fff57a780b525      2018-08-24 14:37:50          2018-08-24 12:43:00           2018-08-30 20:47:26
d454d6650d375ebc3f9667a4d2fe161c      2018-05-10 09:12:16          2018-05-10 09:11:00           2018-05-11 18:58:28
a5a9f45d795fafe0077043697f62fd4f      2018-07-04 14:45:20          2018-07-04 13:41:00           2018-07-11 23:08:32
dab23a46abb860b6b4816df41eacd610      2018-08-08 15:42:27          2018-08-08 14:56:00           2018-08-11 17:04:47
b4180badf3ac49892e23d6e0276f1e84      2018-04-26 14:44:05          2018-04-26 13:51:00           2018-05-03 00:14:44
6c5d1e03493316b72304f07834a03325      2018-06-12 13:56:41          2018-06-12 13:06:00           2018-07-17 16:32:20
ede6a833580744e002b0ee65323a3006      2018-08-17 15:11:53          2018-08-17 14:07:00           2018-08-22 19:28:52
1227f9af3b2ddb0b95060aab8e5b3dc7      2018-05-10 14:48:29          2018-05-10 14:00:00           2018-05-18 16:21:53
2996234f359b5a3b99263b0f5b841d86      2018-08-15 15:48:50          2018-08-15 14:16:00           2018-08-22 22:34:27
108c3238d247dead3fd7423cf8990c5b      2018-08-14 13:49:12          2018-08-14 13:17:00           2018-08-23 16:06:36
0150004d4d8eb63f9948de164da34e34      2018-05-15 15:13:06          2018-05-15 14:58:00           2018-05-23 18:13:16
da383ff6aa9558f3bd909b1d76789381      2018-08-20 13:56:52          2018-08-20 13:55:00           2018-08-27 23:32:23
9b087af1d905d8987ae126797c9d15b1      2018-08-01 13:47:04          2018-08-01 13:31:00           2018-08-08 13:35:29
fb3cf8c9eb2412b0edc0a00a8f43a869      2018-05-29 14:07:25          2018-05-29 13:58:00           2018-06-05 21:46:32
0cf80be143500050973f324c3e068196      2018-07-26 14:33:26          2018-07-26 13:32:00           2018-07-30 22:22:08
```

(first 25 rows shown, more exist)
