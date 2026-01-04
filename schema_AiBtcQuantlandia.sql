SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE positions (
  position_id   BIGINT NOT NULL AUTO_INCREMENT,
  position_name VARCHAR(150) NOT NULL,
  PRIMARY KEY (position_id),
  UNIQUE KEY uq_positions_name (position_name)
) ENGINE=InnoDB;

-- ============================================================
--  1) EMPLOYEES
-- ============================================================

CREATE TABLE employees (
  employee_id      BIGINT NOT NULL AUTO_INCREMENT,
  first_name       VARCHAR(120) NOT NULL,
  last_name        VARCHAR(120) NOT NULL,
  birth_date       DATE NOT NULL,
  hire_date        DATE NOT NULL,
  termination_date DATE NULL,
  email            VARCHAR(255) NOT NULL,
  phone            VARCHAR(50) NULL,
  status           VARCHAR(20) NOT NULL,
  position_id      BIGINT NOT NULL,
  PRIMARY KEY (employee_id),
  UNIQUE KEY uq_employees_email (email),
  KEY idx_employees_position (position_id),
  CONSTRAINT fk_employees_position
    FOREIGN KEY (position_id) REFERENCES positions(position_id),
  CONSTRAINT ck_employees_status
    CHECK (status IN ('active','terminated')),
  CONSTRAINT ck_employees_dates
    CHECK (termination_date IS NULL OR termination_date >= hire_date)
) ENGINE=InnoDB;

CREATE TABLE employee_salary_history (
  employee_id          BIGINT NOT NULL,
  valid_from           DATE NOT NULL,
  valid_to             DATE NULL,
  salary_gross_monthly DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (employee_id, valid_from),
  CONSTRAINT fk_salary_employee
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
  CONSTRAINT ck_salary_nonneg
    CHECK (salary_gross_monthly >= 0),
  CONSTRAINT ck_salary_dates
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
) ENGINE=InnoDB;

-- ============================================================
--  2) PARTNERS
-- ============================================================

CREATE TABLE partners (
  partner_id    BIGINT NOT NULL AUTO_INCREMENT,
  partner_name  VARCHAR(255) NOT NULL,
  tax_id        VARCHAR(50) NULL,
  email         VARCHAR(255) NULL,
  phone         VARCHAR(50) NULL,
  address       VARCHAR(500) NULL,
  PRIMARY KEY (partner_id),
  UNIQUE KEY uq_partners_name (partner_name),
  UNIQUE KEY uq_partners_tax (tax_id)
) ENGINE=InnoDB;

CREATE TABLE partner_contracts (
  contract_id    BIGINT NOT NULL AUTO_INCREMENT,
  partner_id     BIGINT NOT NULL,
  contract_type  VARCHAR(30) NOT NULL,
  valid_from     DATE NOT NULL,
  valid_to       DATE NULL,
  details        VARCHAR(2000) NULL,
  PRIMARY KEY (contract_id),
  KEY idx_contracts_partner (partner_id),
  CONSTRAINT fk_contracts_partner
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
  CONSTRAINT ck_contract_type
    CHECK (contract_type IN ('maintenance','vr_provider','insurer','supplier','other')),
  CONSTRAINT ck_contract_dates
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
) ENGINE=InnoDB;

-- ============================================================
--  3) ATTRACTIONS
-- ============================================================

