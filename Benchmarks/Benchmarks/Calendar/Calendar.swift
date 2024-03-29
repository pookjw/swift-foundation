//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Benchmark
import func Benchmark.blackHole

#if FOUNDATION_FRAMEWORK
import Foundation
#else
import FoundationEssentials
import FoundationInternationalization
#endif

let benchmarks = {
    Benchmark.defaultConfiguration.maxIterations = 1_000
    Benchmark.defaultConfiguration.maxDuration = .seconds(3)
    Benchmark.defaultConfiguration.scalingFactor = .kilo
    Benchmark.defaultConfiguration.metrics = [.cpuTotal, .wallClock, .mallocCountTotal, .throughput]
    
    let thanksgivingComponents = DateComponents(month: 11, weekday: 5, weekOfMonth: 4)
    let cal = Calendar(identifier: .gregorian)
    let currentCalendar = Calendar.current
    let thanksgivingStart = Date(timeIntervalSinceReferenceDate: 496359355.795410) //2016-09-23T14:35:55-0700
    
    Benchmark("nextThousandThanksgivings") { benchmark in
        var count = 1000
        cal.enumerateDates(startingAfter: thanksgivingStart, matching: thanksgivingComponents, matchingPolicy: .nextTime) { result, exactMatch, stop in
            count -= 1
            if count == 0 {
                stop = true
            }
        }
    }

    Benchmark("CurrentDateComponentsFromThanksgivings") { benchmark in
        var count = 1000
        currentCalendar.enumerateDates(startingAfter: thanksgivingStart, matching: thanksgivingComponents, matchingPolicy: .nextTime) { result, exactMatch, stop in
            count -= 1
            _ = currentCalendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second, .nanosecond, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear, .calendar, .timeZone], from: result!)
            if count == 0 {
                stop = true
            }
        }
    }

    let reference = Date(timeIntervalSinceReferenceDate: 496359355.795410) //2016-09-23T14:35:55-0700
    
    Benchmark("allocationsForFixedCalendars", configuration: .init(scalingFactor: .mega)) { benchmark in
        for _ in benchmark.scaledIterations {
            // Fixed calendar
            let cal = Calendar(identifier: .gregorian)
            let date = cal.date(byAdding: .day, value: 1, to: reference)
            assert(date != nil)
        }
    }
    
    Benchmark("allocationsForCurrentCalendar", configuration: .init(scalingFactor: .mega)) { benchmark in
        for _ in benchmark.scaledIterations {
            // Current calendar
            let cal = Calendar.current
            let date = cal.date(byAdding: .day, value: 1, to: reference)
            assert(date != nil)
        }
    }
    
    Benchmark("allocationsForAutoupdatingCurrentCalendar", configuration: .init(scalingFactor: .mega)) { benchmark in
        for _ in benchmark.scaledIterations {
            // Autoupdating current calendar
            let cal = Calendar.autoupdatingCurrent
            let date = cal.date(byAdding: .day, value: 1, to: reference)
            assert(date != nil)
        }
    }
    
    Benchmark("copyOnWritePerformance", configuration: .init(scalingFactor: .mega)) { benchmark in
        var cal = Calendar(identifier: .gregorian)
        for i in benchmark.scaledIterations {
            cal.firstWeekday = i % 2
            assert(cal.firstWeekday == i % 2)
        }
    }
    
    Benchmark("copyOnWritePerformanceNoDiff", configuration: .init(scalingFactor: .mega)) { benchmark in
        var cal = Calendar(identifier: .gregorian)
        let tz = TimeZone(secondsFromGMT: 1800)!
        for _ in benchmark.scaledIterations {
            cal.timeZone = tz
        }
    }
    
    Benchmark("allocationsForFixedLocale", configuration: .init(scalingFactor: .mega)) { benchmark in
        // Fixed locale
        for _ in benchmark.scaledIterations {
            let loc = Locale(identifier: "en_US")
            let identifier = loc.identifier
            assert(identifier == "en_US")
        }
    }
    
    Benchmark("allocationsForCurrentLocale", configuration: .init(scalingFactor: .mega)) { benchmark in
        // Current locale
        for _ in benchmark.scaledIterations {
            let loc = Locale.current
            let identifier = loc.identifier
            assert(identifier == "en_US")
        }
    }
    
    Benchmark("allocationsForAutoupdatingCurrentLocale", configuration: .init(scalingFactor: .mega)) { benchmark in
        // Autoupdating current locale
        for _ in benchmark.scaledIterations {
            let loc = Locale.autoupdatingCurrent
            let identifier = loc.identifier
            assert(identifier == "en_US")
        }
    }
        
    Benchmark("identifierFromComponents", configuration: .init(scalingFactor: .mega)) { benchmark in
        let c1 = ["kCFLocaleLanguageCodeKey" : "en"]
        let c2 = ["kCFLocaleLanguageCodeKey" : "zh",
                  "kCFLocaleScriptCodeKey" : "Hans",
                  "kCFLocaleCountryCodeKey" : "TW"]
        let c3 = ["kCFLocaleLanguageCodeKey" : "es",
                  "kCFLocaleScriptCodeKey" : "",
                  "kCFLocaleCountryCodeKey" : "409"]
        
        for _ in benchmark.scaledIterations {
            let id1 = Locale.identifier(fromComponents: c1)
            let id2 = Locale.identifier(fromComponents: c2)
            let id3 = Locale.identifier(fromComponents: c3)
            assert(id1.isEmpty == false)
            assert(id2.isEmpty == false)
            assert(id3.isEmpty == false)
        }
    }
}
