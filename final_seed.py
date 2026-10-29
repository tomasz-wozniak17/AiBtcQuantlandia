import os
import csv
import random
import mysql.connector
from datetime import datetime, timedelta, date, time
from faker import Faker
import unicodedata
import sys, io

# PL symbols fix dla konsoli Windows/Docker
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# --- KONFIGURACJA ---
DB_HOST = "127.0.0.1"
DB_PORT = 3306
DB_USER = "root"
DB_PASS = "root"
DB_NAME = "aibtcquantlandia"
OUTPUT_DIR = "seed_data_real"

# Zakres symulacji
START_DATE = date(2021, 1, 1)
END_DATE = date(2023, 12, 31)

fake = Faker("pl_PL")
Faker.seed(999)
random.seed(999)


def ensure_dir(d):
    os.makedirs(d, exist_ok=True)


def write_csv(filename, rows, header):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if header: w.writerow(header)
        w.writerows(rows)


def fmt_dt(dt): return dt.strftime("%Y-%m-%d %H:%M:%S")


def fmt_d(d): return d.strftime("%Y-%m-%d")


def normalize_str(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn').lower()


def gen_phone():
    prefixes = [501, 502, 503, 510, 601, 603, 660, 691, 721, 880]
    prefix = random.choice(prefixes)
    suffix = random.randint(100000, 999999)
    return f"{prefix}{suffix}"


def gen_email(first, last):
    domains = ["gmail.com", "wp.pl", "onet.pl", "interia.pl", "o2.pl", "yahoo.com"]
    f = normalize_str(first)
    l = normalize_str(last)
    pattern = random.choice([f"{f}.{l}", f"{f[0]}.{l}", f"{l}.{f}"])
    if random.random() < 0.4:
        pattern += str(random.randint(1, 99))
    return f"{pattern}@{random.choice(domains)}"


# ==========================================
# GENEROWANIE PEŁNYCH DANYCH
# ==========================================
def gen_real_data():
    print(f"--- Generowanie PEŁNYCH danych (Sklepy + Wiek + Koszty) do {OUTPUT_DIR}... ---")
    ensure_dir(OUTPUT_DIR)

    # 1. SŁOWNIKI
    channels = [(1, "Kasa Biletowa"), (2, "Strona WWW"), (3, "Aplikacja Mobilna"), (4, "Partnerzy (Groupon itp.)")]
    write_csv("channels.csv", channels, ["channel_id", "channel_name"])

    t_types = [(1, "Normalny"), (2, "Ulgowy"), (3, "Rodzinny"), (4, "VIP FastPass")]
    write_csv("ticket_types.csv", t_types, ["ticket_type_id", "type_name"])

    t_prices = [
        (1, "2020-01-01", None, 159.00),
        (2, "2020-01-01", None, 99.00),
        (3, "2020-01-01", None, 399.00),
        (4, "2020-01-01", None, 299.00)
    ]
    write_csv("ticket_price_list.csv", t_prices, ["ticket_type_id", "valid_from", "valid_to", "price"])
    price_map = {1: 159.0, 2: 99.0, 3: 399.0, 4: 299.0}

    modes = [(1, "Standard"), (2, "Fast Pass"), (3, "Single Rider")]
    write_csv("session_modes.csv", modes, ["mode_id", "mode_name"])

    positions = [(1, "Operator"), (2, "Kasjer"), (3, "Technik"), (4, "Menadżer"), (5, "Ochrona"), (6, "Gastronomia")]
    write_csv("positions.csv", positions, ["position_id", "position_name"])

    attr_types = [(1, "Rollercoaster"), (2, "Wodna"), (3, "Karuzela"), (4, "Dom Strachów"), (5, "Dla dzieci")]
    write_csv("attraction_types.csv", attr_types, ["attraction_type_id", "type_name"])

    pay_methods = [(1, "Karta"), (2, "Gotówka"), (3, "BLIK")]
    write_csv("payment_methods.csv", pay_methods, ["payment_method_id", "method_name"])

    prod_cats = [(1, "Jedzenie"), (2, "Napoje"), (3, "Pamiątki"), (4, "Odzież")]
    write_csv("product_categories.csv", prod_cats, ["category_id", "category_name"])

    insurers = [(1, "PZU"), (2, "Warta"), (3, "Allianz"), (4, "Generali")]
    write_csv("insurers.csv", insurers, ["insurer_id", "insurer_name"])

    cost_cats = [(1, "Prąd"), (2, "Woda"), (3, "Wynagrodzenia"), (4, "Części Zamienne"), (5, "Marketing")]
    write_csv("cost_categories.csv", cost_cats, ["cost_category_id", "category_name"])

    pol_types = [(1, "NNW Turystyczne", "Ochrona zdrowia"), (2, "Ubezpieczenie Bagażu", "Kradzież/Zgubienie")]
    write_csv("policy_types.csv", pol_types, ["policy_type_id", "type_name", "description"])

    event_types = [(1, "Zgubienie telefonu", 1), (2, "Zadrapanie", 2), (3, "Zatrzymanie wagonika", 4),
                   (4, "Udar słoneczny", 3), (5, "Kradzież portfela", 3)]
    write_csv("unpleasant_event_types.csv", event_types, ["event_type_id", "event_name", "default_severity"])

    # 2. LUDZIE I FIRMY
    partners = []
    company_prefixes = ["Tech", "Food", "Clean", "Secure", "Build", "Fun"]
    company_suffixes = ["Sp. z o.o.", "S.A.", "Polska", "Services", "Technics"]
    for i in range(1, 16):
        c_name = f"{random.choice(company_prefixes)}{fake.word().capitalize()} {random.choice(company_suffixes)}"
        partners.append((i, c_name, fake.nip(), f"kontakt@{normalize_str(c_name.split()[0])}.pl", gen_phone(),
                         fake.address().replace("\n", ", ")))
    write_csv("partners.csv", partners, ["partner_id", "partner_name", "tax_id", "email", "phone", "address"])

    contracts = []
    for i in range(1, 8):
        contract_type = random.choice(["maintenance", "supplier", "other"])
        contracts.append((i, random.randint(1, 15), contract_type, "2020-01-01", "2025-12-31", "Umowa ramowa"))
    write_csv("partner_contracts.csv", contracts,
              ["contract_id", "partner_id", "contract_type", "valid_from", "valid_to", "details"])

    attractions_def = [
        (1, "Hyperion", 1, 60000000, "2018-06-15", 2, 1),
        (2, "Zadra", 1, 70000000, "2019-08-20", 1, 1),
        (3, "Super Kopacz", 2, 20000000, "2017-05-01", 3, 2),
        (4, "Stary Karuzel", 3, 500000, "2005-04-10", 8, 1), 
        (5, "Belka Strachu", 4, 3000000, "2015-10-31", 2, 3),
        (6, "Petruleum", 5, 2000000, "2016-06-01", 1, 0),
        (7, "Ekstremalny Młot", 1, 5000000, "2010-07-01", 6, 5),
        (8, "Skarbiec majów 7.0", 2, 12000000, "2012-05-01", 4, 2),
        (9, "Cookies Monster", 1, 8000000, "2014-04-01", 3, 2),
        (10, "Węgierski Azyl", 5, 1500000, "2008-01-01", 5, 1)
    ]

    attractions_csv = []
    for a in attractions_def:
        attractions_csv.append((a[0], a[1], a[2], "2010-01-01", a[3], a[4], None, "operational", random.randint(0, 12),
                                random.randint(0, 120), 0))
    write_csv("attractions.csv", attractions_csv,
              ["attraction_id", "attraction_name", "attraction_type_id", "purchase_date", "purchase_cost", "opened_on",
               "closed_on", "status", "min_age", "min_height_cm", "is_vr_available"])

    employees = []
    sal_hist = []
    for i in range(1, 51):
        fname = fake.first_name()
        lname = fake.last_name()
        mail = gen_email(fname, lname)
        hire = fake.date_between(start_date="-5y", end_date="-1y")
        pos = random.randint(1, 6)
        base = 4000
        if pos == 3: base = 6000
        if pos == 4: base = 9000
        employees.append(
            (i, fname, lname, fmt_d(fake.date_of_birth(minimum_age=20, maximum_age=60)), fmt_d(hire), None, mail,
             gen_phone(), "active", pos))
        sal_hist.append((i, fmt_d(hire), None, base + random.randint(0, 1000)))

    write_csv("employees.csv", employees,
              ["employee_id", "first_name", "last_name", "birth_date", "hire_date", "termination_date", "email",
               "phone", "status", "position_id"])
    write_csv("employee_salary_history.csv", sal_hist,
              ["employee_id", "valid_from", "valid_to", "salary_gross_monthly"])

    # --- GENEROWANIE WIEKU ---
    guests_db = []
    guest_count = 1500
    print("   Generowanie gości (Rozkład Gamma)...")

    for i in range(1, guest_count + 1):
        f = fake.first_name()
        l = fake.last_name()

        shape = 4
        scale = 6
        min_age = 5

        val = random.gammavariate(shape, scale)
        age = int(min_age + val)
        if age > 80: age = 80

        days_old = int(age * 365.25) + random.randint(0, 360)
        dob = date.today() - timedelta(days=days_old)

        guests_db.append({
            "id": i,
            "first": f, "last": l,
            "mail": gen_email(f, l),
            "phone": gen_phone(),
            "dob": dob,
            "created": fake.date_time_between(start_date="-3y", end_date="-1d")
        })

    g_csv = [(g["id"], g["first"], g["last"], fmt_d(g["dob"]), g["mail"], g["phone"], fmt_dt(g["created"])) for g in
             guests_db]
    write_csv("guests.csv", g_csv,
              ["guest_id", "first_name", "last_name", "birth_date", "email", "phone", "created_at"])

    # PRODUKTY
    products = [
        (1, "Woda Mineralna 0.5L", 2, 1.0, 6.0),
        (2, "Coca Cola 0.5L", 2, 2.5, 9.0),
        (3, "Kawa Espresso", 2, 1.0, 12.0),
        (4, "Burger Classic", 1, 8.0, 32.0),
        (5, "Frytki Małe", 1, 2.0, 12.0),
        (6, "Lody Włoskie", 1, 1.5, 8.0),
        (7, "Zapiekanka XXL", 1, 4.0, 22.0),
        (8, "Gofr z owocami", 1, 3.0, 18.0),
        (9, "Magnes Parkowy", 3, 2.0, 15.0),
        (10, "Smycz do kluczy", 3, 3.0, 20.0),
        (11, "Pluszowy Miś", 3, 15.0, 55.0),
        (12, "Koszulka Logo", 4, 18.0, 69.0),
        (13, "Czapka z daszkiem", 4, 12.0, 45.0),
        (14, "Peleryna Przeciwdeszczowa", 4, 5.0, 25.0)
    ]
    prod_map_data = {p[0]: p for p in products}

    prod_csv = []
    prod_price_list = []
    for p in products:
        prod_csv.append((p[0], p[1], p[2], 1, p[3], 0))
        prod_price_list.append((p[0], "2020-01-01", None, p[4]))

    write_csv("shop_products.csv", prod_csv,
              ["product_id", "product_name", "category_id", "is_active", "unit_purchase_cost", "unit_production_cost"])
    write_csv("shop_price_list.csv", prod_price_list, ["product_id", "valid_from", "valid_to", "list_price"])

    # SYMULACJA CZASU
    visits = []
    tickets = []
    transactions = []
    shop_sales = []
    shop_items = []
    failures = []
    incidents = []
    op_costs = []
    inv_movements = []
    sessions = []
    policies = []
    coverages = []

    curr_date = START_DATE
    trans_id = 1
    visit_id = 1
    sale_id = 1
    failure_id = 1
    incident_id = 1
    cost_id = 1
    session_id = 1
    move_id = 1
    policy_id = 1

    # ID atrakcji, które mają tracić pieniądze
    unprofitable_ids = [4, 10]

    print("   Symulacja dzień po dniu")

    while curr_date <= END_DATE:
        month = curr_date.month
        weekday = curr_date.weekday()
        is_weekend = weekday >= 5
        is_summer = month in [6, 7, 8]
        is_winter = month in [11, 12, 1, 2]
        is_school_trip_season = month in [5, 6, 9]

        # --- LOGIKA RUCHU ---
        if is_winter:
            daily_traffic = random.randint(120, 200)
        elif is_summer:
            daily_traffic = random.randint(500, 750)
        elif is_school_trip_season and weekday < 5:
            daily_traffic = random.randint(300, 500)
        else:
            daily_traffic = random.randint(200, 350)

        if is_weekend:
            daily_traffic = int(daily_traffic * 1.5)

        # --- TYPY BILETÓW ---
        if curr_date.year == 2021:
            base_weights = [40, 50, 8, 2]
        elif curr_date.year == 2022:
            base_weights = [30, 20, 45, 5]
        else:
            base_weights = [40, 10, 20, 30]

        if is_school_trip_season and weekday < 5:
            current_weights = [w + change for w, change in zip(base_weights, [-10, 50, -10, -5])]
        elif is_summer:
            current_weights = [w + change for w, change in zip(base_weights, [-5, -5, 30, 0])]
        elif is_winter:
            current_weights = [w + change for w, change in zip(base_weights, [20, -10, -10, 10])]
        else:
            current_weights = base_weights
        current_weights = [max(1, w) for w in current_weights]

        todays_guests = random.sample(guests_db, min(daily_traffic, len(guests_db)))

        for g in todays_guests:
            enter_h = random.randint(9, 17)
            enter_time = datetime.combine(curr_date, time(enter_h, random.randint(0, 59)))
            stay_duration = random.randint(2, 6)
            exit_time = enter_time + timedelta(hours=stay_duration)

            visits.append(
                (visit_id, g["id"], fmt_d(curr_date), fmt_dt(enter_time), fmt_dt(exit_time), random.randint(1, 4)))

            pay_weights = [random.randint(50, 70), random.randint(10, 20), random.randint(20, 40)]
            pay_method = random.choices([1, 2, 3], weights=pay_weights, k=1)[0]

            tid = random.choices([1, 2, 3, 4], weights=current_weights, k=1)[0]
            price = price_map[tid]

            transactions.append(
                (trans_id, fmt_dt(enter_time), "income", pay_method, price, "PLN", f"Bilet {tid}", "ticket", visit_id,
                 None))
            tickets.append((visit_id, visit_id, tid, price, fmt_dt(enter_time)))
            trans_id += 1

            # --- UBEZPIECZENIA ---
            if random.random() < 0.05:
                pol_cost = 15.0
                pay_method_ins = random.choices([1, 2, 3], weights=[80, 5, 15])[0]
                policies.append(
                    (policy_id, f"POL/{curr_date.year}/{policy_id}", g["id"], visit_id, random.randint(1, 4), 1,
                     fmt_d(curr_date), fmt_d(curr_date), pol_cost))
                transactions.append(
                    (trans_id, fmt_dt(enter_time), "income", pay_method_ins, pol_cost, "PLN", "Polisa NNW",
                     "insurance_premium", policy_id, None))
                coverages.append((policy_id, 2, 5000.0, 0.0))
                policy_id += 1
                trans_id += 1

            # --- ATRAKCJE / SESJE / INCYDENTY ---
            rides_count = random.randint(2, 6)
            for _ in range(rides_count):
                attr_def = random.choice(attractions_def)
                aid = attr_def[0]
                # Incydenty
                if random.random() < (0.0001 * attr_def[6]):
                    severity = random.randint(1, attr_def[6])
                    desc = random.choice(["Złamanie kończyny", "Porażenie prądem", "Zgubienie czapki", "Omdlenie"])
                    incidents.append((incident_id, fmt_dt(enter_time + timedelta(minutes=30)), g["id"], visit_id, aid,
                                      random.randint(1, 5), severity, desc, severity * 200.0, None, 0))
                    incident_id += 1

                start_ride = enter_time + timedelta(minutes=random.randint(10, stay_duration * 60))
                sessions.append(
                    (session_id, visit_id, aid, fmt_dt(start_ride), fmt_dt(start_ride + timedelta(minutes=5)), 1, 1,
                     random.randint(1, 40)))
                session_id += 1

            # --- SKLEP ---
            shop_chance = 0.6 if is_summer else 0.4

            if random.random() < shop_chance:
                p_weights = {p[0]: 10 for p in products}
                if is_summer:
                    p_weights[6] = 200;
                    p_weights[1] = 150;
                    p_weights[2] = 120;
                    p_weights[3] = 5;
                    p_weights[14] = 0
                elif is_winter:
                    p_weights[6] = 5;
                    p_weights[3] = 150;
                    p_weights[14] = 80;
                    p_weights[1] = 30
                elif is_school_trip_season:
                    p_weights[4] = 100;
                    p_weights[5] = 100;
                    p_weights[9] = 150

                prod_ids_list = list(p_weights.keys())
                prod_weights_list = list(p_weights.values())

                bought_raw = random.choices(prod_ids_list, weights=prod_weights_list, k=random.randint(1, 3))

                counts = {}
                for pid in bought_raw:
                    counts[pid] = counts.get(pid, 0) + 1

                total = 0
                for pid, qty in counts.items():
                    p_data = prod_map_data[pid]
                    price_sell = p_data[4]
                    cost_buy = p_data[3]

                    shop_items.append((sale_id, pid, qty, price_sell))
                    inv_movements.append((move_id, pid, fmt_dt(enter_time), -qty, cost_buy, "sale", None))
                    move_id += 1
                    total += (qty * price_sell)

                pay_method_shop = random.choices([1, 2, 3], weights=[60, 20, 20], k=1)[0]
                transactions.append(
                    (trans_id, fmt_dt(enter_time + timedelta(hours=1)), "income", pay_method_shop, total, "PLN",
                     "Sklep", "shop_sale", sale_id, None))
                shop_sales.append((sale_id, fmt_dt(enter_time), visit_id, trans_id))
                trans_id += 1
                sale_id += 1

            visit_id += 1

        # --- AWARIE ---
        for attr in attractions_def:
            aid = attr[0]
            base_prob = attr[5] / 200.0

            # Jeśli atrakcja nierentowna, psuje się częściej
            if aid in unprofitable_ids:
                base_prob = attr[5] / 80.0 

            if random.random() < base_prob:
                rep_time = datetime.combine(curr_date, time(random.randint(9, 18), random.randint(0, 59)))
                fix_time = rep_time + timedelta(days=random.randint(2, 5))

                if aid in unprofitable_ids:
                    repair_cost = random.randint(20000, 50000)
                    desc = "Krytyczna awaria silnika/hydrauliki"
                else:
                    repair_cost = random.randint(2000, 15000)
                    desc = "Awaria mechaniczna"

                failures.append((failure_id, attr[0], fmt_dt(rep_time), fmt_dt(fix_time), random.randint(3, 5),
                                 desc, "Zużycie", repair_cost, random.randint(1, 10),
                                 1))
                failure_id += 1

        # --- KOSZTY MIESIĘCZNE ---
        if curr_date.day == 1:
            #  Koszty ogólne
            cost_val = random.uniform(15000, 30000)
            if is_winter: cost_val *= 0.8
            if is_summer: cost_val *= 1.2

            transactions.append(
                (trans_id, fmt_dt(datetime.combine(curr_date, time(8, 0))), "expense", 1, cost_val, "PLN",
                 "Faktura Prąd", "operating_cost", cost_id, None))
            op_costs.append((cost_id, fmt_d(curr_date), 1, cost_val, "Tauron", None, None, 1, trans_id))
            trans_id += 1
            cost_id += 1

            for attr in attractions_def:
                aid = attr[0]
                aname = attr[1]

                if aid in unprofitable_ids:
                    # GIGANTYCZNE KOSZTY
                    maint_cost = random.uniform(40000, 90000)
                    desc_maint = f"Kapitalny remont/Części ({aname})"
                else:
                    # STANDARDOWE KOSZTY
                    maint_cost = random.uniform(500, 2500)
                    desc_maint = f"Konserwacja bieżąca ({aname})"

                transactions.append(
                    (trans_id, fmt_dt(datetime.combine(curr_date, time(9, 0))), "expense", 1, maint_cost, "PLN",
                     desc_maint, "operating_cost", cost_id, None))
                op_costs.append((cost_id, fmt_d(curr_date), 4, maint_cost, desc_maint, aid, None, 1, trans_id))
                trans_id += 1
                cost_id += 1

            print(f"   Generuję: {curr_date.strftime('%Y-%m')}, Wizyt dotąd: {visit_id}")

        curr_date += timedelta(days=1)

    # Inwestycje
    investments = [
        (1, "Nowa Strefa Wodna", "Rozbudowa basenów", "2023-01-15", "2024-05-01", 5000000.00, "in_progress", 2, None,
         None)]
    milestones = [(1, 1, "Wylanie fundamentów", "2023-03-01", 1)]
    inspections = []
    for i, a in enumerate(attractions_def, 1):
        inspections.append((i, a[0], "2023-01-10", "pass", "Wszystko OK", 500.0, 3, None))

    # ZAPIS WSZYSTKIEGO
    write_csv("visits.csv", visits, ["visit_id", "guest_id", "visit_date", "enter_time", "exit_time", "channel_id"])
    write_csv("tickets.csv", tickets, ["ticket_id", "visit_id", "ticket_type_id", "price_paid", "purchased_at"])
    write_csv("financial_transactions.csv", transactions,
              ["transaction_id", "transaction_time", "direction", "payment_method_id", "amount", "currency", "title",
               "source_type", "source_id", "entered_by_employee_id"])
    write_csv("shop_sales.csv", shop_sales, ["sale_id", "sale_time", "visit_id", "transaction_id"])
    write_csv("shop_sale_items.csv", shop_items, ["sale_id", "product_id", "quantity", "unit_price_paid"])
    write_csv("attraction_failures.csv", failures,
              ["failure_id", "attraction_id", "reported_at", "resolved_at", "severity", "description", "root_cause",
               "repair_cost", "resolved_by_employee_id", "resolved_by_partner_id"])
    write_csv("incidents.csv", incidents,
              ["incident_id", "occurred_at", "guest_id", "visit_id", "attraction_id", "event_type_id", "severity",
               "description", "estimated_cost", "claimed_policy_id", "paid_out_cost"])
    write_csv("operating_costs.csv", op_costs,
              ["cost_id", "cost_date", "cost_category_id", "amount", "description", "related_attraction_id",
               "related_employee_id", "partner_id", "transaction_id"])
    write_csv("attraction_sessions.csv", sessions,
              ["session_id", "visit_id", "attraction_id", "start_time", "end_time", "mode_id", "completed",
               "operator_employee_id"])
    write_csv("insurance_policies.csv", policies,
              ["policy_id", "policy_number", "guest_id", "visit_id", "insurer_id", "policy_type_id", "valid_from",
               "valid_to", "premium_paid"])
    write_csv("policy_coverages.csv", coverages, ["policy_id", "event_type_id", "coverage_limit", "deductible"])
    write_csv("shop_inventory_movements.csv", inv_movements,
              ["movement_id", "product_id", "movement_time", "qty_change", "unit_cost", "reason", "partner_id"])
    write_csv("planned_investments.csv", investments,
              ["investment_id", "title", "description", "planned_start", "planned_end", "budget", "status",
               "partner_id", "related_attraction_id", "transaction_id"])
    write_csv("investment_milestones.csv", milestones,
              ["milestone_id", "investment_id", "milestone_name", "planned_date", "done"])
    write_csv("attraction_inspections.csv", inspections,
              ["inspection_id", "attraction_id", "inspection_date", "result", "notes", "cost",
               "performed_by_employee_id", "performed_by_partner_id"])


def load_real_data():
    print(f"\n--- Wgrywanie danych do bazy {DB_HOST}:{DB_PORT}... ---")
    try:
        conn = mysql.connector.connect(host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASS, database=DB_NAME)
        cursor = conn.cursor()

        # CZYSZCZENIE (TRUNCATE)
        print(" Czyszczenie bazy (TRUNCATE)...")
        cursor.execute("SET FOREIGN_KEY_CHECKS=0;")

        tables = [
            "channels", "ticket_types", "session_modes", "positions", "attraction_types", "payment_methods",
            "product_categories", "insurers", "cost_categories", "policy_types", "unpleasant_event_types",
            "partners", "partner_contracts", "attractions", "employees", "employee_salary_history", "guests",
            "visits", "financial_transactions", "tickets", "shop_products", "shop_price_list", "shop_sales",
            "shop_sale_items", "shop_inventory_movements", "attraction_sessions",
            "attraction_failures", "incidents", "operating_costs",
            "planned_investments", "investment_milestones", "attraction_inspections",
            "insurance_policies", "policy_coverages"
        ]

        for t in tables:
            try:
                cursor.execute(f"TRUNCATE TABLE {t};")
            except:
                pass

        cursor.execute("SET FOREIGN_KEY_CHECKS=1;")
        print("Wyczyszczono.")

        # WGRYWANIE
        for table in tables:
            path = os.path.join(OUTPUT_DIR, f"{table}.csv")
            if not os.path.exists(path): continue

            with open(path, "r", encoding="utf-8") as f:
                reader = csv.reader(f)
                header = next(reader, None)
                if not header: continue
                print(f"Wgrywanie {table}...", end=" ")
                cols = ",".join(header)
                vals = ",".join(["%s"] * len(header))
                sql = f"INSERT INTO {table} ({cols}) VALUES ({vals})"

                batch = []
                for row in reader:
                    batch.append([None if x == "" else x for x in row])
                    if len(batch) >= 1000:
                        cursor.executemany(sql, batch)
                        conn.commit()
                        batch = []
                if batch:
                    cursor.executemany(sql, batch)
                    conn.commit()
                print("OK")

        conn.close()
        print("\n SUKCES!")
    except Exception as e:
        print(f"\n BŁĄD: {e}")


if __name__ == "__main__":
    gen_real_data()
    load_real_data()