CREATE TABLE attraction_types (
  attraction_type_id BIGINT NOT NULL AUTO_INCREMENT,
  type_name          VARCHAR(150) NOT NULL,
  PRIMARY KEY (attraction_type_id),
  UNIQUE KEY uq_attr_types_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE attractions (
  attraction_id      BIGINT NOT NULL AUTO_INCREMENT,
  attraction_name    VARCHAR(255) NOT NULL,
  attraction_type_id BIGINT NOT NULL,
  purchase_date      DATE NOT NULL,
  purchase_cost      DECIMAL(14,2) NOT NULL,
  opened_on          DATE NOT NULL,
  closed_on          DATE NULL,
  status             VARCHAR(30) NOT NULL,
  min_age            INT NULL,
  min_height_cm      INT NULL,
  is_vr_available    TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (attraction_id),
  UNIQUE KEY uq_attractions_name (attraction_name),
  KEY idx_attractions_type (attraction_type_id),
  CONSTRAINT fk_attractions_type
    FOREIGN KEY (attraction_type_id) REFERENCES attraction_types(attraction_type_id),
  CONSTRAINT ck_attraction_purchase_cost
    CHECK (purchase_cost >= 0),
  CONSTRAINT ck_attraction_status
    CHECK (status IN ('operational','maintenance','out_of_service')),
  CONSTRAINT ck_attraction_min_age
    CHECK (min_age IS NULL OR min_age >= 0),
  CONSTRAINT ck_attraction_min_height
    CHECK (min_height_cm IS NULL OR min_height_cm >= 0),
  CONSTRAINT ck_attraction_dates
    CHECK (closed_on IS NULL OR closed_on >= opened_on)
) ENGINE=InnoDB;

CREATE TABLE attraction_inspections (
  inspection_id            BIGINT NOT NULL AUTO_INCREMENT,
  attraction_id            BIGINT NOT NULL,
  inspection_date          DATE NOT NULL,
  result                   VARCHAR(20) NOT NULL,
  notes                    VARCHAR(2000) NULL,
  cost                     DECIMAL(12,2) NOT NULL DEFAULT 0,
  performed_by_employee_id BIGINT NULL,
  performed_by_partner_id  BIGINT NULL,
  PRIMARY KEY (inspection_id),
  KEY idx_inspections_attr (attraction_id),
  KEY idx_inspections_emp (performed_by_employee_id),
  KEY idx_inspections_partner (performed_by_partner_id),
  CONSTRAINT fk_inspections_attraction
    FOREIGN KEY (attraction_id) REFERENCES attractions(attraction_id),
  CONSTRAINT fk_inspections_employee
    FOREIGN KEY (performed_by_employee_id) REFERENCES employees(employee_id),
  CONSTRAINT fk_inspections_partner
    FOREIGN KEY (performed_by_partner_id) REFERENCES partners(partner_id),
  CONSTRAINT ck_inspection_result
    CHECK (result IN ('pass','fail','conditional')),
  CONSTRAINT ck_inspection_cost
    CHECK (cost >= 0),
  CONSTRAINT ck_inspection_performer
    CHECK (performed_by_employee_id IS NOT NULL OR performed_by_partner_id IS NOT NULL)
) ENGINE=InnoDB;

CREATE TABLE attraction_failures (
  failure_id              BIGINT NOT NULL AUTO_INCREMENT,
  attraction_id           BIGINT NOT NULL,
  reported_at             DATETIME NOT NULL,
  resolved_at             DATETIME NULL,
  severity                INT NOT NULL,
  description             VARCHAR(2000) NOT NULL,
  root_cause              VARCHAR(2000) NULL,
  repair_cost             DECIMAL(12,2) NOT NULL DEFAULT 0,
  resolved_by_employee_id BIGINT NULL,
  resolved_by_partner_id  BIGINT NULL,
  PRIMARY KEY (failure_id),
  KEY idx_failures_attr (attraction_id),
  KEY idx_failures_reported (reported_at),
  KEY idx_failures_emp (resolved_by_employee_id),
  KEY idx_failures_partner (resolved_by_partner_id),
  CONSTRAINT fk_failures_attraction
    FOREIGN KEY (attraction_id) REFERENCES attractions(attraction_id),
  CONSTRAINT fk_failures_employee
    FOREIGN KEY (resolved_by_employee_id) REFERENCES employees(employee_id),
  CONSTRAINT fk_failures_partner
    FOREIGN KEY (resolved_by_partner_id) REFERENCES partners(partner_id),
  CONSTRAINT ck_failure_severity
    CHECK (severity BETWEEN 1 AND 5),
  CONSTRAINT ck_failure_repair_cost
    CHECK (repair_cost >= 0),
  CONSTRAINT ck_failure_dates
    CHECK (resolved_at IS NULL OR resolved_at >= reported_at)
) ENGINE=InnoDB;

-- ============================================================
--  4) GUESTS + VISITS + TICKETS + SESSIONS
-- ============================================================

