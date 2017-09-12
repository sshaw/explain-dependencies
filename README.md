# Explain Dependencies

Explains what your project's dependencies are.

## Usage

    xdep [-ai] [-f format] [file or directory...]
      -a, --add                        Add explanations to the dependency file, if possible
      -i, --ignore-popular             Ignore popular dependencies
      -f, --format=NAME                Output format for explanations (csv or source), defaults to csv

### Examples

Output a CSV file describing all of your project's dependencies:

    xdep

Output a CSV file describing dependencies in `package.json`:

    xdep package.json

Output a `Gemfile` with comments describing dependencies in `Gemfile`:

    xdep -f source Gemfile

Update your project's `Gemfile` with comments describing each
dependency, ignoring well-known dependencies:

    xdep -aif source Gemfile

## Supported Projects

* Ruby: Gemfile, gemspec
* Node: package.json

## TODO

* More dependency files
