# News

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
