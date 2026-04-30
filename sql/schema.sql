-- =============================================================
-- sql/schema.sql — CarMarket 데이터베이스 스키마
-- =============================================================
-- 실행: sqlcmd -S localhost -U sa -P "$SA_PWD" -C -i sql/schema.sql
-- =============================================================

IF DB_ID('CarMarket') IS NULL
BEGIN
    CREATE DATABASE CarMarket;
END;
GO

USE CarMarket;
GO

-- 기존 테이블 정리 (멱등성)
IF OBJECT_ID('Inquiries', 'U') IS NOT NULL DROP TABLE Inquiries;
IF OBJECT_ID('Cars',      'U') IS NOT NULL DROP TABLE Cars;
IF OBJECT_ID('Users',     'U') IS NOT NULL DROP TABLE Users;
GO

-- =====================================
-- Users — 판매자 / 구매자
-- =====================================
CREATE TABLE Users (
    UserId    INT IDENTITY(1,1) PRIMARY KEY,
    Name      NVARCHAR(100)  NOT NULL,
    Email     NVARCHAR(200)  NOT NULL UNIQUE,
    Phone     NVARCHAR(20),
    UserType  NVARCHAR(10)   NOT NULL DEFAULT 'both'
              CHECK (UserType IN ('seller', 'buyer', 'both')),
    CreatedAt DATETIME2      DEFAULT SYSUTCDATETIME()
);
GO

-- =====================================
-- Cars — 매물
-- =====================================
CREATE TABLE Cars (
    CarId       INT IDENTITY(1,1) PRIMARY KEY,
    SellerId    INT            NOT NULL FOREIGN KEY REFERENCES Users(UserId),
    Brand       NVARCHAR(50)   NOT NULL,
    Model       NVARCHAR(100)  NOT NULL,
    Year        INT            NOT NULL,
    Price       DECIMAL(12, 0) NOT NULL,
    Mileage     INT            NOT NULL,
    FuelType    NVARCHAR(20),
    Description NVARCHAR(MAX),
    Status      NVARCHAR(20)   NOT NULL DEFAULT 'available'
                CHECK (Status IN ('available', 'reserved', 'sold')),
    CreatedAt   DATETIME2      DEFAULT SYSUTCDATETIME()
);
GO

-- =====================================
-- Inquiries — 문의
-- =====================================
CREATE TABLE Inquiries (
    InquiryId INT IDENTITY(1,1) PRIMARY KEY,
    CarId     INT            NOT NULL FOREIGN KEY REFERENCES Cars(CarId),
    BuyerId   INT            NOT NULL FOREIGN KEY REFERENCES Users(UserId),
    Message   NVARCHAR(1000) NOT NULL,
    CreatedAt DATETIME2      DEFAULT SYSUTCDATETIME()
);
GO

-- =====================================
-- 인덱스 (검색 최적화)
-- =====================================
CREATE INDEX IX_Cars_Brand     ON Cars(Brand);
CREATE INDEX IX_Cars_Status    ON Cars(Status);
CREATE INDEX IX_Cars_CreatedAt ON Cars(CreatedAt DESC);
GO

PRINT '✅ schema.sql 실행 완료 — 3 tables, 3 indexes 생성됨';
GO
