import cdsapi

client = cdsapi.Client()

for year in range(2025, 2026):
    dataset = "derived-era5-land-daily-statistics"
    request = {
        "variable": ["2m_temperature"],
        "year": str(year),
        "month": ["01", "02", "03", "04",
                  "05", "06", "07", "08",
                  "09", "10", "11", "12"],
        "day": ["01", "02", "03",
                "04", "05", "06",
                "07", "08", "09",
                "10", "11", "12",
                "13", "14", "15",
                "16", "17", "18",
                "19", "20", "21",
                "22", "23", "24",
                "25", "26", "27",
                "28", "29", "30",
                "31"],
        "daily_statistic": "daily_mean",
        "time_zone": "utc+00:00",
        "frequency": "1_hourly",
        "area": [47, 6, 36, 19]
    }

    output_filename = f"{year}.nc"

    print(f"Requesting data for year {year}...")
    client.retrieve(dataset, request, target=f"/Users/tommasoroccuzzo/Desktop/5 - Data 2025/INPUTS/T2M/era5_land_temperature_{year}.nc")

    print(f"Data for year {year} saved to {output_filename}.")
    