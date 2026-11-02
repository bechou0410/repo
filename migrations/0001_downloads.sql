-- One row per package, version and package manager; count is the number of downloads.
CREATE TABLE IF NOT EXISTS downloads (
  package TEXT NOT NULL,
  version TEXT NOT NULL,
  client TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (package, version, client)
);