CREATE TABLE guests (
  guest_id    BIGINT NOT NULL AUTO_INCREMENT,
  first_name  VARCHAR(120) NOT NULL,
  last_name   VARCHAR(120) NOT NULL,
  birth_date  DATE NOT NULL,
  email       VARCHAR(255) NULL,
  phone       VARCHAR(50) NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (guest_id),
  UNIQUE KEY uq_guests_email (email)
) ENGINE=InnoDB;

CREATE TABLE channels (
  channel_id   BIGINT NOT NULL AUTO_INCREMENT,
  channel_name VARCHAR(40) NOT NULL,
  PRIMARY KEY (channel_id),
  UNIQUE KEY uq_channels_name (channel_name)
) ENGINE=InnoDB;

CREATE TABLE visits (
  visit_id    BIGINT NOT NULL AUTO_INCREMENT,
  guest_id    BIGINT NOT NULL,
  visit_date  DATE NOT NULL,
  enter_time  DATETIME NOT NULL,
  exit_time   DATETIME NULL,
  channel_id  BIGINT NOT NULL,
  PRIMARY KEY (visit_id),
  KEY idx_visits_guest (guest_id),
  KEY idx_visits_channel (channel_id),
  CONSTRAINT fk_visits_guest
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
  CONSTRAINT fk_visits_channel
    FOREIGN KEY (channel_id) REFERENCES channels(channel_id),
  CONSTRAINT ck_visits_times
    CHECK (exit_time IS NULL OR exit_time >= enter_time)
) ENGINE=InnoDB;

CREATE TABLE ticket_types (
  ticket_type_id BIGINT NOT NULL AUTO_INCREMENT,
  type_name      VARCHAR(120) NOT NULL,
  PRIMARY KEY (ticket_type_id),
  UNIQUE KEY uq_ticket_types_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE ticket_price_list (
  ticket_type_id BIGINT NOT NULL,
  valid_from     DATE NOT NULL,
  valid_to       DATE NULL,
  price          DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (ticket_type_id, valid_from),
  CONSTRAINT fk_ticket_price_type
    FOREIGN KEY (ticket_type_id) REFERENCES ticket_types(ticket_type_id),
  CONSTRAINT ck_ticket_price_nonneg
    CHECK (price >= 0),
  CONSTRAINT ck_ticket_price_dates
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
) ENGINE=InnoDB;

CREATE TABLE tickets (
  ticket_id      BIGINT NOT NULL AUTO_INCREMENT,
  visit_id       BIGINT NOT NULL,
  ticket_type_id BIGINT NOT NULL,
  purchased_at   DATETIME NOT NULL,
  price_paid     DECIMAL(12,2) NOT NULL,
  currency       CHAR(3) NOT NULL DEFAULT 'PLN',
  PRIMARY KEY (ticket_id),
  KEY idx_tickets_visit (visit_id),
  KEY idx_tickets_type (ticket_type_id),
  CONSTRAINT fk_tickets_visit
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
  CONSTRAINT fk_tickets_type
    FOREIGN KEY (ticket_type_id) REFERENCES ticket_types(ticket_type_id),
  CONSTRAINT ck_tickets_price_paid
    CHECK (price_paid >= 0)
) ENGINE=InnoDB;

CREATE TABLE session_modes (
  mode_id   BIGINT NOT NULL AUTO_INCREMENT,
  mode_name VARCHAR(40) NOT NULL,
  PRIMARY KEY (mode_id),
  UNIQUE KEY uq_session_modes_name (mode_name)
) ENGINE=InnoDB;

CREATE TABLE attraction_sessions (
  session_id           BIGINT NOT NULL AUTO_INCREMENT,
  visit_id             BIGINT NOT NULL,
  attraction_id        BIGINT NOT NULL,
  start_time           DATETIME NOT NULL,
  end_time             DATETIME NULL,
  mode_id              BIGINT NOT NULL,
  completed            TINYINT(1) NOT NULL DEFAULT 1,
  operator_employee_id BIGINT NULL,
  PRIMARY KEY (session_id),
  KEY idx_sessions_visit (visit_id),
  KEY idx_sessions_attr (attraction_id),
  KEY idx_sessions_mode (mode_id),
  KEY idx_sessions_operator (operator_employee_id),
  CONSTRAINT fk_sessions_visit
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
  CONSTRAINT fk_sessions_attraction
    FOREIGN KEY (attraction_id) REFERENCES attractions(attraction_id),
  CONSTRAINT fk_sessions_mode
    FOREIGN KEY (mode_id) REFERENCES session_modes(mode_id),
  CONSTRAINT fk_sessions_operator
    FOREIGN KEY (operator_employee_id) REFERENCES employees(employee_id),
  CONSTRAINT ck_sessions_times
    CHECK (end_time IS NULL OR end_time >= start_time)
) ENGINE=InnoDB;

-- ============================================================
--  5) INSURANCE + INCIDENTS + EVENT TYPES
-- ============================================================

