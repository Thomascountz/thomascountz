---
title: Sargable Queries & MUL Indexes; or Why My Query is Slow
author: Thomas Countz
layout: post
tags: ["ruby", "sql", "database", "rails"]
featured: true
---

You're on Ops. Debugging `Error`-s in Invoicing Rails app, as usual. They're stored in MySQL, and accessed through ActiveRecord and some helper methods. They've already been updated with a `status_message`, so now it's time to dig in and investigate.

```ruby
irb(main):001:0> Error.column_names
[
    "id",
    "message",
    "backtrace",
    "status_message",
    "created_at",
    "updated_at",
    "runtime_environment",
    "error_type",
    "ticket_id"
]
```

The sun beams through your window on another record-high heat wave afternoon, but you're cool as a cucumber: you brought your sunglasses and a tall glass of trusty H2O.

Let's do this!

```ruby
Error.where_message_like("NoMethodError: undfined method `is_approved_by_finance?\\' for nil:NilClass")
```

...

...

You check the time... it's been over 45 seconds.

...

...maybe you shouldn't have run this in the console??

...

Another 23.7 seconds pass and you decide to `CTRL-C` your way out of there before you cause a production incident. You decide to just pull the `Error` IDs from the JIRA ticket like a pleb. Suddenly the heat wave feels even hotter.

---

But this is nagging you. I mean, what gives?? Why doesn't this method ever just do the thing it says on the tin? Sure, if we use the `.no_status` scope (`WHERE status_message IS NOT NULL`) it seems to work, but why can't we get simple text search to work on this column? Sure there are a lot (a lot = `8612441`) of rows, but I feel like I've seen text searching work before. Should we switch to [Postgres](https://www.postgresql.org/docs/13/textsearch.html)?

## Sargable & Non-sargable
Sargable is a gate keep-y portmanteau (<- also gate keep-y. A portmanteau is a word that smashes together the sounds and meaning of two words, like spoon + fork = spork) for "search argument-able." We use the term to describe the ability of the database's SQL optimizer to leverage an index. There are a few things that determine a query's sargability (not sure if that's a word), but a big one to look out for is using wildcards (`%`) when doing text searches.

Let's look at the implementation of our `where_message_like` method to see if we might be running into something like this.

```ruby
irb(main):001:0> ActiveRecord::Base.connection.to_sql(Error.where_message_like("NoMethodError: undefined method `is_approved_by_finance?\\' for nil:NilClass"))
=> "SELECT `errors`.* FROM `errors`  WHERE (message like '%NoMethodError: undefined method `is_approved_by_finance?\' for nil:NilClass%')"
```

Aha, so we have a wildcard (`%`) on either end of string in the `WHERE` clause:

```sql
'%NoMethodError: undefined method `is_approved_by_finance?\' for nil:NilClass%'
```

To understand why this is a problem, let's pretend you're the SQL query optimizer. Let's say that I ask you to find all of the words in the dictionary that contain the substring `get`:

```sql
SELECT * FROM entries WHERE entries.word LIKE '%get%'
```

You'll have to scan through _every_ word (row) in the dictionary (`entries` table) to find all of the instances:

```
...
- GETaway
- fidGETy
- veGETal
- exeGETe
- nugGETy
...
```

If, instead, I asked you to get all of the words in the dictionary that _begin_ with `get`, you could just flip to the correct page and give me all the words! In this way, the dictionary being in alphabetical order is a type of index:

```sql
SELECT * FROM entries WHERE entries.word LIKE 'get%'
```

```
...
- GETaway
- GETable
- GETting
- GETters
...
```

"But, Thomas," I hear you asking, "what if we want to do a substring search rather than search from the beginning of the string?"

That's a great question! For our `Error` scenario, that's seldom the case, but there are more intentional indexes we _could_ use to get us a more robust sub-string search, like [MySQL's `FULLTEXT`](https://dev.mysql.com/doc/refman/5.6/en/fulltext-search.html) or [Postgres' `ts_vector`](https://www.postgresql.org/docs/9.5/datatype-textsearch.html). It's worth noting that full-text indexes aren't magic, and your tables and queries have to change to support them.

For our example, we don't have these things readily at our disposal, so we'll continue with the assumption that we're searching for a substring at the _beginning_ of the column's contents.

## `TEXT` & `VARCHAR`
So now, let's see this sargable business in action by looking at the query plans!

First the non-sargable, double wildcard (`%`), query:

```ruby
irb(main):002:0> puts ActiveRecord::Base.connection.explain(Error.where_message_like("NoMethodError: undefined method `is_approved_by_finance?\\' for nil:NilClass").to_sql)
  EXPLAIN (0.5ms)  EXPLAIN SELECT `errors`.* FROM `errors` WHERE (message like '%NoMethodError: undefined method `is_approved_by_finance?\' for nil:NilClass%')
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table          | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | errors         | ALL  | NULL          | NULL | NULL    | NULL | 6739497 | Using where |
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
1 row in set (0.00 sec)
```

Then the sargable, search from the beginning of the contents, query:

```ruby
irb(main):003:0> puts ActiveRecord::Base.connection.explain(Error.where("message LIKE \'NoMethodError: undefined method `is_approved_by_finance?\\' for nil:NilClass%\'").to_sql)
  EXPLAIN (0.5ms)  EXPLAIN SELECT `errors`.* FROM `errors` WHERE (message LIKE 'NoMethodError: undefined method `is_approved_by_finance?\' for nil:NilClass%')
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table          | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | errors         | ALL  | NULL          | NULL | NULL    | NULL | 6739497 | Using where |
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
1 row in set (0.00 sec)
```

Oh crap. What gives?! They look exactly the same! Why isn't MySQL optimizing!? We sarged(?) it!

Unfortunately for us, our `message` doesn't have an index. Further, the column is a `TEXT` column, and (given its extremely varied and undefined length) if we want to add an index, MySQL [requires us to specify a _prefix length_](https://dev.mysql.com/doc/refman/8.0/en/create-index.html), which tells MySQL how much of the _beginning_ of the string should be indexed. Further further, only the InnoDB tables can be indexed this way. (Our `errors` table uses the InnoDB engine, so no problem there).

## How it looks with an index
Even though our `message` `TEXT` column doesn't have an index, our `ticket_id` column does:

```ruby
irb(main):004:0> puts ActiveRecord::Base.connection.explain('errors')
  EXPLAIN (2.6ms)  EXPLAIN errors
