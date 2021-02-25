---
title: SQL Injection Overview
Author: Thomas Countz
layout: post
tags: ["security", "ruby", "java", "elixir", "database", "sql"]
---

![](/assets/images/sql_injection/sql-injection-owasp.png)

An SQL Injection **occurs when untrusted input is used directly in the construction of an SQL query**. This attack is commonly executed by introducing a meta character \(such as a comment\) into a data plane in such a way that allows an attacker to add commands to the control plane. Essentially, when building a SQL query from user input, an attacker can insert SQL instructions that cause the application to behave in unintended ways.

> SQL Injection flaws are introduced when software developers create dynamic database queries that include user supplied input.
>
> —[OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)

## Authentication Form Example

Let's take a login form with that requires a user enter a username and password to log in.

![](/assets/images/sql_injection/login-long-password.png)

In the happy-path case, a user enters in their details, presses "Login," and a request is sent to a server where we take what the user enters, search the database for that user, and then log that user into our web application.

```ruby
# SQL Injection Vulnerable Pseudocode
# -- snip --

let user = ORM.query(
  "SELECT * 
    FROM users 
    WHERE username = '#{params['username']}'
    AND password = '#{params['password']}';"
).execute()[0];

# -- snip -- 

log_in_user(user)
```

Using a tool like [SQL Fiddle](http://sqlfiddle.com), you can see how a query like this will behave in PostgreSQL 9.6. Here's is the schema and seed data for our example:

```sql
CREATE TABLE users(
   id        INT PRIMARY KEY   NOT NULL,
   username  VARCHAR           NOT NULL,
   password  VARCHAR           NOT NULL
);

INSERT INTO users (id, username, password) 
VALUES (1, 'sarah', 'good-password');

INSERT INTO users (id, username, password) 
VALUES (2, 'thomas', 'password123');

INSERT INTO users (id, username, password) 
VALUES (3, 'patrice', md5('palm-kumquat-futon-padden'));

```

After the user submits the username:

```text
thomas
```

and password:

```text
password123
```

 the resulting query will look like this:

```sql
SELECT * 
FROM users 
WHERE username='thomas' AND password='password123';
```

and the following results will be returned:

```text
| id | username |    password |
|----|----------|-------------|
|  2 |  tcountz | password123 |
```

As expected, our backend code then takes this result, and calls the `log_in_user()` function which authorizes the user to access certain parts of the application.

### Authentication Attack

The vulnerability here will allow an attacker to log in as any user.

Because user input is interpolated directly into the SQL query, we can have the server execute arbitrary SQL statements. Let's take a look at an example that would allow us to log into any user, given we have their username.

After the user submits the username:

```text
patrice'; --
```

and a blank \(or arbitrary\) password, the resulting query looks like this

```sql
SELECT * 
FROM users 
WHERE username='patrice'; --' AND password='<anything>'
```

and the results:

```text
| id | username |                         password |
|----|----------|----------------------------------|
|  3 |  patrice | 26e9053a783f364d949b4e400dd2f68c |
```

Now, our application, again, takes the 0th results \(this time the user `patrice`\) and logs them in.

#### What Happened?

Even though we hashed Patrice's password, our query was vulnerable to interpreting the `'`, `;`, and `--` PostgreSQL meta characters.

Firstly, the single quote: `'`, ends the string \(or `VARCHAR`\) that we're searching for; in this case the username `patrice`. Next, the semi-colon `;` represents the end of the SQL statement. Finally, the `--` represents a comment and tells PostgreSQL to ignore everything that comes after.

This effectively makes our query look like this:

```sql
SELECT * 
FROM users 
WHERE username='patrice';
```

Which, as we've seen, and as we expect, returns the `patrice` user and logs them in. Now our attacker has been authenticated and has access to Patrice's account!

This combination: `'; --`, and others like it, show up often in SQL injection attacks and it works by prematurely ending a SQL statement.

### Data Destruction Attack

In the example above, the 0th row of the results returned from the query will be passed into the `log_in_user()` function, but the scope of this attack vector isn't limited to logging in. 

As an example of how we can attack the server to execute _any_ SQL, take this example where we destroy the `users` table.

If we enter a username of:

```text
'; DROP TABLE users; --
```

and a blank \(or arbitrary\) password, the resulting query looks like this

```sql
SELECT * 
FROM users 
WHERE username=''; DROP TABLE users; --' AND password='<anything>'
```

The user-facing effect of this query might not tell us exactly what has happened, but a developer might see something like this show up in the logs:

```text
ERROR: relation "users" does not exist
```

#### What Happened?

Similar to the first attack, we've cut the original query short and this time, we've injected our own query to drop the `users` table.

## Prevention

### Parameterized Queries

> The use of prepared statements with variable binding \(aka parameterized queries\) is how all developers should first be taught how to write database queries.
>
>  Parameterized queries force the developer to first define all the SQL code, and then pass in each parameter to the query later. This coding style allows the database to distinguish between code and data, regardless of what user input is supplied.
>
> — [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)

Our code was vulnerable because we use string interpolation to build an SQL statement directly from user input. Instead, we should "parameterize" our query by using whatever tools our language gives us to separate the data plane \(input\) from the control plane \(SQL\). This is the idea of using variable binding \(placing user input into a type of variable\) with prepared statements \(the rest of the SQL that we don't want the user to be able to alter\).

The way to code this varies depending on the language you're working with, so check out the OWASP SQL Injection Prevention Cheat Sheet section on [parameterized queries](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.md#defense-option-1-prepared-statements-with-parameterized-queries).

### Other Defenses

Another defense against SQL injection are stored procedures, which are predefined SQL statements stored in the data table. These procedures can have parameters and can effectively be similar to constructs from different languages. Read more [here](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.md#defense-option-2-stored-procedures).

To read more about allow-listing or escaping user input, see the rest of the [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html).

### Next Steps

* Research SQL injection prevention for your ORM/database
  * e.g. [https://guides.rubyonrails.org/security.html\#sql-injection](https://guides.rubyonrails.org/security.html#sql-injection)
* Aim to separate queries and data \(parameterized queries\)
  * e.g. [https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Query\_Parameterization\_Cheat\_Sheet.md](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Query_Parameterization_Cheat_Sheet.md)
* Consider SQL Injection when reviewing code

### Code Review

* Aim to validate user input by testing type, length, format, and range.
* Avoid building SQL statements directly from user input.
* Implement multiple layers of validation. 
* Avoid concatenating user input that is not validated; this is the primary point of entry for script injection.
* You should review all code that calls execute\(\), exe\(\), and any SQL calls or commands that can call out outside resources or the command line.

## Example Code Snippets

### Ruby/ActiveRecord

```ruby
# SQL Injection Vulnerable Ruby/ActiveRecord
# -- snip --

user = User.where(
    "username = #{params[:username]} AND " \
    "password = #{params[:password]}"
).first

# -- snip --
```

```ruby
# SQL Injection Safe Ruby/ActiveRecord
# -- snip --

user = User.where(
    username: params[:username], password: params[:password]
).first

# -- snip --
```

### Elixir/Ecto

```elixir
# SQL Injection Vulnerable Elixir/Ecto
# -- snip --

query = """
  SELECT *
  FROM users
  WHERE username = \'#{params["username"]}\'
  AND password = \'#{params["pasword"]}\';
"""

user = Ecto.Adapters.SQL.query!(
    MyApp.Repo, query, []
)[:rows][0]

# -- snip --
```

```elixir
# SQL Injection Safe Elixir/Ecto
# -- snip --

query = """
  SELECT * 
  FROM users 
  WHERE username = $1 
  AND password = $2;
"""

user = Ecto.Adapters.SQL.query!(
    MyApp.Repo, query, params["username"], params["password"]
)[:rows][0]

# -- snip --
```

### Java

```java
// SQL Injection Vulnerable Java
// -- snip --

String username = request.getParameter("username");
String password = request.getParameter("password");

String query = "SELECT * FROM users WHERE username = "
    + username + " AND password = " + password + ";";

Statement statement = connection.createStatement();
Object user = statement.executeQuery(query).getObject(0);

// -- snip --
```

```java
// SQL Injection Safe Java
// -- snip --

String username = request.getParameter("username");
String password = request.getParameter("password");

String query = "SELECT * FROM users WHERE username = ? AND password = ?";
PreparedStatement pstmt = connection.prepareStatement(query);
pstmt.setString( 1, username);
pstmt.setString( 2, password);

Object user = pstmt.executeQuery().getObject(0);

// -- snip --
```

## Resources

* [https://github.com/OWASP/railsgoat/wiki/R5-A1-SQL-Injection-Concatentation](https://github.com/OWASP/railsgoat/wiki/R5-A1-SQL-Injection-Concatentation)
* [https://cheatsheetseries.owasp.org/cheatsheets/SQL\_Injection\_Prevention\_Cheat\_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
* [https://www.websec.ca/kb/sql\_injection](https://www.websec.ca/kb/sql_injection)
* [https://owasp.org/www-community/attacks/SQL\_Injection](https://owasp.org/www-community/attacks/SQL_Injection)
* [https://www.websec.ca/kb/sql\_injection](https://www.websec.ca/kb/sql_injection)

![https://xkcd.com/327/](/assets/images/sql_injection/exploits_of_a_mom.png)