CREATE TABLE insurers (
  insurer_id   BIGINT NOT NULL AUTO_INCREMENT,
  insurer_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (insurer_id),
  UNIQUE KEY uq_insurers_name (insurer_name)
) ENGINE=InnoDB;

CREATE TABLE policy_types (
  policy_type_id BIGINT NOT NULL AUTO_INCREMENT,
  type_name      VARCHAR(120) NOT NULL,
  description    VARCHAR(2000) NULL,
  PRIMARY KEY (policy_type_id),
  UNIQUE KEY uq_policy_types_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE insurance_policies (
  policy_id      BIGINT NOT NULL AUTO_INCREMENT,
  policy_number  VARCHAR(80) NOT NULL,
  guest_id       BIGINT NOT NULL,
  visit_id       BIGINT NULL,
  insurer_id     BIGINT NOT NULL,
  policy_type_id BIGINT NOT NULL,
  valid_from     DATE NOT NULL,
  valid_to       DATE NOT NULL,
  premium_paid   DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (policy_id),
  UNIQUE KEY uq_policy_number (policy_number),
  KEY idx_policy_guest (guest_id),
  KEY idx_policy_visit (visit_id),
  KEY idx_policy_insurer (insurer_id),
  KEY idx_policy_type (policy_type_id),
  CONSTRAINT fk_policy_guest
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
  CONSTRAINT fk_policy_visit
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
  CONSTRAINT fk_policy_insurer
    FOREIGN KEY (insurer_id) REFERENCES insurers(insurer_id),
  CONSTRAINT fk_policy_type
    FOREIGN KEY (policy_type_id) REFERENCES policy_types(policy_type_id),
  CONSTRAINT ck_policy_dates
    CHECK (valid_to >= valid_from),
  CONSTRAINT ck_policy_premium
    CHECK (premium_paid >= 0)
) ENGINE=InnoDB;

CREATE TABLE unpleasant_event_types (
  event_type_id    BIGINT NOT NULL AUTO_INCREMENT,
  event_name       VARCHAR(255) NOT NULL,
  default_severity INT NOT NULL,
  PRIMARY KEY (event_type_id),
  UNIQUE KEY uq_event_name (event_name),
  CONSTRAINT ck_event_default_sev
    CHECK (default_severity BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE policy_coverages (
  policy_id      BIGINT NOT NULL,
  event_type_id  BIGINT NOT NULL,
  coverage_limit DECIMAL(12,2) NULL,
  deductible     DECIMAL(12,2) NULL,
  PRIMARY KEY (policy_id, event_type_id),
  CONSTRAINT fk_cov_policy
    FOREIGN KEY (policy_id) REFERENCES insurance_policies(policy_id),
  CONSTRAINT fk_cov_event
    FOREIGN KEY (event_type_id) REFERENCES unpleasant_event_types(event_type_id),
  CONSTRAINT ck_cov_limit
    CHECK (coverage_limit IS NULL OR coverage_limit >= 0),
  CONSTRAINT ck_cov_deductible
    CHECK (deductible IS NULL OR deductible >= 0)
) ENGINE=InnoDB;

CREATE TABLE incidents (
  incident_id       BIGINT NOT NULL AUTO_INCREMENT,
  occurred_at       DATETIME NOT NULL,
  guest_id          BIGINT NOT NULL,
  visit_id          BIGINT NOT NULL,
  attraction_id     BIGINT NULL,
  event_type_id     BIGINT NOT NULL,
  severity          INT NOT NULL,
  description       VARCHAR(2000) NULL,
  estimated_cost    DECIMAL(12,2) NULL,
  claimed_policy_id BIGINT NULL,
  paid_out_cost     DECIMAL(12,2) NULL,
  PRIMARY KEY (incident_id),
  KEY idx_incidents_visit (visit_id),
  KEY idx_incidents_guest (guest_id),
  KEY idx_incidents_event (event_type_id),
  KEY idx_incidents_attraction (attraction_id),
  CONSTRAINT fk_inc_guest
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
  CONSTRAINT fk_inc_visit
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
  CONSTRAINT fk_inc_attraction
    FOREIGN KEY (attraction_id) REFERENCES attractions(attraction_id),
  CONSTRAINT fk_inc_event
    FOREIGN KEY (event_type_id) REFERENCES unpleasant_event_types(event_type_id),
  CONSTRAINT fk_inc_claim_policy
    FOREIGN KEY (claimed_policy_id) REFERENCES insurance_policies(policy_id),
  CONSTRAINT ck_inc_severity
    CHECK (severity BETWEEN 1 AND 5),
  CONSTRAINT ck_inc_costs
    CHECK (
      (estimated_cost IS NULL OR estimated_cost >= 0) AND
      (paid_out_cost IS NULL OR paid_out_cost >= 0)
    )
) ENGINE=InnoDB;

-- ============================================================
--  6) FINANCIAL TRANSACTIONS + OPERATING COSTS
-- ============================================================

CREATE TABLE payment_methods (
  payment_method_id BIGINT NOT NULL AUTO_INCREMENT,
  method_name       VARCHAR(40) NOT NULL,
  PRIMARY KEY (payment_method_id),
  UNIQUE KEY uq_payment_method (method_name)
) ENGINE=InnoDB;

CREATE TABLE financial_transactions (
  transaction_id         BIGINT NOT NULL AUTO_INCREMENT,
  transaction_time       DATETIME NOT NULL,
  direction              VARCHAR(10) NOT NULL,
  payment_method_id      BIGINT NOT NULL,
  amount                 DECIMAL(14,2) NOT NULL,
  currency               CHAR(3) NOT NULL DEFAULT 'PLN',
  title                  VARCHAR(500) NULL,
  source_type            VARCHAR(30) NOT NULL,
  source_id              BIGINT NULL,
  entered_by_employee_id BIGINT NULL,
  PRIMARY KEY (transaction_id),
  KEY idx_tx_time (transaction_time),
  KEY idx_tx_method (payment_method_id),
  KEY idx_tx_employee (entered_by_employee_id),
  CONSTRAINT fk_tx_method
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id),
  CONSTRAINT fk_tx_employee
    FOREIGN KEY (entered_by_employee_id) REFERENCES employees(employee_id),
  CONSTRAINT ck_tx_direction
    CHECK (direction IN ('income','expense')),
  CONSTRAINT ck_tx_amount
    CHECK (amount >= 0),
  CONSTRAINT ck_tx_source_type
    CHECK (source_type IN ('ticket','shop_sale','insurance_premium','operating_cost','investment','other'))
) ENGINE=InnoDB;

CREATE TABLE cost_categories (
  cost_category_id BIGINT NOT NULL AUTO_INCREMENT,
  category_name    VARCHAR(150) NOT NULL,
  PRIMARY KEY (cost_category_id),
  UNIQUE KEY uq_cost_categories_name (category_name)
) ENGINE=InnoDB;

CREATE TABLE operating_costs (
  cost_id               BIGINT NOT NULL AUTO_INCREMENT,
  cost_date             DATE NOT NULL,
  cost_category_id      BIGINT NOT NULL,
  amount                DECIMAL(14,2) NOT NULL,
  description           VARCHAR(2000) NULL,
  related_attraction_id BIGINT NULL,
  related_employee_id   BIGINT NULL,
  partner_id            BIGINT NULL,
  transaction_id        BIGINT NULL,
  PRIMARY KEY (cost_id),
  KEY idx_cost_category (cost_category_id),
  KEY idx_cost_attraction (related_attraction_id),
  KEY idx_cost_employee (related_employee_id),
  KEY idx_cost_partner (partner_id),
  UNIQUE KEY uq_cost_transaction (transaction_id),
  CONSTRAINT fk_cost_category
    FOREIGN KEY (cost_category_id) REFERENCES cost_categories(cost_category_id),
  CONSTRAINT fk_cost_attraction
    FOREIGN KEY (related_attraction_id) REFERENCES attractions(attraction_id),
  CONSTRAINT fk_cost_employee
    FOREIGN KEY (related_employee_id) REFERENCES employees(employee_id),
  CONSTRAINT fk_cost_partner
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
  CONSTRAINT fk_cost_transaction
    FOREIGN KEY (transaction_id) REFERENCES financial_transactions(transaction_id),
  CONSTRAINT ck_cost_amount
    CHECK (amount >= 0)
) ENGINE=InnoDB;

-- ============================================================
--  7) PLANNED INVESTMENTS
-- ============================================================

