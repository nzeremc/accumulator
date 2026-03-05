/**
* author: Vamsi Gangarapu
* project: DOCMP - Accumulator
*/

DROP SCHEMA docmp CASCADE;

CREATE SCHEMA docmp;

CREATE TYPE docmp.program_type AS ENUM (
    'CHAMPVA'
);

CREATE TYPE docmp.status_type AS ENUM (
    'INDIVIDUAL',
    'FAMILY',
    'COSTSHARE'
);

CREATE TYPE docmp.units_type AS ENUM (
    'DOLLAR'
);

CREATE TABLE docmp.sponsor (
    sponsor_id VARCHAR(50),
    sponsor_ssn VARCHAR(100),
    dfn VARCHAR(50) NOT NULL
);

CREATE TABLE docmp.id (
    sponsor_id VARCHAR(50) NOT NULL,
    patient_id VARCHAR(50),
    id_hash VARCHAR(64) NOT NULL,
    patient_ssn VARCHAR(100),
    bfn VARCHAR(50)
);

CREATE TABLE docmp.monetary_accumulator (
    accumulator_id uuid DEFAULT gen_random_uuid(),
    sponsor_id VARCHAR(50) NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    program docmp.program_type,
    accumulator_start_date date DEFAULT date_trunc('year', CURRENT_DATE),
    accumulator_end_date date DEFAULT (
        date_trunc('year', CURRENT_DATE)
        + INTERVAL '1 year'
        - INTERVAL '1 second'
    ),
    individual_deductable numeric(10,2) DEFAULT 0,
    individual_deductable_max numeric(10,2) DEFAULT 50
);

CREATE TABLE docmp.family_monetary_accumulator (
    family_accumulator_id uuid DEFAULT gen_random_uuid(),
    sponsor_id VARCHAR(50) NOT NULL,
    program docmp.program_type,
    accumulator_start_date date DEFAULT date_trunc('year', CURRENT_DATE),
    accumulator_end_date date DEFAULT (
        date_trunc('year', CURRENT_DATE)
        + INTERVAL '1 year'
        - INTERVAL '1 second'
    ),
    family_deductable numeric(10,2) DEFAULT 0,
    family_deductable_max numeric(10,2) DEFAULT 100,
    out_of_pocket numeric(10,2) DEFAULT 0,
    out_of_pocket_max numeric(10,2) DEFAULT 3000
);

CREATE TABLE docmp.claims (
    claim_id uuid,
    accumulator_id uuid,
    sponsor_id VARCHAR(50) NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    type docmp.status_type,
    delta numeric(10,2) NOT NULL,
    claim_number VARCHAR(50),
    start_date_of_service date NOT NULL,
    end_date_of_service date NOT NULL,
    source VARCHAR(50) NOT NULL,
    notes text,
    create_date timestamp DEFAULT CURRENT_TIMESTAMP,
    units docmp.units_type
);

CREATE TABLE docmp.eligibilities (
    eligibility_id uuid DEFAULT gen_random_uuid(),
    sponsor_icn VARCHAR(50) NOT NULL,
    patient_icn VARCHAR(50),
    start_date date,
    end_date date
);

CREATE TABLE docmp.historical_id (
    historical_id uuid DEFAULT gen_random_uuid(),
    sponsor_id VARCHAR(50) NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    old_patient_id VARCHAR(50) NOT NULL
);

CREATE TABLE docmp.icn_crosswalk (
    dfn VARCHAR(70),
    bfn VARCHAR(70),
    icn VARCHAR(70)
);

-- Prevent duplicate sponsors
CREATE UNIQUE INDEX idx_sponsor_pk
ON docmp.sponsor (sponsor_id);

-- Prevent duplicate id_hash
CREATE UNIQUE INDEX idx_id_hash_pk
ON docmp.id (id_hash);

-- Prevent duplicate sponsor/patient combo
CREATE UNIQUE INDEX idx_id_sponsor_patient_unique
ON docmp.id (sponsor_id, patient_id);

-- Required for ON CONFLICT in monetary_accumulator
CREATE UNIQUE INDEX idx_monetary_unique
ON docmp.monetary_accumulator
(patient_id, sponsor_id, accumulator_start_date, accumulator_end_date);

-- Required for ON CONFLICT in family_monetary_accumulator
CREATE UNIQUE INDEX idx_family_accumulator_unique
ON docmp.family_monetary_accumulator
(sponsor_id, accumulator_start_date, accumulator_end_date);