-- Calendar months, clamped to the last day for month-end anniversaries.
return function(age)
    local year, month, day = age.createTime:match('^(%d+)%-(%d+)%-(%d+)')
    if not year then return 'Unknown OS age' end
    year, month, day = tonumber(year), tonumber(month), tonumber(day)

    local function daysInMonth(y, m)
        if m == 2 then
            local leap = y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)
            return leap and 29 or 28
        end
        return ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[m]
    end

    local months, days, anniversaryDay = 0, age.days, day
    while true do
        local nextMonth, nextYear = month % 12 + 1, year + (month == 12 and 1 or 0)
        local nextDay = math.min(day, daysInMonth(nextYear, nextMonth))
        local span = daysInMonth(year, month) - anniversaryDay + nextDay
        if days < span then break end
        months, days = months + 1, days - span
        year, month, anniversaryDay = nextYear, nextMonth, nextDay
    end

    local function unit(n, name)
        return n .. ' ' .. name .. (n == 1 and '' or 's')
    end
    return unit(months // 12, 'year') .. ', ' .. unit(months % 12, 'month')
        .. ', ' .. unit(days, 'day') .. ' (' .. unit(age.days, 'day') .. ')'
end