CREATE TABLE planned_investments (
  investment_id        BIGINT NOT NULL AUTO_INCREMENT,
  title                VARCHAR(255) NOT NULL,
  description          VARCHAR(2000) NULL,
  planned_start        DATE NOT NULL,
  planned_end          DATE NULL,
  budget               DECIMAL(14,2) NOT NULL,
  status               VARCHAR(20) NOT NULL,
  partner_id           BIGINT NULL,
  related_attraction_id BIGINT NULL,
  transaction_id       BIGINT NULL,
  PRIMARY KEY (investment_id),
  KEY idx_invest_partner (partner_id),
  KEY idx_invest_attraction (related_attraction_id),
  UNIQUE KEY uq_invest_transaction (transaction_id),
  CONSTRAINT fk_invest_partner
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
  CONSTRAINT fk_invest_attraction
    FOREIGN KEY (related_attraction_id) REFERENCES attractions(attraction_id),
  CONSTRAINT fk_invest_transaction
    FOREIGN KEY (transaction_id) REFERENCES financial_transactions(transaction_id),
  CONSTRAINT ck_invest_budget
    CHECK (budget >= 0),
  CONSTRAINT ck_invest_status
    CHECK (status IN ('planned','approved','in_progress','completed','cancelled')),
  CONSTRAINT ck_invest_dates
    CHECK (planned_end IS NULL OR planned_end >= planned_start)
) ENGINE=InnoDB;

