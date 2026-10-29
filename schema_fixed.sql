-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: aibtcquantlandia
-- ------------------------------------------------------
-- Server version	8.0.44


/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- =====================================================
-- Table structure for table `attractions`
-- =====================================================

DROP TABLE IF EXISTS `attractions`;
CREATE TABLE `attractions` (
  `attraction_id` bigint NOT NULL AUTO_INCREMENT,
  `attraction_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `attraction_type_id` bigint NOT NULL,
  `purchase_date` date NOT NULL,
  `purchase_cost` decimal(14,2) NOT NULL,
  `opened_on` date NOT NULL,
  `closed_on` date DEFAULT NULL,
  `status` varchar(30) COLLATE utf8mb4_polish_ci NOT NULL,
  `min_age` int DEFAULT NULL,
  `min_height_cm` int DEFAULT NULL,
  `is_vr_available` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`attraction_id`),
  UNIQUE KEY `uq_attractions_name` (`attraction_name`),
  KEY `idx_attractions_type` (`attraction_type_id`),
  CONSTRAINT `fk_attractions_type`
    FOREIGN KEY (`attraction_type_id`)
    REFERENCES `attraction_types` (`attraction_type_id`)
    ON UPDATE CASCADE,
  CONSTRAINT `ck_attraction_dates`
    CHECK (((`closed_on` IS NULL) OR (`closed_on` >= `opened_on`))),
  CONSTRAINT `ck_attraction_min_age`
    CHECK (((`min_age` IS NULL) OR (`min_age` >= 0))),
  CONSTRAINT `ck_attraction_min_height`
    CHECK (((`min_height_cm` IS NULL) OR (`min_height_cm` >= 0))),
  CONSTRAINT `ck_attraction_purchase_cost`
    CHECK (`purchase_cost` >= 0),
  CONSTRAINT `ck_attraction_status`
    CHECK (`status` IN ('operational','maintenance','out_of_service'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;

-- =====================================================
-- Table structure for table `attraction_failures`
-- =====================================================

DROP TABLE IF EXISTS `attraction_failures`;
CREATE TABLE `attraction_failures` (
  `failure_id` bigint NOT NULL AUTO_INCREMENT,
  `attraction_id` bigint NOT NULL,
  `reported_at` datetime NOT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `severity` int NOT NULL,
  `description` varchar(2000) COLLATE utf8mb4_polish_ci NOT NULL,
  `root_cause` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `repair_cost` decimal(12,2) NOT NULL DEFAULT '0.00',
  `resolved_by_employee_id` bigint DEFAULT NULL,
  `resolved_by_partner_id` bigint DEFAULT NULL,
  PRIMARY KEY (`failure_id`),
  KEY `idx_failures_attr` (`attraction_id`),
  KEY `idx_failures_reported` (`reported_at`),
  KEY `idx_failures_emp` (`resolved_by_employee_id`),
  KEY `idx_failures_partner` (`resolved_by_partner_id`),
  CONSTRAINT `fk_failures_attraction`
    FOREIGN KEY (`attraction_id`)
    REFERENCES `attractions` (`attraction_id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_failures_employee`
    FOREIGN KEY (`resolved_by_employee_id`)
    REFERENCES `employees` (`employee_id`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_failures_partner`
    FOREIGN KEY (`resolved_by_partner_id`)
    REFERENCES `partners` (`partner_id`)
    ON DELETE SET NULL,
  CONSTRAINT `ck_failure_dates`
    CHECK (((`resolved_at` IS NULL) OR (`resolved_at` >= `reported_at`))),
  CONSTRAINT `ck_failure_repair_cost`
    CHECK (`repair_cost` >= 0),
  CONSTRAINT `ck_failure_severity`
    CHECK (`severity` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;

-- =====================================================

DROP TABLE IF EXISTS `attraction_inspections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attraction_inspections` (
  `inspection_id` bigint NOT NULL AUTO_INCREMENT,
  `attraction_id` bigint NOT NULL,
  `inspection_date` date NOT NULL,
  `result` varchar(20) COLLATE utf8mb4_polish_ci NOT NULL,
  `notes` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `cost` decimal(12,2) NOT NULL DEFAULT '0.00',
  `performed_by_employee_id` bigint DEFAULT NULL,
  `performed_by_partner_id` bigint DEFAULT NULL,
  PRIMARY KEY (`inspection_id`),
  KEY `idx_inspections_attr` (`attraction_id`),
  KEY `idx_inspections_emp` (`performed_by_employee_id`),
  KEY `idx_inspections_partner` (`performed_by_partner_id`),
  CONSTRAINT `fk_inspections_attraction` FOREIGN KEY (`attraction_id`) REFERENCES `attractions` (`attraction_id`),
  CONSTRAINT `fk_inspections_employee` FOREIGN KEY (`performed_by_employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `fk_inspections_partner` FOREIGN KEY (`performed_by_partner_id`) REFERENCES `partners` (`partner_id`),
  CONSTRAINT `ck_inspection_cost` CHECK ((`cost` >= 0)),
  CONSTRAINT `ck_inspection_performer` CHECK (((`performed_by_employee_id` is not null) or (`performed_by_partner_id` is not null))),
  CONSTRAINT `ck_inspection_result` CHECK ((`result` in (_utf8mb4'pass',_utf8mb4'fail',_utf8mb4'conditional')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attraction_sessions`
--

DROP TABLE IF EXISTS `attraction_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attraction_sessions` (
  `session_id` bigint NOT NULL AUTO_INCREMENT,
  `visit_id` bigint NOT NULL,
  `attraction_id` bigint NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime DEFAULT NULL,
  `mode_id` bigint NOT NULL,
  `completed` tinyint(1) NOT NULL DEFAULT '1',
  `operator_employee_id` bigint DEFAULT NULL,
  PRIMARY KEY (`session_id`),
  KEY `idx_sessions_visit` (`visit_id`),
  KEY `idx_sessions_attr` (`attraction_id`),
  KEY `idx_sessions_mode` (`mode_id`),
  KEY `idx_sessions_operator` (`operator_employee_id`),
  CONSTRAINT `fk_sessions_attraction` FOREIGN KEY (`attraction_id`) REFERENCES `attractions` (`attraction_id`),
  CONSTRAINT `fk_sessions_mode` FOREIGN KEY (`mode_id`) REFERENCES `session_modes` (`mode_id`),
  CONSTRAINT `fk_sessions_operator` FOREIGN KEY (`operator_employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `fk_sessions_visit` FOREIGN KEY (`visit_id`) REFERENCES `visits` (`visit_id`),
  CONSTRAINT `ck_sessions_times` CHECK (((`end_time` is null) or (`end_time` >= `start_time`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attraction_types`
--

DROP TABLE IF EXISTS `attraction_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attraction_types` (
  `attraction_type_id` bigint NOT NULL AUTO_INCREMENT,
  `type_name` varchar(150) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`attraction_type_id`),
  UNIQUE KEY `uq_attr_types_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `attractions`
--

DROP TABLE IF EXISTS `attractions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attractions` (
  `attraction_id` bigint NOT NULL AUTO_INCREMENT,
  `attraction_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `attraction_type_id` bigint NOT NULL,
  `purchase_date` date NOT NULL,
  `purchase_cost` decimal(14,2) NOT NULL,
  `opened_on` date NOT NULL,
  `closed_on` date DEFAULT NULL,
  `status` varchar(30) COLLATE utf8mb4_polish_ci NOT NULL,
  `min_age` int DEFAULT NULL,
  `min_height_cm` int DEFAULT NULL,
  `is_vr_available` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`attraction_id`),
  UNIQUE KEY `uq_attractions_name` (`attraction_name`),
  KEY `idx_attractions_type` (`attraction_type_id`),
  CONSTRAINT `fk_attractions_type` FOREIGN KEY (`attraction_type_id`) REFERENCES `attraction_types` (`attraction_type_id`),
  CONSTRAINT `ck_attraction_dates` CHECK (((`closed_on` is null) or (`closed_on` >= `opened_on`))),
  CONSTRAINT `ck_attraction_min_age` CHECK (((`min_age` is null) or (`min_age` >= 0))),
  CONSTRAINT `ck_attraction_min_height` CHECK (((`min_height_cm` is null) or (`min_height_cm` >= 0))),
  CONSTRAINT `ck_attraction_purchase_cost` CHECK ((`purchase_cost` >= 0)),
  CONSTRAINT `ck_attraction_status` CHECK ((`status` in (_utf8mb4'operational',_utf8mb4'maintenance',_utf8mb4'out_of_service')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `channels`
--

DROP TABLE IF EXISTS `channels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `channels` (
  `channel_id` bigint NOT NULL AUTO_INCREMENT,
  `channel_name` varchar(40) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`channel_id`),
  UNIQUE KEY `uq_channels_name` (`channel_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cost_categories`
--

DROP TABLE IF EXISTS `cost_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cost_categories` (
  `cost_category_id` bigint NOT NULL AUTO_INCREMENT,
  `category_name` varchar(150) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`cost_category_id`),
  UNIQUE KEY `uq_cost_categories_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_salary_history`
--

DROP TABLE IF EXISTS `employee_salary_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_salary_history` (
  `employee_id` bigint NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `salary_gross_monthly` decimal(12,2) NOT NULL,
  PRIMARY KEY (`employee_id`,`valid_from`),
  CONSTRAINT `fk_salary_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `ck_salary_dates` CHECK (((`valid_to` is null) or (`valid_to` >= `valid_from`))),
  CONSTRAINT `ck_salary_nonneg` CHECK ((`salary_gross_monthly` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employees`
--

DROP TABLE IF EXISTS `employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employees` (
  `employee_id` bigint NOT NULL AUTO_INCREMENT,
  `first_name` varchar(120) COLLATE utf8mb4_polish_ci NOT NULL,
  `last_name` varchar(120) COLLATE utf8mb4_polish_ci NOT NULL,
  `birth_date` date NOT NULL,
  `hire_date` date NOT NULL,
  `termination_date` date DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `phone` varchar(50) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `status` varchar(20) COLLATE utf8mb4_polish_ci NOT NULL,
  `position_id` bigint NOT NULL,
  PRIMARY KEY (`employee_id`),
  UNIQUE KEY `uq_employees_email` (`email`),
  KEY `idx_employees_position` (`position_id`),
  CONSTRAINT `fk_employees_position` FOREIGN KEY (`position_id`) REFERENCES `positions` (`position_id`),
  CONSTRAINT `ck_employees_dates` CHECK (((`termination_date` is null) or (`termination_date` >= `hire_date`))),
  CONSTRAINT `ck_employees_status` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'terminated')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `financial_transactions`
--

DROP TABLE IF EXISTS `financial_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `financial_transactions` (
  `transaction_id` bigint NOT NULL AUTO_INCREMENT,
  `transaction_time` datetime NOT NULL,
  `direction` varchar(10) COLLATE utf8mb4_polish_ci NOT NULL,
  `payment_method_id` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `currency` char(3) COLLATE utf8mb4_polish_ci NOT NULL DEFAULT 'PLN',
  `title` varchar(500) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `source_type` varchar(30) COLLATE utf8mb4_polish_ci NOT NULL,
  `source_id` bigint DEFAULT NULL,
  `entered_by_employee_id` bigint DEFAULT NULL,
  PRIMARY KEY (`transaction_id`),
  KEY `idx_tx_time` (`transaction_time`),
  KEY `idx_tx_method` (`payment_method_id`),
  KEY `idx_tx_employee` (`entered_by_employee_id`),
  CONSTRAINT `fk_tx_employee` FOREIGN KEY (`entered_by_employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `fk_tx_method` FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`payment_method_id`),
  CONSTRAINT `ck_tx_amount` CHECK ((`amount` >= 0)),
  CONSTRAINT `ck_tx_direction` CHECK ((`direction` in (_utf8mb4'income',_utf8mb4'expense'))),
  CONSTRAINT `ck_tx_source_type` CHECK ((`source_type` in (_utf8mb4'ticket',_utf8mb4'shop_sale',_utf8mb4'insurance_premium',_utf8mb4'operating_cost',_utf8mb4'investment',_utf8mb4'other')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `guests`
--

DROP TABLE IF EXISTS `guests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `guests` (
  `guest_id` bigint NOT NULL AUTO_INCREMENT,
  `first_name` varchar(120) COLLATE utf8mb4_polish_ci NOT NULL,
  `last_name` varchar(120) COLLATE utf8mb4_polish_ci NOT NULL,
  `birth_date` date NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guest_id`),
  UNIQUE KEY `uq_guests_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `incidents`
--

DROP TABLE IF EXISTS `incidents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incidents` (
  `incident_id` bigint NOT NULL AUTO_INCREMENT,
  `occurred_at` datetime NOT NULL,
  `guest_id` bigint NOT NULL,
  `visit_id` bigint NOT NULL,
  `attraction_id` bigint DEFAULT NULL,
  `event_type_id` bigint NOT NULL,
  `severity` int NOT NULL,
  `description` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `estimated_cost` decimal(12,2) DEFAULT NULL,
  `claimed_policy_id` bigint DEFAULT NULL,
  `paid_out_cost` decimal(12,2) DEFAULT NULL,
  PRIMARY KEY (`incident_id`),
  KEY `idx_incidents_visit` (`visit_id`),
  KEY `idx_incidents_guest` (`guest_id`),
  KEY `idx_incidents_event` (`event_type_id`),
  KEY `idx_incidents_attraction` (`attraction_id`),
  KEY `fk_inc_claim_policy` (`claimed_policy_id`),
  CONSTRAINT `fk_inc_attraction` FOREIGN KEY (`attraction_id`) REFERENCES `attractions` (`attraction_id`),
  CONSTRAINT `fk_inc_claim_policy` FOREIGN KEY (`claimed_policy_id`) REFERENCES `insurance_policies` (`policy_id`),
  CONSTRAINT `fk_inc_event` FOREIGN KEY (`event_type_id`) REFERENCES `unpleasant_event_types` (`event_type_id`),
  CONSTRAINT `fk_inc_guest` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`),
  CONSTRAINT `fk_inc_visit` FOREIGN KEY (`visit_id`) REFERENCES `visits` (`visit_id`),
  CONSTRAINT `ck_inc_costs` CHECK ((((`estimated_cost` is null) or (`estimated_cost` >= 0)) and ((`paid_out_cost` is null) or (`paid_out_cost` >= 0)))),
  CONSTRAINT `ck_inc_severity` CHECK ((`severity` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `insurance_policies`
--

DROP TABLE IF EXISTS `insurance_policies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `insurance_policies` (
  `policy_id` bigint NOT NULL AUTO_INCREMENT,
  `policy_number` varchar(80) COLLATE utf8mb4_polish_ci NOT NULL,
  `guest_id` bigint NOT NULL,
  `visit_id` bigint DEFAULT NULL,
  `insurer_id` bigint NOT NULL,
  `policy_type_id` bigint NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date NOT NULL,
  `premium_paid` decimal(12,2) NOT NULL,
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `uq_policy_number` (`policy_number`),
  KEY `idx_policy_guest` (`guest_id`),
  KEY `idx_policy_visit` (`visit_id`),
  KEY `idx_policy_insurer` (`insurer_id`),
  KEY `idx_policy_type` (`policy_type_id`),
  CONSTRAINT `fk_policy_guest` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`),
  CONSTRAINT `fk_policy_insurer` FOREIGN KEY (`insurer_id`) REFERENCES `insurers` (`insurer_id`),
  CONSTRAINT `fk_policy_type` FOREIGN KEY (`policy_type_id`) REFERENCES `policy_types` (`policy_type_id`),
  CONSTRAINT `fk_policy_visit` FOREIGN KEY (`visit_id`) REFERENCES `visits` (`visit_id`),
  CONSTRAINT `ck_policy_dates` CHECK ((`valid_to` >= `valid_from`)),
  CONSTRAINT `ck_policy_premium` CHECK ((`premium_paid` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `insurers`
--

DROP TABLE IF EXISTS `insurers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `insurers` (
  `insurer_id` bigint NOT NULL AUTO_INCREMENT,
  `insurer_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`insurer_id`),
  UNIQUE KEY `uq_insurers_name` (`insurer_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `investment_milestones`
--

DROP TABLE IF EXISTS `investment_milestones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `investment_milestones` (
  `milestone_id` bigint NOT NULL AUTO_INCREMENT,
  `investment_id` bigint NOT NULL,
  `milestone_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `planned_date` date NOT NULL,
  `done` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`milestone_id`),
  KEY `idx_milestone_investment` (`investment_id`),
  CONSTRAINT `fk_milestone_investment` FOREIGN KEY (`investment_id`) REFERENCES `planned_investments` (`investment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `operating_costs`
--

DROP TABLE IF EXISTS `operating_costs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operating_costs` (
  `cost_id` bigint NOT NULL AUTO_INCREMENT,
  `cost_date` date NOT NULL,
  `cost_category_id` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `description` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `related_attraction_id` bigint DEFAULT NULL,
  `related_employee_id` bigint DEFAULT NULL,
  `partner_id` bigint DEFAULT NULL,
  `transaction_id` bigint DEFAULT NULL,
  PRIMARY KEY (`cost_id`),
  UNIQUE KEY `uq_cost_transaction` (`transaction_id`),
  KEY `idx_cost_category` (`cost_category_id`),
  KEY `idx_cost_attraction` (`related_attraction_id`),
  KEY `idx_cost_employee` (`related_employee_id`),
  KEY `idx_cost_partner` (`partner_id`),
  CONSTRAINT `fk_cost_attraction` FOREIGN KEY (`related_attraction_id`) REFERENCES `attractions` (`attraction_id`),
  CONSTRAINT `fk_cost_category` FOREIGN KEY (`cost_category_id`) REFERENCES `cost_categories` (`cost_category_id`),
  CONSTRAINT `fk_cost_employee` FOREIGN KEY (`related_employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `fk_cost_partner` FOREIGN KEY (`partner_id`) REFERENCES `partners` (`partner_id`),
  CONSTRAINT `fk_cost_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `financial_transactions` (`transaction_id`),
  CONSTRAINT `ck_cost_amount` CHECK ((`amount` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `partner_contracts`
--

DROP TABLE IF EXISTS `partner_contracts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `partner_contracts` (
  `contract_id` bigint NOT NULL AUTO_INCREMENT,
  `partner_id` bigint NOT NULL,
  `contract_type` varchar(30) COLLATE utf8mb4_polish_ci NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `details` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  PRIMARY KEY (`contract_id`),
  KEY `idx_contracts_partner` (`partner_id`),
  CONSTRAINT `fk_contracts_partner` FOREIGN KEY (`partner_id`) REFERENCES `partners` (`partner_id`),
  CONSTRAINT `ck_contract_dates` CHECK (((`valid_to` is null) or (`valid_to` >= `valid_from`))),
  CONSTRAINT `ck_contract_type` CHECK ((`contract_type` in (_utf8mb4'maintenance',_utf8mb4'vr_provider',_utf8mb4'insurer',_utf8mb4'supplier',_utf8mb4'other')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `partners`
--

DROP TABLE IF EXISTS `partners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `partners` (
  `partner_id` bigint NOT NULL AUTO_INCREMENT,
  `partner_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `tax_id` varchar(50) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `address` varchar(500) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  PRIMARY KEY (`partner_id`),
  UNIQUE KEY `uq_partners_name` (`partner_name`),
  UNIQUE KEY `uq_partners_tax` (`tax_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment_methods`
--

DROP TABLE IF EXISTS `payment_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_methods` (
  `payment_method_id` bigint NOT NULL AUTO_INCREMENT,
  `method_name` varchar(40) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`payment_method_id`),
  UNIQUE KEY `uq_payment_method` (`method_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `planned_investments`
--

DROP TABLE IF EXISTS `planned_investments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `planned_investments` (
  `investment_id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `description` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  `planned_start` date NOT NULL,
  `planned_end` date DEFAULT NULL,
  `budget` decimal(14,2) NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_polish_ci NOT NULL,
  `partner_id` bigint DEFAULT NULL,
  `related_attraction_id` bigint DEFAULT NULL,
  `transaction_id` bigint DEFAULT NULL,
  PRIMARY KEY (`investment_id`),
  UNIQUE KEY `uq_invest_transaction` (`transaction_id`),
  KEY `idx_invest_partner` (`partner_id`),
  KEY `idx_invest_attraction` (`related_attraction_id`),
  CONSTRAINT `fk_invest_attraction` FOREIGN KEY (`related_attraction_id`) REFERENCES `attractions` (`attraction_id`),
  CONSTRAINT `fk_invest_partner` FOREIGN KEY (`partner_id`) REFERENCES `partners` (`partner_id`),
  CONSTRAINT `fk_invest_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `financial_transactions` (`transaction_id`),
  CONSTRAINT `ck_invest_budget` CHECK ((`budget` >= 0)),
  CONSTRAINT `ck_invest_dates` CHECK (((`planned_end` is null) or (`planned_end` >= `planned_start`))),
  CONSTRAINT `ck_invest_status` CHECK ((`status` in (_utf8mb4'planned',_utf8mb4'approved',_utf8mb4'in_progress',_utf8mb4'completed',_utf8mb4'cancelled')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `policy_coverages`
--

DROP TABLE IF EXISTS `policy_coverages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `policy_coverages` (
  `policy_id` bigint NOT NULL,
  `event_type_id` bigint NOT NULL,
  `coverage_limit` decimal(12,2) DEFAULT NULL,
  `deductible` decimal(12,2) DEFAULT NULL,
  PRIMARY KEY (`policy_id`,`event_type_id`),
  KEY `fk_cov_event` (`event_type_id`),
  CONSTRAINT `fk_cov_event` FOREIGN KEY (`event_type_id`) REFERENCES `unpleasant_event_types` (`event_type_id`),
  CONSTRAINT `fk_cov_policy` FOREIGN KEY (`policy_id`) REFERENCES `insurance_policies` (`policy_id`),
  CONSTRAINT `ck_cov_deductible` CHECK (((`deductible` is null) or (`deductible` >= 0))),
  CONSTRAINT `ck_cov_limit` CHECK (((`coverage_limit` is null) or (`coverage_limit` >= 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `policy_types`
--

DROP TABLE IF EXISTS `policy_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `policy_types` (
  `policy_type_id` bigint NOT NULL AUTO_INCREMENT,
  `type_name` varchar(120) COLLATE utf8mb4_polish_ci NOT NULL,
  `description` varchar(2000) COLLATE utf8mb4_polish_ci DEFAULT NULL,
  PRIMARY KEY (`policy_type_id`),
  UNIQUE KEY `uq_policy_types_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `positions`
--

DROP TABLE IF EXISTS `positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `positions` (
  `position_id` bigint NOT NULL AUTO_INCREMENT,
  `position_name` varchar(150) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`position_id`),
  UNIQUE KEY `uq_positions_name` (`position_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_categories`
--

DROP TABLE IF EXISTS `product_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_categories` (
  `category_id` bigint NOT NULL AUTO_INCREMENT,
  `category_name` varchar(150) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uq_product_categories_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session_modes`
--

DROP TABLE IF EXISTS `session_modes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `session_modes` (
  `mode_id` bigint NOT NULL AUTO_INCREMENT,
  `mode_name` varchar(40) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`mode_id`),
  UNIQUE KEY `uq_session_modes_name` (`mode_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shop_inventory_movements`
--

DROP TABLE IF EXISTS `shop_inventory_movements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_inventory_movements` (
  `movement_id` bigint NOT NULL AUTO_INCREMENT,
  `product_id` bigint NOT NULL,
  `movement_time` datetime NOT NULL,
  `qty_change` int NOT NULL,
  `unit_cost` decimal(12,2) DEFAULT NULL,
  `reason` varchar(20) COLLATE utf8mb4_polish_ci NOT NULL,
  `partner_id` bigint DEFAULT NULL,
  PRIMARY KEY (`movement_id`),
  KEY `idx_inv_product` (`product_id`),
  KEY `idx_inv_time` (`movement_time`),
  KEY `idx_inv_partner` (`partner_id`),
  CONSTRAINT `fk_inv_partner` FOREIGN KEY (`partner_id`) REFERENCES `partners` (`partner_id`),
  CONSTRAINT `fk_inv_product` FOREIGN KEY (`product_id`) REFERENCES `shop_products` (`product_id`),
  CONSTRAINT `ck_inv_reason` CHECK ((`reason` in (_utf8mb4'purchase',_utf8mb4'sale',_utf8mb4'spoilage',_utf8mb4'adjustment'))),
  CONSTRAINT `ck_inv_unit_cost` CHECK (((`unit_cost` is null) or (`unit_cost` >= 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shop_price_list`
--

DROP TABLE IF EXISTS `shop_price_list`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_price_list` (
  `product_id` bigint NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `list_price` decimal(12,2) NOT NULL,
  PRIMARY KEY (`product_id`,`valid_from`),
  CONSTRAINT `fk_shop_price_product` FOREIGN KEY (`product_id`) REFERENCES `shop_products` (`product_id`),
  CONSTRAINT `ck_shop_price_dates` CHECK (((`valid_to` is null) or (`valid_to` >= `valid_from`))),
  CONSTRAINT `ck_shop_price_nonneg` CHECK ((`list_price` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shop_products`
--

DROP TABLE IF EXISTS `shop_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_products` (
  `product_id` bigint NOT NULL AUTO_INCREMENT,
  `product_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `category_id` bigint NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `unit_purchase_cost` decimal(12,2) NOT NULL DEFAULT '0.00',
  `unit_production_cost` decimal(12,2) DEFAULT NULL,
  `default_partner_id` bigint DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `uq_product_name` (`product_name`),
  KEY `idx_product_category` (`category_id`),
  KEY `idx_product_partner` (`default_partner_id`),
  CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `product_categories` (`category_id`),
  CONSTRAINT `fk_product_partner` FOREIGN KEY (`default_partner_id`) REFERENCES `partners` (`partner_id`),
  CONSTRAINT `ck_product_costs` CHECK (((`unit_purchase_cost` >= 0) and ((`unit_production_cost` is null) or (`unit_production_cost` >= 0))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shop_sale_items`
--

DROP TABLE IF EXISTS `shop_sale_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_sale_items` (
  `sale_id` bigint NOT NULL,
  `product_id` bigint NOT NULL,
  `quantity` int NOT NULL,
  `unit_price_paid` decimal(12,2) NOT NULL,
  PRIMARY KEY (`sale_id`,`product_id`),
  KEY `idx_sale_items_product` (`product_id`),
  CONSTRAINT `fk_sale_items_product` FOREIGN KEY (`product_id`) REFERENCES `shop_products` (`product_id`),
  CONSTRAINT `fk_sale_items_sale` FOREIGN KEY (`sale_id`) REFERENCES `shop_sales` (`sale_id`),
  CONSTRAINT `ck_sale_items_price` CHECK ((`unit_price_paid` >= 0)),
  CONSTRAINT `ck_sale_items_qty` CHECK ((`quantity` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shop_sales`
--

DROP TABLE IF EXISTS `shop_sales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shop_sales` (
  `sale_id` bigint NOT NULL AUTO_INCREMENT,
  `sale_time` datetime NOT NULL,
  `visit_id` bigint DEFAULT NULL,
  `transaction_id` bigint DEFAULT NULL,
  PRIMARY KEY (`sale_id`),
  UNIQUE KEY `uq_sale_transaction` (`transaction_id`),
  KEY `idx_sale_time` (`sale_time`),
  KEY `idx_sale_visit` (`visit_id`),
  CONSTRAINT `fk_sale_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `financial_transactions` (`transaction_id`),
  CONSTRAINT `fk_sale_visit` FOREIGN KEY (`visit_id`) REFERENCES `visits` (`visit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ticket_price_list`
--

DROP TABLE IF EXISTS `ticket_price_list`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_price_list` (
  `ticket_type_id` bigint NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `price` decimal(12,2) NOT NULL,
  PRIMARY KEY (`ticket_type_id`,`valid_from`),
  CONSTRAINT `fk_ticket_price_type` FOREIGN KEY (`ticket_type_id`) REFERENCES `ticket_types` (`ticket_type_id`),
  CONSTRAINT `ck_ticket_price_dates` CHECK (((`valid_to` is null) or (`valid_to` >= `valid_from`))),
  CONSTRAINT `ck_ticket_price_nonneg` CHECK ((`price` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ticket_types`
--

DROP TABLE IF EXISTS `ticket_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_types` (
  `ticket_type_id` bigint NOT NULL AUTO_INCREMENT,
  `type_name` varchar(120) COLLATE utf8mb4_polish_ci NOT NULL,
  PRIMARY KEY (`ticket_type_id`),
  UNIQUE KEY `uq_ticket_types_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tickets`
--

DROP TABLE IF EXISTS `tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tickets` (
  `ticket_id` bigint NOT NULL AUTO_INCREMENT,
  `visit_id` bigint NOT NULL,
  `ticket_type_id` bigint NOT NULL,
  `purchased_at` datetime NOT NULL,
  `price_paid` decimal(12,2) NOT NULL,
  `currency` char(3) COLLATE utf8mb4_polish_ci NOT NULL DEFAULT 'PLN',
  PRIMARY KEY (`ticket_id`),
  KEY `idx_tickets_visit` (`visit_id`),
  KEY `idx_tickets_type` (`ticket_type_id`),
  CONSTRAINT `fk_tickets_type` FOREIGN KEY (`ticket_type_id`) REFERENCES `ticket_types` (`ticket_type_id`),
  CONSTRAINT `fk_tickets_visit` FOREIGN KEY (`visit_id`) REFERENCES `visits` (`visit_id`),
  CONSTRAINT `ck_tickets_price_paid` CHECK ((`price_paid` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unpleasant_event_types`
--

DROP TABLE IF EXISTS `unpleasant_event_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unpleasant_event_types` (
  `event_type_id` bigint NOT NULL AUTO_INCREMENT,
  `event_name` varchar(255) COLLATE utf8mb4_polish_ci NOT NULL,
  `default_severity` int NOT NULL,
  PRIMARY KEY (`event_type_id`),
  UNIQUE KEY `uq_event_name` (`event_name`),
  CONSTRAINT `ck_event_default_sev` CHECK ((`default_severity` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visits`
--

DROP TABLE IF EXISTS `visits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `visits` (
  `visit_id` bigint NOT NULL AUTO_INCREMENT,
  `guest_id` bigint NOT NULL,
  `visit_date` date NOT NULL,
  `enter_time` datetime NOT NULL,
  `exit_time` datetime DEFAULT NULL,
  `channel_id` bigint NOT NULL,
  PRIMARY KEY (`visit_id`),
  KEY `idx_visits_guest` (`guest_id`),
  KEY `idx_visits_channel` (`channel_id`),
  CONSTRAINT `fk_visits_channel` FOREIGN KEY (`channel_id`) REFERENCES `channels` (`channel_id`),
  CONSTRAINT `fk_visits_guest` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`),
  CONSTRAINT `ck_visits_times` CHECK (((`exit_time` is null) or (`exit_time` >= `enter_time`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;

/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-04 15:17:24
