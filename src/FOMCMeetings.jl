module FOMCMeetings

using Dates, HTTP, DataFrames

export get_fomc_meetings, view_fomc_calendar

"""
    get_fomc_meetings(start=1998)

Scrapes the FOMC (Federal Open Market Committee) meeting schedule from the Federal Reserve website.

# Arguments
- `start::Int`: The start year for retrieving older meetings. Default is 1998.

# Returns
- Vector{Date}: A vector containing the dates of FOMC meetings.

# Examples
```julia
meetings = get_fomc_meetings()
```
"""
function get_fomc_meetings(start=1998)
    # Scrapes the FOMC schedule from the Federal Reserve website
    meetings = Vector{Date}()

    # Get recent meetings
    recents = HTTP.get("https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm").body |> String
    get_fomc_recent!(meetings, recents)

    # Older statements are posted on separate pages
    stop = minimum(year.(meetings)) - 1

    # Get older meetings
    get_fomc_old!(meetings, start, stop)

    sort!(meetings)
    return meetings
end

function get_fomc_recent!(meetings, contents)
    # Recent statements are all posted on one page.
    rxnew = r"<a href=\"\/newsevents\/pressreleases\/monetary([0-9]{8})a.htm\">"

    for m in eachmatch(rxnew, contents)
        push!(meetings, Date(m.captures[1], "yyyymmdd"))
    end
end

function get_fomc_old!(meetings, start, stop)
    # Patterns for scraping the older pages
    rx, rxmonthend = make_patterns()

    for year in start:stop
        contents = HTTP.get("https://www.federalreserve.gov/monetarypolicy/fomchistorical$(year).htm").body |> String
        add_days!(meetings, year, rx, contents, false)
        add_days!(meetings, year, rxmonthend, contents, true)
    end
end

function make_capgroup()
    month_names = [Dates.format(Date(0,i,1),"U") for i in 1:12]
    return "(" * join(month_names,"|") * ")"
end

function make_patterns()
    capgroup = make_capgroup()
    rx = Regex("<h5>$(capgroup) ([0-9\\-]+) Meeting(.*?)</h5>")
    rxmonthend = Regex("<h5>$(capgroup) ([0-9]+)-$(capgroup) ([0-9])+ Meeting(.*?)</h5>")
    return rx, rxmonthend
end

function add_days!(meetings, year, rx, contents, is_monthend)
    month_idx = is_monthend ? 3 : 1
    day_idx = is_monthend ? 4 : 2
    for m in eachmatch(rx, contents)
        month = m.captures[month_idx]
        day = split(m.captures[day_idx],"-")[end]
        push!(meetings, Date("$month $day, $year", "U dd, yyyy"))
    end
end

function write_vector_to_csv(path, v, name)
    open(path, "w") do file
        write(file, "$(name)\n")
        for x in v
            write(file, "$x\n")
        end
    end
end

"""
    view_fomc_calendar(v::Vector)

Converts a Vector of Date objects into a DataFrame and then calls `view_fomc_calendar(v::DataFrame)`.

# Arguments
- `v::Vector`: A Vector containing Date objects.

# Returns
- DataFrame: A DataFrame containing the dates.

# Examples
```julia
dates = Date(2024,1,10) .+ Month.(0:11)
df = view_fomc_calendar(dates)
```
"""
function view_fomc_calendar(v::Vector)
    view_fomc_calendar(DataFrame(date=v))
end

"""
    view_fomc_calendar(v::DataFrame)

Creates a DataFrame containing year, month, and day columns based on the Date column `v.date` in the input DataFrame `v`. Then unstacks the DataFrame based on the year and month columns to create a wide-format DataFrame with columns for each month of the year. 

# Arguments
- `v::DataFrame`: A DataFrame containing a `date` column of Date objects.

# Returns
- DataFrame: A wide-format DataFrame containing year and month columns as well as columns for each month of the year.

# Examples
```julia
using DataFrames
df = DataFrame(date = Date(2024,1,10) .+ Month.(0:11))
wide_df = view_fomc_calendar(df)
```
"""
function view_fomc_calendar(v::DataFrame)
    v.year=year.(v.date)
    v.month=month.(v.date)
    v.day=string.(day.(v.date))

    df = unstack(v, :year, :month, :day, combine = x -> join(x,", "))
    order = ["year", string.(1:12)...]
    return df[!,order]
end

end