CREATE TABLE investment_milestones (
  milestone_id   BIGINT NOT NULL AUTO_INCREMENT,
  investment_id  BIGINT NOT NULL,
  milestone_name VARCHAR(255) NOT NULL,
  planned_date   DATE NOT NULL,
  done           TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (milestone_id),
  KEY idx_milestone_investment (investment_id),
  CONSTRAINT fk_milestone_investment
    FOREIGN KEY (investment_id) REFERENCES planned_investments(investment_id)
) ENGINE=InnoDB;

-- ============================================================
--  8) SHOP
-- ============================================================

CREATE TABLE product_categories (
  category_id   BIGINT NOT NULL AUTO_INCREMENT,
  category_name VARCHAR(150) NOT NULL,
  PRIMARY KEY (category_id),
  UNIQUE KEY uq_product_categories_name (category_name)
) ENGINE=InnoDB;

CREATE TABLE shop_products (
  product_id           BIGINT NOT NULL AUTO_INCREMENT,
  product_name         VARCHAR(255) NOT NULL,
  category_id          BIGINT NOT NULL,
  is_active            TINYINT(1) NOT NULL DEFAULT 1,
  unit_purchase_cost   DECIMAL(12,2) NOT NULL DEFAULT 0,
  unit_production_cost DECIMAL(12,2) NULL,
  default_partner_id   BIGINT NULL,
  PRIMARY KEY (product_id),
  UNIQUE KEY uq_product_name (product_name),
  KEY idx_product_category (category_id),
  KEY idx_product_partner (default_partner_id),
  CONSTRAINT fk_product_category
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id),
  CONSTRAINT fk_product_partner
    FOREIGN KEY (default_partner_id) REFERENCES partners(partner_id),
  CONSTRAINT ck_product_costs
    CHECK (
      unit_purchase_cost >= 0 AND
      (unit_production_cost IS NULL OR unit_production_cost >= 0)
    )
) ENGINE=InnoDB;

