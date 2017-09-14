# Explain Dependencies

Explains what your project's dependencies are.


## Installation

[Ruby](https://www.ruby-lang.org/en/downloads/) is required. Once it's installed run:

    gem install explain-dependencies

If you're using [Bundler](http://bundler.io/):

    gem "explain-dependencies", :group => :development

## Usage

    xdep [-ai] [-f format] [file or directory...]
      -a, --add                        Add explanations to the dependency file, if possible
      -i, --ignore-popular             Ignore popular dependencies
      -f, --format=NAME                Output format for explanations (csv or source), defaults to csv

Your dependencies must be installed in order to describe them.

### Output Formats

Explain Dependencies can output to CSV or add descriptions to the
dependency file.

CSV output will contain the following columns: Language, Name,
Version, Description, Homepage, License

Source output adds the dependency's description as a comment
directly above the line that's including it. This is not supported for
all output formats.

### Examples

Output a CSV file describing all of your project's dependencies:

    xdep

Output a CSV file describing dependencies in `package.json`:

    xdep package.json

Output a `Gemfile` with comments describing dependencies in `Gemfile`:

    bundle exec xdep -f source Gemfile

Update your project's `Gemfile` with comments describing each
dependency, ignoring well-known dependencies:

    bundle exec xdep -aif source Gemfile

## Supported Projects

* Ruby: [Bundler](http://bundler.io/v1.15/man/gemfile.5.html), [RubyGems](http://guides.rubygems.org/specification-reference/)
* Node: [npm](https://docs.npmjs.com/getting-started/using-a-package.json)

## TODO

* More dependency files
* Specify CSV columns
* Speedup describing package.json
