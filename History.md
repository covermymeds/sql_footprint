3.0.1 / 2021-05-12
==================

  * Remove ruby 2.3 and 2.4 from CI build. Ruby >= 2.5.0 is required for rails 6.

3.0.0 / 2021-05-12
==================

  * Changes to support Rails 6.1.
  * Fetch config for database name differently because rails removed the connection_id key from the sql.active_record notification.

1.0.0 / 2016-05-04
==================

  * Split footprint files by database name
