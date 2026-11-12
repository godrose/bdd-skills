# Records export

Export downloads the records as a CSV file.

To see the file a user would download, run `node src/show.js`. It uses `data/records.json` and the filter in `data/filter.json`.

The folder `data/` holds two filters to try: `filter-none.json` matches no record and `filter-empty.json` has no condition.

To try other data, give files under `data/` as arguments: `node src/show.js data/<records file> data/<filter file>`.
