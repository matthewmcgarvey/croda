-- +micrate Up
CREATE TABLE todos(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task TEXT NOT NULL,
  completed_at TEXT
);


-- +micrate Down
DROP TABLE todos;
