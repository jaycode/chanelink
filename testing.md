[back to main readme](https://github.com/jaycode/chanelink)

# Testing Chanelink App

Chanelink app is going to be developed with full TDD fashion. This is a decision that we made to
ensure the finished product can be as robust as possible, and making the app itself as adaptive as
possible.

## When to test?

Here are some basic guidelines:

1. Write test code as you are developing new channels.
2. Write test code when you find bugs to properly reproduce them, then fix the bugs (IN THAT ORDER).
3. Write test code when you are adding new features.

In other words, write test code whenever you are doing anything at all to the app. In this document,
let us go through different scenario to find out what kinds of test code are appropriate for them.

## Write test code as you are developing new channels

[Capybara](https://github.com/jnicklas/capybara). Integration test with Capybara allows you to test out
view files in your app. BUT it does not allow you to read app's session; you need standard integration test
for that.

Integration test, `test/integration/channels/{channel name}`. Add each feature needed for a channel
there. Not all features are owned by all channels. {example}.

```
bundle exec rake test:integration

# Or to run specific test files:
bundle exec rake test:integration TEST=test/integration/sessions_controller_test.rb
# I know that is weird, you need to actually specify whether that file is located
# under ":units", ":functionals", or ":integration", otherwise your test will run
# three times.
```

Read more about running specific tests [here](http://flavio.castelli.name/2010/05/28/rails_execute_single_test/)

### Using Cookies in Capybara + Rails

## Write test code when fixing bugs

Integration testing without Capybara could be a good start to fix session-related bugs that happens when
a series of actions are done across several controllers.

If the bug is tied only within a single controller, functional test is the perfect way to handle this.
Functional test code in Rails are tightly coupled with controllers in the app. To run functional test, do:

```
bundle exec rake test:functionals
```

Occassionally, If the bug happens within a model, or happens outside of models, views, and controllers, 
e.g. a problem with delayed job, or one of the libraries used may have problems, you may use Unit test
for that. To run unit tests, here is the command:

```
bundle exec rake test:units
```

## Write test code when you are adding new features

`test/unit/property_channel_test.rb` is a good example on how a test code is created to test out behaviors of a
new feature in the model `property_channel`.

## Run all of your test code when you are about to deploy!

This is very important. I have seen avoidable catastrophes happen simply because the test code were not
being run before deploying the app into production server.

To run all tests, do the following:

```
bundle exec rake test
```

## Using cookies in test code

### Without Capybara

Instead of `cookies[:something]`, use `@request.cookie_jar[:something]`, because the latter allows you
to use permanent and signed featuress (i.e. it is an object instead of hash).

### With Capybara

Capybara has access to cookies, but not sessions. To access it use following code:

```
cookies = Capybara.current_session.driver.request.cookies
```

## Sample data in test code

We do not run seeds.rb in testing. Instead, we add required data in `fixtures/*.yml` files.

## References

Learn about Rails testing [here](http://guides.rubyonrails.org/v3.2.21/testing.html).

A great reference for Capybara by far is their github page, available [here](https://github.com/jnicklas/capybara).

We use fixtures to help us with testing, learn about them [here](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html).