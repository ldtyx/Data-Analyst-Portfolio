-- ============================================================
-- PROJECT: Telco Customer Churn Data Cleaning & Transformation
-- GOAL: Menyiapkan data mentah agar siap divisualisasikan di Tableau
-- ============================================================

-- 1. PILIH DATABASE
USE telco_analysis; 


-- 2. DATA PROFILING
-- Cek struktur tabel dan tipe data awal
DESC telco_churn;

-- Cek jumlah total baris
SELECT COUNT(*) FROM telco_churn;

-- Cek apakah ada ID pelanggan yang duplikat
SELECT CustomerID, COUNT(*) 
FROM telco_churn 
GROUP BY CustomerID 
HAVING COUNT(*) > 1;


-- 3. DATA CLEANING
-- Mematikan Safe Update Mode agar bisa mengubah data tanpa Primary Key
SET SQL_SAFE_UPDATES = 0;

-- Mengubah data kosong (spasi) pada Total Charges menjadi '0'
UPDATE telco_churn 
SET `Total Charges` = '0' 
WHERE `Total Charges` = ' ';

-- Mengaktifkan kembali Safe Update Mode
SET SQL_SAFE_UPDATES = 1;


-- 4. TRANSFORMASI TIPE DATA (DATA TRANSFORMATION)
-- Mengubah kolom teks menjadi Decimal untuk perhitungan matematis dan pemetaan
ALTER TABLE telco_churn 
MODIFY COLUMN `Total Charges` DECIMAL(15,2),
MODIFY COLUMN `Monthly Charges` DECIMAL(10,2),
MODIFY COLUMN `Latitude` DECIMAL(10,6),
MODIFY COLUMN `Longitude` DECIMAL(11,6);


-- 5. VERIFIKASI AKHIR
-- Memastikan tidak ada lagi nilai kosong pada range angka
SELECT 
    MIN(`Total Charges`) AS min_total, 
    MAX(`Total Charges`) AS max_total,
    MIN(`Monthly Charges`) AS min_monthly
FROM telco_churn;

-- Memastikan struktur tabel akhir sudah benar
DESC telco_churn;
