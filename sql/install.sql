/*
 * Copyright (C) 2024 Equinox Open Library Initiative, Inc.
 *
 * Author: Galen Charlton <gmc@equinoxOLI.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

DROP SCHEMA IF EXISTS eoli_addons CASCADE;

CREATE SCHEMA eoli_addons;

CREATE OR REPLACE FUNCTION eoli_addons.make_daily_new_bibs_bucket(userid INT) RETURNS VOID AS $func$
DECLARE
    bib_count INTEGER;
    dow INTEGER;
    bucket_name TEXT;
    start_date DATE;
    end_date DATE;
    bucket_id container.biblio_record_entry_bucket.id%TYPE;
BEGIN
    SELECT EXTRACT(dow FROM NOW()) INTO dow;
    RAISE NOTICE 'dow IS % ', dow;
    IF dow = 6 OR dow = 7 THEN
        RAISE NOTICE 'Refusing to create a bucket on Saturday or Sunday';
        RETURN;
    END IF;
    IF dow = 1 THEN
        -- if it's Monday, grab the new bibs created Friday-Sunday
        start_date = NOW()::DATE - 3;
        end_date = NOW()::DATE - 1;
        bucket_name = 'New bibs added from ' || start_date || ' to ' || end_date;
    ELSE
        start_date = NOW()::DATE - 1;
        end_date = NOW()::DATE - 1;
        bucket_name = 'New bibs added on ' || start_date;
    END IF;
    SELECT COUNT(*) INTO bib_count
        FROM biblio.record_entry
        WHERE NOT deleted
        AND create_date::DATE >= start_date
        AND create_date::DATE <= end_date;
    RAISE NOTICE 'count is %', bib_count;
    IF bib_count = 0 THEN
        RAISE NOTICE 'No bibs added during the time period, so no bucket created';
        RETURN;
    END IF;
    INSERT INTO container.biblio_record_entry_bucket (owner, name, btype)
        VALUES (userid, bucket_name, 'staff_client')
        RETURNING id INTO bucket_id;
    RAISE NOTICE 'Created bucket %', bucket_id;
    INSERT INTO container.biblio_record_entry_bucket_item (bucket, target_biblio_record_entry,pos)
        SELECT bucket_id, id, ROW_NUMBER() OVER (ORDER BY id)
        FROM biblio.record_entry
        WHERE NOT deleted
        AND create_date::DATE >= start_date
        AND create_date::DATE <= end_date;            
END
$func$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eoli_addons.make_daily_new_bibs_bucket(INT) IS $$Create a new record bucket containing recently-created bib records.

In particular, when run on Tuesday through Friday, it will include
the records created the previous day. When run on Monday, it will
include the records created on Friday through Sunday. It will not
create buckets if run on Saturday or Sunday.

Records that were deleted since their creation will not be included
in the bucket.

Arguments:

  1. The ID of the user who should own the bucket.

Returns: nothing
$$;
