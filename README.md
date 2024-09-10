# equinox-evergreen-addons
Addons and tools for the Evergreen ILS

## Components

### SQL Toolkit

The SQL Tooklit is found in the directory `sql/` and contains miscellaneous
stored procedures and functions to assist with adminstering or reporting on
an Evergreen system.

The Toolkit includes:

- `eoli_addons.make_daily_new_bibs_bucket(userid)`:
   Create a new record bucket containing recently-created bib records
- `eoli_addons.count_row_referrers(table_name, record_id)`:
   Count records that refer to a specific object. Comes in two versions,
   one where the record ID is an integer and one where the record ID
   is a string.

To install, run

```
psql -U evergreen -f sql/install.sql
```
The installation can be safely re-run to update the SQL Toolkit. All stored
procedures are kept in the `eoli_addons` schema. Since the `eoli_addons` schema
is dropped and recreated during upgrades, please do not add your own functions
to that schema without providing a way to restore them.

## License

Unless otherwise indicated in a specific file, all code in this repository
is licensed under the GNU General Public License 2.0 or later.

## Copyright

Unless otherwise indicated in a specific file, all code in this repository
is copyright (c) 2024 by Equinox Open Library Initiative, Inc.