CREATE TABLE shop_price_list (
  product_id  BIGINT NOT NULL,
  valid_from  DATE NOT NULL,
  valid_to    DATE NULL,
  list_price  DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (product_id, valid_from),
  CONSTRAINT fk_shop_price_product
    FOREIGN KEY (product_id) REFERENCES shop_products(product_id),
  CONSTRAINT ck_shop_price_nonneg
    CHECK (list_price >= 0),
  CONSTRAINT ck_shop_price_dates
    CHECK (valid_to IS NULL OR valid_to >= valid_from)
) ENGINE=InnoDB;

CREATE TABLE shop_inventory_movements (
  movement_id   BIGINT NOT NULL AUTO_INCREMENT,
  product_id    BIGINT NOT NULL,
  movement_time DATETIME NOT NULL,
  qty_change    INT NOT NULL,
  unit_cost     DECIMAL(12,2) NULL,
  reason        VARCHAR(20) NOT NULL,
  partner_id    BIGINT NULL,
  PRIMARY KEY (movement_id),
  KEY idx_inv_product (product_id),
  KEY idx_inv_time (movement_time),
  KEY idx_inv_partner (partner_id),
  CONSTRAINT fk_inv_product
    FOREIGN KEY (product_id) REFERENCES shop_products(product_id),
  CONSTRAINT fk_inv_partner
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
  CONSTRAINT ck_inv_unit_cost
    CHECK (unit_cost IS NULL OR unit_cost >= 0),
  CONSTRAINT ck_inv_reason
    CHECK (reason IN ('purchase','sale','spoilage','adjustment'))
) ENGINE=InnoDB;

CREATE TABLE shop_sales (
  sale_id        BIGINT NOT NULL AUTO_INCREMENT,
  sale_time      DATETIME NOT NULL,
  visit_id       BIGINT NULL,
  transaction_id BIGINT NULL,
  PRIMARY KEY (sale_id),
  KEY idx_sale_time (sale_time),
  KEY idx_sale_visit (visit_id),
  UNIQUE KEY uq_sale_transaction (transaction_id),
  CONSTRAINT fk_sale_visit
    FOREIGN KEY (visit_id) REFERENCES visits(visit_id),
  CONSTRAINT fk_sale_transaction
    FOREIGN KEY (transaction_id) REFERENCES financial_transactions(transaction_id)
) ENGINE=InnoDB;

CREATE TABLE shop_sale_items (
  sale_id         BIGINT NOT NULL,
  product_id      BIGINT NOT NULL,
  quantity        INT NOT NULL,
  unit_price_paid DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (sale_id, product_id),
  KEY idx_sale_items_product (product_id),
  CONSTRAINT fk_sale_items_sale
    FOREIGN KEY (sale_id) REFERENCES shop_sales(sale_id),
  CONSTRAINT fk_sale_items_product
    FOREIGN KEY (product_id) REFERENCES shop_products(product_id),
  CONSTRAINT ck_sale_items_qty
    CHECK (quantity > 0),
  CONSTRAINT ck_sale_items_price
    CHECK (unit_price_paid >= 0)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
