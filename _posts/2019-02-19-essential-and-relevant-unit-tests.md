---
title: "Essential & Relevant: A Unit Test Balancing Act"
author: Thomas Countz
layout: post
tags: ["testing", "process"]
featured: true
---
[Originally Published on 8th Light's Blog](https://8thlight.com/blog/thomas-countz/2019/02/19/essential-and-relevant-unit-tests.html)

I have never been a fan of "[DRYing](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)," out unit tests (i.e., abstracting duplicated test setup). I have always preferred to keep all of my test setup inside each individual test, and I opined about how this made my test suite more readable, isolated, and consistent; despite all of the duplication. I've never been good at articulating _why_ I preferred to do things this way, but I felt that it was better than the alternative: a test suite full of setup methods that forced me to scan many lines of code to try to understand how the tests work.

Then, I read [xUnit Test Patterns](https://www.amazon.com/xUnit-Test-Patterns-Refactoring-Code/dp/0131495054/) by Gerard Meszarso. In his book, he codified some of the most profound formulas for writing unit tests. Of them all, the most well-known is probably [The Four-Phase Test](http://xunitpatterns.com/Four%20Phase%20Test.html). Later disseminated as a distilled variant, ["Arrange, Act, Assert"](http://wiki.c2.com/?ArrangeActAssert) (and its BDD variant ["Given, When, Then"](https://martinfowler.com/bliki/GivenWhenThen.html)), the core of it remains the same: all unit tests, in all programming languages, can take the following form:

```
test do
  setup
  exercise
  verify
  teardown
end
```

In the **setup** step, we instantiate our [system under test](http://xunitpatterns.com/SUT.html), or SUT, as well as the _minimum number of dependencies_ it requires to ensure it is in the correct state:

```
user = User.new(first_name: "John", last_name: "Doe")
```

In the **exercise** step, we execute whatever behavior we want to verify, often a method on our subject, or a function we're passing our subject into:

```
result = user.full_name()
```

  In the **verify** step, we assert that the result of the exercise step matches our expectation:

```
assert(result == "John Doe")
```

  Finally, in the **teardown** step, we restore our system to its pre-test state. This is _usually_ taken care of by the language or framework we're using to write our tests.

  All together, our test ends up like so:

```
// Example 1
...
  describe("User#full_name") do
    it("returns the full name of the user") do
      user = User.new(first_name: "John", last_name: "Doe")
      result = user.full_name()
      assert(result == "John Doe")
    end
  end
...
```

  It's in the "setup" step where we want to establish only the **essential & relevant** information needed throughout the test. Example 1 demonstrates this: we're verifying that a user's full name is the concatenation of their first and last, therefore, including their first and last name explicitly within the test setup is both essential & relevant.

  In Meszaro's book, he writes about the testing anti-pattern, called the [Obscure Test](http://xunitpatterns.com/Obscure%20Test.html), which addresses the imbalance between what is essential and what is relevant to our test setup.

## Non-Essential & Irrelevant

  As an example of **non-essential & irrelevant** test setup, we could tweak our original assertion like this:

```
// Example 2
...
  describe("User#is_logged_in?") do
    it("returns false by default") do
      user = User.new(first_name: "John", last_name: "Doe")
      result = user.is_logged_in?()
      assertFalse(result)
    end
  end
...
```

  Here, instead of testing `user.full_name()` as the concatenation of `first_name` and `last_name`, we're testing that the user returned by `User.new()` responds to the `is_logged_in?()` message with `false`.

  Is having a `first_name` and `last_name` *relevant* to  `is_logged_in?()`? Probably not, but perhaps a user is only valid with a `first_name` and `last_name`, which is what makes that setup *essential* to the test. In this case, the only *essential & relevant* setup we need explicitly in our test is a valid user who is not logged in.

  Having this irrelevant setup makes for an Obscure Test of the [Irrelevant Information](http://xunitpatterns.com/Obscure%20Test.html#Irrelevant%20Information) variety.

  > ...Irrelevant Test can also occur because we make visible all the data the test needs to execute rather than focusing on the data the test needs to be understood. When writing tests, the path of least resistance is to use whatever methods are available (on the SUT and other objects) and to fill in all the parameters with values whether or not they are relevant to the test.
  >
  > -*[xUnit Test Patterns](https://www.amazon.com/xUnit-Test-Patterns-Refactoring-Code/dp/0131495054/)*

  We fix this by extracting a setup function/factory method:

```
// Example 3
...
  describe("User#is_logged_in?") do
    it("returns false by default") do
      user = valid_user()  // setup function
      result = user.is_logged_in?()
      assertFalse(result)
    end
  end
...
```

  The relevant information is here by way of the method name, and the essential setup is on the other side of the `valid_user()` method.

## Essential But Irrelevant

  Assuming there are a lot tests with similar setup, it's common to pull duplicated setup code into a setup function like the example above. This is also the solution to writing tests which have a verbose setup, and it helps us to ensure that we don't include any **essential but irrelevant** information in our tests:

```
// Example 4
...
  describe("User#full_name") do
    it("returns the full name of the user") do
      user: User.new(
          first_name"" "John"
          last_name: "Doe"
          street_address: "1000 Broadway Ave"
          city: "New York"
          state: "New York"
          zip_code: "11111"
          phone_number: "555555555"
          )
      result = user.full_name()
      assert(result == "John Doe")
    end
  end
...
```

  In this case, it may be *essential* to instantiate a valid user with a `first_name`, `last_name`, `street_address`, etc., but some of it is *irrelevant* to our assertion!

  Like in Example 1, we're asserting against `user.full_name()`, and we established that including the `first_name` and `last_name` in the setup was in fact relevant to our test. However, if we used the `valid_user()` setup function from Example 2 here, our setup would not contain all of the _relevant_ information:

```
// Example 5
...
  describe("User#full_name") do
    it("returns the full name of the user") do
      user = valid_user() // setup function
      sult = user.full_name()
      assert(result == "John Doe")
    end
  end
...
```

  This type of Obscure Test is called [Mystery Guest](http://xunitpatterns.com/Obscure%20Test.html#Mystery%20Guest).

  > When either the fixture setup and/or the result verification part of a test depends on information that is not visible within the test and the test reader finds it difficult to understand the behavior that is being verified without first having to find and inspect the external information, we have a *Mystery Guest* on our hands.
  >
  > -*[xUnit Test Patterns](https://www.amazon.com/xUnit-Test-Patterns-Refactoring-Code/dp/0131495054/)*

  This is a case where there is *essential* & *relevant* information missing from the test. The solutions here are to 1) create an explicitly named setup function that returns the user we need, 2) create a setup function that returns a mutable user that we can update before our assertion, or 3) alter our setup function to accept parameters:

```
// Example 6
...
describe("User#full_name") do
  it("returns the full name of the user") do
    user = valid_user(first_name: "John", last_name: "Doe")  // new setup function
    sult = user.full_name()
    assert(result == "John Doe")
  end
end
...
```

  This is called a [Parameterized Creation Method](http://xunitpatterns.com/Creation%20Method.html#Parameterized%20Creation%20Method) and we use it to execute all of the **essential but irrelevant** steps for setting up our test. With it, we're able to keep our test setup DRY by creating a reusable method that keeps *essential* information inline.

  ------

  When judging when to DRY our unit tests, I've found it important to consider what is **essential** for our setup vs **relevant** to our test reader. There are thousands of pages more about what makes good unit tests, and I find this topic particularly nascent as the focus begins to shift from "_why_ should we TDD" to "_how_ do we TDD well." Being able to articulate what is **essential & relevant** to a test is the key to finding the balance between people like me, who always opposed DRY unit tests, to people who prefer to keep things tidy. There are smells in both directions, but **essential & relevant** is the middle ground.