+---------------------+--------------+------+-----+---------+----------------+
| Field               | Type         | Null | Key | Default | Extra          |
+---------------------+--------------+------+-----+---------+----------------+
| id                  | int(11)      | NO   | PRI | NULL    | auto_increment |
| message             | text         | YES  |     | NULL    |                |
| backtrace           | text         | YES  |     | NULL    |                |
| status_message      | varchar(255) | YES  | MUL | NULL    |                |
| created_at          | datetime     | YES  |     | NULL    |                |
| updated_at          | datetime     | YES  |     | NULL    |                |
| runtime_environment | text         | YES  |     | NULL    |                |
| error_type          | varchar(255) | YES  | MUL | NULL    |                |
| ticket_id           | varchar(255) | YES  | MUL | NULL    |                |
+---------------------+--------------+------+-----+---------+----------------+
9 rows in set (0.00 sec)
```

The `ticket_id` column is of type `varchar(255)`, which means we have no problem putting an index on there. And that's exactly what we did! In our case, it uses a `MUL` (or "Multiple") key, meaning that its value is used at the beginning of a non-unique key (multiple records can have the same index).

Let's look at how our knowledge of sargable wildcard queries plays a role with this type of column.

First the non-sargable, double wildcard (`%`), query:

```ruby
irb(main):005:0> puts ActiveRecord::Base.connection.explain(Error.where('ticket_id LIKE \'%A00057440\'').to_sql)
  EXPLAIN (0.5ms)  EXPLAIN SELECT `errors`.* FROM `errors` WHERE (ticket_id LIKE '%A00057440%')
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
| id | select_type | table          | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
|  1 | SIMPLE      | errors         | ALL  | NULL          | NULL | NULL    | NULL | 8612441 | Using where |
+----+-------------+----------------+------+---------------+------+---------+------+---------+-------------+
1 row in set (0.00 sec)
```

Then the sargable, search from the beginning of the contents, query:

```ruby
irb(main):006:0> puts ActiveRecord::Base.connection.explain(Error.where('ticket_id LIKE \'%A00057440\'').to_sql)
  EXPLAIN (1.2ms)  EXPLAIN SELECT `errors`.* FROM `errors` WHERE (ticket_id LIKE 'A00057440%')
