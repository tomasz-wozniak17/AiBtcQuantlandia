-- Każdy członek zespołu uruchamia TEN plik lokalnie i wpisuje własne hasło.
-- Nie commituj prawdziwych haseł do repo!

CREATE USER IF NOT EXISTS 'root' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON aibtcquantlandia.* TO 'root';
FLUSH PRIVILEGES;
