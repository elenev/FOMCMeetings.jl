# FOMCMeetings

This Julia package provides functions to retrieve FOMC (Federal Open Market Committee) meeting schedules from the Federal Reserve website and visualize them in a calendar format.

## Installation

You can install this package using the Julia package manager. From the Julia REPL, type `]` to enter the Pkg mode and then run:

```
pkg> add https://github.com/elenev/FOMCMeetings.jl
```

## Usage

### Retrieving FOMC Meetings

To retrieve FOMC meeting dates, use the `get_fomc_meetings` function:

```julia
using FOMCMeetings

meetings = get_fomc_meetings(1998)
```

This function returns a vector containing the dates of FOMC meetings starting in 1998 (which is also the defaut value).

### Viewing FOMC Meetings in Calendar Format

To visualize FOMC meetings in a calendar format, use the `view_fomc_calendar` function:

```julia
using FOMCMeetings
using DataFrames

# View FOMC meetings in calendar format
calendar_df = view_fomc_calendar(meetingdates)
```

This function creates a DataFrame containing year, month, and day columns based on the input DataFrame `meetingdates`, and then unstacks the DataFrame to create a wide-format DataFrame with columns for each month of the year. The resulting DataFrame can be used to visualize FOMC meetings in a calendar format. `view_fomc_calendar` also accepts a `DataFrame` with a `:date` column.

## License

This package is licensed under the MIT License.
