# Ported over directly from: https://github.com/dimagi/ethiopian-date-converter/blob/master/ethiopian_date/ethiopian_date.py
# and https://github.com/Zenysis/ethiopian-date/blob/master/index.js

module EthiopianDateHelper
  def from_gregorian_date_to_ethiopian_date_string(local_date)
    (eYear, eMonth, eDay) = from_gregorian_to_ethiopian(local_date.year, local_date.month, local_date.day)
    format_ethiopian_date(eYear, eMonth, eDay)
  end

  def from_ethiopian_date_string_to_gregorian_date(ethiopian_date_string)
    (eDay, eMonth, eYear) = ethiopian_date_string.split('-')
    (y, m, d) = from_ethiopian_to_gregorian(eYear.to_i, eMonth.to_i, eDay.to_i)
    DateTime.new(y, m, d).beginning_of_day
  end

  def from_ethiopian_to_gregorian(year, month, date)
    inputs = [year, month, date]
    if year <= 0 || month <= 0 || month > 13 || date <= 0 || date > 30 # Simple validation.
      raise ArgumentError, "Input must correspond to a valid Ethiopian date #{inputs}"
    end

    # Lots of weird stuff happens in the 1500s: https://www.history.com/news/6-things-you-may-not-know-about-the-gregorian-calendar
    if year < 1600
      raise ArgumentError, "This method is not guaranteed to work before 1600."
    end

    # Ethiopian new year in Gregorian calendar
    new_year_day = start_day_of_ethiopian(year)

    # September (Ethiopian) sees 7y difference
    gregorian_year = year + 7

    # Number of days in gregorian months
    # starting with September (index 1)
    # Index 0 is reserved for leap years switches.
    gregorian_months = [0, 30, 31, 30, 31, 31, 28, 31, 30, 31, 30, 31, 31, 30]

    # if next gregorian year is leap year, February has 29 days.
    next_year = gregorian_year + 1
    if (next_year % 4 == 0 and next_year % 100 != 0) || (next_year % 400 == 0)
      gregorian_months[6] = 29
    end

    # calculate number of days up to that date
    days_until_date = ((month - 1) * 30) + date
    if days_until_date <= 37 && year <= 1575  # mysterious rule
      days_until_date += 28
      gregorian_months[0] = 31
    else
      days_until_date += new_year_day - 1
    end

    # if ethiopian year is leap year, paguemain has six days
    if year - 1 % 4 == 3
      days_until_date += 1
    end

    # calculate month and date incremently
    month = -1
    gregorian_date = -1
    (0..(gregorian_months.count - 1)).each do |m|
      month = m
      if days_until_date <= gregorian_months[m]
        gregorian_date = days_until_date
        break
      else
        days_until_date -= gregorian_months[m]
      end
    end

    # if m > 4, we're already on next Gregorian year
    if month > 4
      gregorian_year += 1
    end

    # Gregorian months ordered according to Ethiopian
    order = [8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    gregorian_month = order[month]

    [gregorian_year, gregorian_month, gregorian_date]
  end

  private
  # returns first day of that Ethiopian year
  def start_day_of_ethiopian(year)
    # magic formula gives start of year
    new_year_day = (year / 100) - (year / 400) - 4

    # if the prev ethiopian year is a leap year, new-year occurs on 12th
    if (year - 1) % 4 == 3
      new_year_day += 1
    end

    new_year_day
  end


  def format_ethiopian_date(eYear, eMonth, eDay)
    format('%02d-%02d-%04d', eDay, eMonth, eYear)
  end

  def from_gregorian_to_ethiopian(year, month, date)
    # Validation
    inputs = [year, month, date]
    if month <= 0 || date <= 0 || !Date.valid_date?(year, month, date)
      raise ArgumentError, "Input must correspond to a valid gregorian date: #{inputs}"
    end

    # Lots of weird stuff happens in the 1500s: https://www.history.com/news/6-things-you-may-not-know-about-the-gregorian-calendar
    if year < 1600
      raise ArgumentError, "This method is not guaranteed to work before 1600."
    end

    # Number of days in gregorian months
    # starting with January (index 1)
    # Index 0 is reserved for leap years switches.
    gregorian_months = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    # Number of days in ethiopian months
    # starting with January (index 1)
    # Index 0 is reserved for leap years switches.
    # Comment: No idea why there is an extra 30 here but it's included in the
    # javascript/python library and is needed for specs to pass.
    ethiopian_months = [0, 30, 30, 30, 30, 30, 30, 30, 30, 30, 5, 30, 30, 30, 30]

    # if gregorian leap year, February has 29 days.
    if (year % 4 == 0 && year % 100 != 0) || (year % 400) == 0
      gregorian_months[2] = 29
    end

    # September sees 8y difference
    ethiopian_year = year - 8

    # if ethiopian leap year paguemain has 6 days
    if ethiopian_year % 4 == 3
      ethiopian_months[10] = 6
    end

    # Ethiopian new year in Gregorian calendar
    new_year_day = start_day_of_ethiopian(year - 8)

    # calculate number of days up to that date
    days_until_date = 0
    (1..(month-1)).each do |i|
      days_until_date += gregorian_months[i]
    end
    days_until_date += date

    # update tahissas (december) to match january 1st
    tahissas = ethiopian_year % 4 == 0 ? 26 : 25

    # take into account the 1582 change
    if year < 1582
      ethiopian_months[1] = 0
      ethiopian_months[2] = tahissas
    elsif days_until_date <= 277 && year == 1582
      ethiopian_months[1] = 0
      ethiopian_months[2] = tahissas
    else
      tahissas = new_year_day - 3
      ethiopian_months[1] = tahissas
    end

    # calculate month and date incrementally
    month = -1
    ethiopian_date = -1
    (1..(ethiopian_months.count - 1)).each do |m|
      month = m
      if days_until_date <= ethiopian_months[m]
        if (m == 1) || (ethiopian_months[m] == 0)
          ethiopian_date = days_until_date + (30 - tahissas)
        else
          ethiopian_date = days_until_date
        end

        break
      else
        days_until_date -= ethiopian_months[m]
      end
    end

    # if m > 4, we're already on next Ethiopian year
    if month > 10
      ethiopian_year += 1
    end

    # Ethiopian months ordered according to Gregorian
    order = [0, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 3, 4]
    ethiopian_month = order[month]

    [ethiopian_year, ethiopian_month, ethiopian_date]
  end
end
