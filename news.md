# News

## 1.0.2 - 2018-05-03

### Improvements

  * Split file for CSV::VERSION

  * Code cleanup: Split csv.rb into a more manageable structure
    [GitHub#19][Patch by Espartaco Palma]
    [GitHub#20][Patch by Steven Daniels]

  * Use CSV::MalformedCSVError for invalid encoding line
    [GitHub#26][Reported by deepj]

  * Support implicit Row <-> Array conversion
    [Bug #10013][ruby-core:63582][Reported by Dawid Janczak]

  * Update class docs
    [GitHub#32][Patch by zverok]

  * Add `Row#each_pair`
    [GitHub#33][Patch by zverok]

  * Improve CSV performance
    [GitHub#30][Patch by Watson]

  * Add :nil_value and :empty_value option

### Fixes

  * Fix a bug that "bom|utf-8" doesn't work
    [GitHub#23][Reported by Pavel Lobashov]

  * `CSV::Row#to_h`, `#to_hash`: uses the same value as `Row#[]`
    [Bug #14482][Reported by tomoya ishida]

  * Make row separator detection more robust
    [GitHub#25][Reported by deepj]

  * Fix a bug that too much separator when col_sep is `" "`
    [Bug #8784][ruby-core:63582][Reported by Sylvain Laperche]

### Thanks

  * Espartaco Palma

  * Steven Daniels

  * deepj

  * Dawid Janczak

  * zverok

  * Watson

  * Pavel Lobashov

  * tomoya ishida

  * Sylvain Laperche

  * Ryunosuke Sato

## 1.0.1 - 2018-02-09

### Improvements

  * `CSV::Table#delete`: Added bulk delete support. You can delete
    multiple rows and columns at once.
    [GitHub#4][Patch by Vladislav]

  * Updated Gem description.
    [GitHub#11][Patch by Marcus Stollsteimer]

  * Code cleanup.
    [GitHub#12][Patch by Marcus Stollsteimer]
    [GitHub#14][Patch by Steven Daniels]
    [GitHub#18][Patch by takkanm]

  * `CSV::Table#dig`: Added.
    [GitHub#15][Patch by Tomohiro Ogoke]

  * `CSV::Row#dig`: Added.
    [GitHub#15][Patch by Tomohiro Ogoke]

  * Added ISO 8601 support to date time converter.
    [GitHub#16]

### Fixes

  * Fixed wrong `CSV::VERSION`.
    [GitHub#10][Reported by Marcus Stollsteimer]

  * `CSV.generate`: Fixed a regression bug that `String` argument is
    ignored.
    [GitHub#13][Patch by pavel]

### Thanks

  * Vladislav

  * Marcus Stollsteimer

  * Steven Daniels

  * takkanm

  * Tomohiro Ogoke

  * pavel
