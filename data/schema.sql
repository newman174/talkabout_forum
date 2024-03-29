CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(30) UNIQUE NOT NULL,
  password CHAR(60) NOT NULL,
  join_date DATE NOT NULL DEFAULT NOW()
);

CREATE TABLE topics (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  subject VARCHAR(100) NOT NULL,
  body TEXT NOT NULL,
  time_posted TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE replies (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  topic_id INT NOT NULL REFERENCES topics (id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  time_posted TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
