-- Standardize SaleDate date format
ALTER TABLE nashville_housing
ADD SaleDateConverted Date

UPDATE nashville_housing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Populate PropertyAddress data
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM nashville_housing A JOIN nashville_housing B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> b.[UniqueID ]
WHERE A.PropertyAddress IS NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM nashville_housing A JOIN nashville_housing B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

-- Breaking out PropertyAddress into individual columns (Address, City)
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM nashville_housing

ALTER TABLE nashville_housing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE nashville_housing
ADD PropertySplitCity NVARCHAR(255)

UPDATE nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Breaking out OwnerAddress into individual columns (Address, City, State)
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM nashville_housing

ALTER TABLE nashville_housing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE nashville_housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE nashville_housing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE nashville_housing
ADD OwnerSplitState NVARCHAR(255)

UPDATE nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N to Yes and No in "SoldAsVacant" field
SELECT DISTINCT SoldAsVacant
FROM nashville_housing

SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM nashville_housing

UPDATE nashville_housing
SET SoldAsVacant =
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-- Renove duplicates
WITH RowNumCTE AS (
	SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY UniqueID
	) Row_Num
	FROM nashville_housing
)
SELECT * FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY PropertyAddress

WITH RowNumCTE AS (
	SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY UniqueID
	) Row_Num
	FROM nashville_housing
)
DELETE FROM RowNumCTE
WHERE Row_Num > 1

-- Delete unused columns
SELECT *
FROM nashville_housing

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate