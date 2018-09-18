# Test Boosters

[![Gem Version](https://badge.fury.io/rb/semaphore_test_boosters.svg)](https://badge.fury.io/rb/semaphore_test_boosters)
[![Build Status](https://semaphoreci.com/api/v1/renderedtext/test-boosters/branches/master/badge.svg)](https://semaphoreci.com/renderedtext/test-boosters)

Auto Parallelization &mdash; runs test files in multiple jobs

- [Installation](#installation)

Test Booster basics:

  - [What are Test Boosters](#what-are-test-boosters)
  - [Split Configuration](#split-configuration)
  - [Leftover Files](#split-configuration)
  - [Altering Test Paths](#altering-test-paths)
  - [Commit Directives](#commit-directives)

Test Boosters:

  - [RSpec Booster](#rspec-booster)
  - [Cucumber Booster](#cucumber-booster)
  - [Minitest Booster](#minitest-booster)
  - [ExUnit Booster](#ex-unit-booster)
  - [GoTest Booster](#go-test-booster)

## Installation

``` bash
gem install semaphore_test_boosters
````

## What are Test Boosters

Test Boosters take your test suite and split the test files into multiple jobs.
This allows you to quickly parallelize your test suite across multiple build
machines.

As an example, let's take a look at the `rspec_booster --job 1/10` command. It
lists all the files that match the `spec/**/*_spec.rb` glob in your project,
distributes them into 10 jobs, and execute the first job.

### Split Configuration

Every test booster can load a split configuration file that helps the test
booster to make a better distribution.

For example, if you have 3 RSpec Booster jobs, and you want to run:

- `spec/a_spec.rb` and `spec/b_spec.rb` in the first job
- `spec/c_spec.rb` and `spec/d_spec.rb` in the second job
- `spec/e_spec.rb` in the third job

you should put the following in your split configuration file:

``` json
[
  { "files": ["spec/a_spec.rb", "spec/b_spec.rb"] },
  { "files": ["spec/c_spec.rb", "spec/d_spec.rb"] },
  { "files": ["spec/e_spec.rb"] }
]
```

Semaphore uses Split configurations to split your test files based on their
durations in the previous builds.

### Leftover Files

Files that are part of your test suite, but are not in the split
configuration file, are called "leftover files". These files will be distributed
based on their file size in a round robin fashion across your jobs.

For example, if you have the following in your split configuration:

``` json
[
  { "files": ["spec/a_spec.rb"] }
  { "files": ["spec/b_spec.rb"] }
  { "files": ["spec/c_spec.rb"] }
]
```

and the following files in your spec directory:

``` bash
# Files from split configuration ↓

spec/a_spec.rb
spec/b_spec.rb
spec/c_spec.rb

# Leftover files ↓

spec/d_spec.rb
spec/e_spec.rb
```

When you run the `rspec_booster --job 1/3` command, the files from the
configuration's first job and some leftover files will be executed.

``` bash
rspec_booster --job 1/3

# => runs: bundle exec rspec spec/a_spec.rb spec/d_spec.rb
```

Booster will distribute your leftover files uniformly across jobs.

### Altering Test Paths

There is always a trade-off between testing time and test thoroughness.
To make this more flexible, test boosters have the ability to dynamically assign test paths based on environment variables.
There are two environment variables that need to be set in order to do this:

`REGRESSION_PATH` is the path that the test boosters will ignore unless a full test suite is being run.

`EXEMPT_BRANCHES` contains a csv list of branches that will always run a full test suite- i.e. they will ignore the REGRESSION_PATH exclusion. This is very useful for branches like master, release or develop where thoroughness is more important than execution time.

An example use of this would be a company that doesn't want their Capybara tests (all located in spec/features/) to run unless necessary. This way, Semaphore's build time can be reduced on all branches that don't need total build-accuracy. In this case, the company could use Semaphore's environment variable setter to enable:

`REGRESSION_PATH=spec/features/`

`EXEMPT_BRANCHES=master,release,develop`

Additionally, the REGRESSION_PATH will be ignored if the build was manually created- meaning it was created by someone clicking 'Rebuild last revision' on Semaphore.

### Commit Directives

Further, test execution can be customised by commit directives. Commit directives are strings pulled from the most recent git commit. There are seven recognised commit directives:

- [ci skip]
  - Semaphore will not process this commit, will not create a build revision of it.
- [cukes off]
  - Cucumber tests wont run. This directive tells Semaphore not to execute any cucumber test files.
- [specs off]
  - Specs wont run. Same purpose as cukes off but for specs.
- [minitest off]
  - Minitest wont run.
- [exunit off]
  - ExUnit tests wont run.
- [gotest off]
  - GoTests wont run.
- [regression]
  - The REGRESSION_PATH is ignored, a full test-suite is run for this build. Useful if you want to be certain your code is green before pushing to release, master etc.

These commit directives can be stacked as much as you would like, but be wary of using conflicting directives that might have unexpected behaviour.
For example if `[regression]` and `[ci skip]` are both passed, ci skip will trump and no build revision will be made.

In an example where a developer did not want their specs to run on a certain commit, they could use the commit message:

``` git
Misc changes to cucumber tests.

Altered the setup file for our cucumber tests, shouldn't affect any of the specs.
[specs off]
```

Note that it does not matter where the `[command]` is in the commit message.

## RSpec Booster

The `rspec_booster` loads all the files that match the `spec/**/*_spec.rb`
pattern and uses the `~/rspec_split_configuration.json` file to parallelize your
test suite.

Example of running job 4 out of 32 jobs:

``` bash
rspec_booster --job 4/32
```

Under the hood, the RSpec Booster uses the following command:

``` bash
bundle exec rspec --format documentation --format json --out /home/<user>/rspec_report.json <file_list>
```

Optionally, you can pass additional RSpec flags with the `TB_RSPEC_OPTIONS`
environment variable. You can also set a RSpec formatter with the `TB_RSPEC_FORMATTER` environment variable.
Default formatter is `documentation`.


Example:
``` bash
TB_RSPEC_OPTIONS='--fail-fast=3' TB_RSPEC_FORMATTER=Fivemat rspec_booster --job 4/32

# will execute:
bundle exec rspec --fail-fast=3 --format Fivemat --format json --out /home/<user>/rspec_report.json <file_list>
```

## Cucumber Booster

The `cucumber_booster` loads all the files that match the `features/**/*.feature`
pattern and uses the `~/cucumber_split_configuration.json` file to parallelize
your test suite.

Example of running job 4 out of 32 jobs:

``` bash
cucumber_booster --job 4/32
```

Under the hood, the Cucumber Booster uses the following command:

``` bash
bundle exec cucumber <file_list>
```

## Minitest Booster

The `minitest_booster` loads all the files that match the `test/**/*_test.rb`
pattern and uses the `~/minitest_split_configuration.json` file to parallelize
your test suite.

Example of running job 4 out of 32 jobs:

``` bash
minitest_booster --job 4/32
```

Under the hood, the Minitest Booster uses the following command:

``` bash
ruby -e 'ARGV.each { |f| require ".#{f}" }' <file_list>
```

## ExUnit Booster

The `ex_unit_booster` loads all the files that match the `test/**/*_test.exs`
pattern and uses the `~/ex_unit_split_configuration.json` file to parallelize
your test suite.

Example of running job 4 out of 32 jobs:

``` bash
ex_unit_booster --job 4/32
```

Under the hood, the ExUnit Booster uses the following command:

``` bash
mix test <file_list>
```

## Go Test Booster

The `go_test_booster` loads all the files that match the `**/*_test.go`
pattern and uses the `~/go_test_split_configuration.json` file to parallelize
your test suite.

Example of running job 4 out of 32 jobs:

``` bash
go_test_booster --job 4/32
```

Under the hood, the Go Test Booster uses the following command:

``` bash
go test <file_list>
```

## Development

### Integration testing

For integration tests we use test repositories that are located in
<https://github.com/renderedtext/test-boosters-tests.git>.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/renderedtext/test-boosters.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
