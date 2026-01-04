-- Każdy członek zespołu uruchamia TEN plik lokalnie i wpisuje własne hasło.
-- Nie commituj prawdziwych haseł do repo!

CREATE USER IF NOT EXISTS 'aibtc_user'@'localhost' IDENTIFIED BY 'WSTAW_TU_SWOJE_HASLO';
GRANT ALL PRIVILEGES ON aibtcquantlandia.* TO 'aibtc_user'@'localhost';
FLUSH PRIVILEGES;
