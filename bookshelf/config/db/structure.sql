CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `books`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `title` varchar(255),
  `author` varchar(255),
  `created_at` timestamp NOT NULL,
  `updated_at` timestamp NOT NULL
);
INSERT INTO schema_migrations (filename) VALUES
('20260410140004_create_books.rb');
