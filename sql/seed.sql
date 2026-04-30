-- =============================================================
-- sql/seed.sql — CarMarket 초기 데이터 (한국 차종 5건)
-- =============================================================
-- 실행: sqlcmd -S localhost -U sa -P "$SA_PWD" -C -i sql/seed.sql
-- =============================================================

USE CarMarket;
GO

-- 기존 데이터 정리
DELETE FROM Inquiries;
DELETE FROM Cars;
DELETE FROM Users;

-- IDENTITY 리셋 (멱등성)
DBCC CHECKIDENT ('Users',     RESEED, 0);
DBCC CHECKIDENT ('Cars',      RESEED, 0);
DBCC CHECKIDENT ('Inquiries', RESEED, 0);
GO

-- =====================================
-- Users — 판매자 3명, 구매자 2명
-- =====================================
INSERT INTO Users (Name, Email, Phone, UserType) VALUES
(N'김판매', 'seller1@test.com', '010-1111-1111', 'seller'),
(N'이판매', 'seller2@test.com', '010-2222-2222', 'seller'),
(N'박판매', 'seller3@test.com', '010-3333-3333', 'seller'),
(N'최구매', 'buyer1@test.com',  '010-4444-4444', 'buyer'),
(N'정구매', 'buyer2@test.com',  '010-5555-5555', 'buyer');
GO

-- =====================================
-- Cars — 한국 인기 차종 5건
-- =====================================
INSERT INTO Cars (SellerId, Brand, Model, Year, Price, Mileage, FuelType, Description) VALUES
(1, N'현대',     N'쏘나타 DN8',  2021, 18500000, 45000, N'가솔린', N'무사고, 1인 소유, 정기점검 완료'),
(1, N'기아',     N'K5 3세대',    2020, 16000000, 62000, N'가솔린', N'썬루프, 어라운드뷰 옵션'),
(2, N'BMW',     N'520d (G30)',  2019, 28000000, 78000, N'디젤',   N'풀옵션, 가죽시트, 무사고'),
(2, N'벤츠',     N'E300 (W213)', 2020, 38000000, 55000, N'가솔린', N'AMG 패키지, 1인 소유'),
(3, N'제네시스', N'G80 (RG3)',   2022, 45000000, 28000, N'가솔린', N'신차급, 출고 1년');
GO

-- =====================================
-- 검증
-- =====================================
SELECT
    c.Brand, c.Model, c.Year,
    FORMAT(c.Price, 'N0') AS Price,
    FORMAT(c.Mileage, 'N0') AS Mileage,
    u.Name AS Seller
FROM Cars c
JOIN Users u ON c.SellerId = u.UserId
ORDER BY c.Price DESC;
GO

PRINT '✅ seed.sql 실행 완료 — Users 5건, Cars 5건';
GO
