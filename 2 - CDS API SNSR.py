# Notice that a change in the maximum download size of NetCDF files from the ERA5-Land database occurred in April 2025.
# (see https://forum.ecmwf.int/t/limitation-change-on-netcdf-era5-requests/12477 for more information).
# Thus, one needs to download 2 files for each year: one for Jan-Jun, and one for Jul-Dec. 


import cdsapi

client = cdsapi.Client()

# COMPLETE WITH THE DIRECTORY WHERE TO SAVE THE ZIPPED NETCDF FILES.
output_dir = ""

for year in range(2012, 2026):
    dataset = "reanalysis-era5-land"
    request = {
        "variable": [
            "surface_net_solar_radiation"
        ],
        "year": str(year),
        "month": [
            "01", "02", "03",
            "04", "05", "06"
        ],

        "day": [
            "01", "02", "03",
            "04", "05", "06",
            "07", "08", "09",
            "10", "11", "12",
            "13", "14", "15",
            "16", "17", "18",
            "19", "20", "21",
            "22", "23", "24",
            "25", "26", "27",
            "28", "29", "30",
            "31"
        ],
        "time": "00:00",
        "data_format": "netcdf",
        "download_format": "zip",
        "area": [47, 6, 36, 19]
    }

    output_filename = f"{output_dir}/era5_land_snsr_{year}.1.zip"

    print(f"Requesting data for year {year}...")
    client.retrieve(dataset, request).download(output_filename)
    print(f"Data for year {year} saved to {output_filename}.")




for year in range(2012, 2026):
    dataset = "reanalysis-era5-land"
    request = {
        "variable": [
            "surface_net_solar_radiation"
        ],
        "year": str(year),
        "month": [
            "07", "08", "09",
            "10", "11", "12"
        ],

        "day": [
            "01", "02", "03",
            "04", "05", "06",
            "07", "08", "09",
            "10", "11", "12",
            "13", "14", "15",
            "16", "17", "18",
            "19", "20", "21",
            "22", "23", "24",
            "25", "26", "27",
            "28", "29", "30",
            "31"
        ],
        "time": "00:00",
        "data_format": "netcdf",
        "download_format": "zip",
        "area": [47, 6, 36, 19]
    }

    output_filename = f"{output_dir}/era5_land_snsr_{year}.2.zip"

    print(f"Requesting data for year {year}...")
    client.retrieve(dataset, request).download(output_filename)
    print(f"Data for year {year} saved to {output_filename}.")