+----+-------------+----------------+-------+--------------------------------------+--------------------------------------+---------+------+------+-----------------------+
| id | select_type | table          | type  | possible_keys                        | key                                  | key_len | ref  | rows | Extra                 |
+----+-------------+----------------+-------+--------------------------------------+--------------------------------------+---------+------+------+-----------------------+
|  1 | SIMPLE      | errors         | range | index_errors_on_ticket_id            | index_errors_on_ticket_id            | 768     | NULL |  214 | Using index condition |
+----+-------------+----------------+-------+--------------------------------------+--------------------------------------+---------+------+------+-----------------------+
1 row in set (0.00 sec)
```

Aha! In the first query plan, MySQL tells us it will scan through `ALL` `8612441` rows `Using where`. The second, sargable query plan tells us that it will only need to scan through a `range` of `214` by `Using index condition`!

Wow... a single `%` can make a huge difference.

I'll leave it as an exercise for the reader to `SET profiling = 1;` to see the real cost. [See documentation here](https://dev.mysql.com/doc/refman/8.0/en/show-profile.html).

## Back on Ops
Ahhh, the sun is finally starting to set. We haven't finished (or really even begun) our investigation, but we're a little wiser about MySQL's indexing patterns.

How can we use this knowledge to make our jobs a little easier and beat the heat?

I guess the first thing to know is that `where_message_like` could take a very long time if there are no other `WHERE` conditions. This is because it's a `TEXT` column with no index; but even if it had an index, using a wildcard at the front of our search string isn't doing us any favors.

Also, it's nice to know that the `ticket_id` column _is_ indexed, and if we want to search, we can use a sargable query to get our results much faster! Having a consistent format for `ticket_id` might be something to consider; if we can deduce what the beginning of the string is, finding all of the relevant records could be super efficient!

Lastly, if we did want to index the `message` column, we have a few options:

We could migrate it from `TEXT` to `VARCHAR`. The advantage there is gaining access to an easy index, but we give up the [benefits of choosing `TEXT`](https://stackoverflow.com/questions/25300821/difference-between-varchar-and-text-in-mysq0l) in the first place.

We could use a [column prefix key](https://dev.mysql.com/doc/refman/8.0/en/create-index.html#create-index-column-prefixes) by specifying a prefix limit. That might get us some good bang for our buck if we use sargable queries. 

Or, we could invest in a [full-text index](https://dev.mysql.com/doc/refman/8.0/en/create-index.html#create-index-fulltext) and really leverage what InnoDB can do! However, this will require us to alter our table a bit more and adjust our query patterns. Whether or not this plays nice with Rails is another question we'd need to answer.

Nevertheless, it's 5:00 p.m. (4:56 p.m., but who's counting), so it's time to call it a day and grab the last few rays of sun down by the water.

Before you `⌘-Q` out of Slack, you remember something. "...didn't Brianna say that they were going to look at this issue??"

You refresh JIRA:

"Status: Done."

You give a shout out to Brianna and  `⌘-SHIFT-Q`.

