using FOMCMeetings
using Test
using Dates, DataFrames

@testset "FOMCMeetings.jl" begin

    @testset "make_capgroup function tests" begin
        # Test case for make_capgroup
        @testset "make_capgroup function" begin
            capgroup = FOMCMeetings.make_capgroup()
            expected_capgroup = "(January|February|March|April|May|June|July|August|September|October|November|December)"
            
            @test typeof(capgroup) == String  # Ensure the return type is String
            @test capgroup == expected_capgroup  # Ensure the generated capgroup matches the expected one
        end
    end

    @testset "make_patterns function tests" begin
        # Test case for make_patterns
        @testset "make_patterns function" begin
            rx, rxmonthend = FOMCMeetings.make_patterns()
            
            # Test rx pattern
            @test typeof(rx) == Regex  # Ensure rx is a Regex object
            @test occursin(rx, "<h5>February 3-4 Meeting </h5>")  # Test matching 2-day pattern
            @test occursin(rx, "<h5>June 30 Meeting </h5>")  # Test matching 1-day pattern
            @test !occursin(rx, "<h5>Mar 30 Meeting </h5>")  # Test non-matching pattern
            
            # Test rxmonthend pattern
            @test typeof(rxmonthend) == Regex  # Ensure rxmonthend is a Regex object
            @test occursin(rxmonthend, "<h5>June 30-July 1 Meeting </h5>")  # Test matching 2-day pattern
        end
    end

    # Test case for add_days!
    @testset "add_days! function" begin
        meetings =  Vector{Date}()
        rx, rxmonthend = FOMCMeetings.make_patterns()

        # Read the contents of the file into a string
        contents = read("test/fomchistorical1998.htm", String)
        
        # Test adding days to non-monthend
        @testset "Adding days to non-monthend" begin
            FOMCMeetings.add_days!(meetings, 1998, rx, contents, false)
            @test length(meetings) == 7
            @test meetings[1] == Date(1998, 2, 4)    # 2-day meeting
            @test meetings[2] == Date(1998, 3, 31)   # 1-day meeting
        end
        
        # Test adding days to monthend
        @testset "Adding days to monthend" begin
            FOMCMeetings.add_days!(meetings, 1998, rxmonthend, contents, true)
            @test length(meetings) == 8
            @test meetings[8] == Date(1998, 7, 1)
        end
    end

    # Test case for get_fomc_recent!
    @testset "get_fomc_recent! function" begin
        # Read the contents of the file into a string
        contents = read("test/fomccalendars.htm", String)
        
        meetings =  Vector{Date}()
        FOMCMeetings.get_fomc_recent!(meetings, contents)
        
        # Check if meetings were added correctly
        @test length(meetings) == 47
        @test meetings[1] == Date(2024, 1, 31)
        @test meetings[end] == Date(2019, 12, 11)

        years = year.(meetings)
        @test sum(years .== 2024) == 2
        @test sum(years .== 2023) == 8
        @test sum(years .== 2022) == 8
        @test sum(years .== 2021) == 8
        @test sum(years .== 2020) == 12
        @test sum(years .== 2019) == 9
    end

    # Test case for view_fomc_calendar with Vector input
    @testset "view_fomc_calendar with Vector input" begin
        # Prepare sample data
        dates = Date(2024,1,10) .+ Month.(0:11)
        
        # Call the function with Vector input
        df = view_fomc_calendar(dates)
        
        # Check if DataFrame is returned
        @test typeof(df) == DataFrame
        
        # Check DataFrame structure
        @test ncol(df) == 13
        @test nrow(df) == 1
        @test all(names(df) .== ["year", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"])
        
        # Check values in the DataFrame
        @test df[1,:year] == 2024
        @test df[1,"7"] == "10"
    end
end