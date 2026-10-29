import mysql.connector

# PL symbols fix dla konsoli Windows/Docker
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Konfiguracja
DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "root",  # Twoje hasło
    "database": "aibtcquantlandia",
    "port": 3306
}

# Lista wszystkich tabel do wyczyszczenia
tables_to_clean = [
    "visits", "tickets", "guests", "attraction_sessions", "attraction_failures",
    "attraction_inspections", "attractions", "attraction_types", "session_modes",
    "shop_sale_items", "shop_sales", "shop_inventory_movements", "shop_price_list",
    "shop_products", "product_categories", "operating_costs", "financial_transactions",
    "payment_methods", "cost_categories", "employee_salary_history", "employees",
    "positions", "partner_contracts", "partners", "planned_investments",
    "investment_milestones", "incidents", "policy_coverages", "insurance_policies",
    "unpleasant_event_types", "policy_types", "insurers", "channels", "ticket_types",
    "ticket_price_list"
]

print("--- ROZPOCZYNAM CZYSZCZENIE BAZY ---")
try:
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # Wyłączamy sprawdzanie kluczy, żeby móc usuwać bez błędów
    cursor.execute("SET FOREIGN_KEY_CHECKS=0;")

    for table in tables_to_clean:
        try:
            cursor.execute(f"TRUNCATE TABLE {table}")
            print(f"✅ Wyczyszczono tabelę: {table}")
        except mysql.connector.Error as err:
            # Ignorujemy błąd, jeśli tabela jeszcze nie istnieje
            print(f"Problem z tabelą {table}: {err}")

    cursor.execute("SET FOREIGN_KEY_CHECKS=1;")
    conn.close()
    print("\nBAZA JEST CZYSTA I GOTOWA!")

except mysql.connector.Error as err:
    print(f'BŁĄD POŁĄCZENIA: {err}")